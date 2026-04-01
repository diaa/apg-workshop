---

sectionid: param-tuning
sectionclass: h2
parent-id: day2
title: Parameter Tuning
---

PostgreSQL has over 300 configuration parameters. Most are fine at their defaults, but a handful directly control memory allocation, query planning, and I/O behaviour. Getting these right for your workload is the difference between a server that flies and one that spills every sort to disk.

In this section you will tune the most impactful parameters using the `orders_demo` database, measure the effect on the demo workload, and understand how Azure Flexible Server handles defaults.

---

### How to Change Parameters on Azure Flexible Server

There are two ways:

**1. Azure Portal** — Server parameters blade (GUI)
**2. Azure CLI:**

<div class="lang-tag lang-tag-shell">shell</div>
```bash
az postgres flexible-server parameter set \
  --resource-group <rg> --server-name <server> \
  --name work_mem --value "64MB"
```

Some parameters require a server restart (marked as `static` in the portal). Others apply immediately to new sessions (`dynamic`).

You can check the current value of any parameter from psql:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SHOW work_mem;

-- Or see all parameters with context:
SELECT name, setting, unit, context, short_desc
FROM pg_settings
WHERE name = 'work_mem';
```

The `context` column tells you when the change takes effect:

| Context | Meaning | Restart? |
|---|---|---|
| `user` | Can be changed per session with `SET` | No |
| `superuser` | Requires `azure_pg_admin` role | No |
| `postmaster` | Requires server restart | Yes |
| `sighup` | Applied on config reload (no restart) | No |

---

### The Key Parameters

---

#### 1. `work_mem` — Per-Operation Sort/Hash Memory

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SHOW work_mem;
```

Default on Flexible Server: typically `4MB`.

**What it controls:** The maximum amount of memory each sort, hash join, or hash aggregation operation can use **before spilling to temp files on disk**. Each query can use multiple `work_mem` allocations — a complex query with 5 sort/hash nodes uses up to 5 × `work_mem`.

**The problem you saw:** In the workload section, Query 3 (window functions) and Query 6 (DISTINCT ON) spilled to temp files. You saw this in:
- `pg_stat_database.temp_files` > 0
- EXPLAIN showing `Sort Method: external merge` instead of `Sort Method: quicksort`

#### Lab — Measure the impact

**Before (default `work_mem`):**

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SET work_mem = '4MB';

EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT ON (customer_id)
       customer_id, order_id, order_date, total_amount
FROM orders
ORDER BY customer_id, total_amount DESC, order_date DESC;
```

Look at the `Sort` node. If you see `Sort Method: external merge  Disk: XXXkB`, it means the sort spilled to temp files.

**After (increased `work_mem`):**

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SET work_mem = '64MB';

EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT ON (customer_id)
       customer_id, order_id, order_date, total_amount
FROM orders
ORDER BY customer_id, total_amount DESC, order_date DESC;
```

Now the Sort node should show `Sort Method: quicksort  Memory: XXXkB` — the entire sort fits in memory.

Compare execution times:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
-- Reset to default and time it
SET work_mem = '4MB';
\timing                 -- meta-command: toggles execution timing on
SELECT DISTINCT ON (customer_id) customer_id, order_id, order_date, total_amount
FROM orders ORDER BY customer_id, total_amount DESC, order_date DESC;

-- Increase and time it again
SET work_mem = '64MB';
SELECT DISTINCT ON (customer_id) customer_id, order_id, order_date, total_amount
FROM orders ORDER BY customer_id, total_amount DESC, order_date DESC;
```

Also test with Query 3 (window functions):

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SET work_mem = '4MB';
\timing                 -- meta-command: toggles execution timing on
SELECT order_id, customer_id, order_date, total_amount,
       SUM(total_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS running_total,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY total_amount DESC) AS rank_by_amount
FROM orders;

SET work_mem = '64MB';
SELECT order_id, customer_id, order_date, total_amount,
       SUM(total_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS running_total,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY total_amount DESC) AS rank_by_amount
FROM orders;
```

**Sizing guideline:**

```
Total memory budget for work_mem ≈ RAM × 0.25 / max_connections
```

For a 8GB server with 100 connections: `2048MB / 100 = ~20MB`. Conservative, but avoids OOM under load.

> **Caution:** Do not set `work_mem` globally to very large values (e.g., 512MB). A burst of concurrent queries each allocating multiple `work_mem` buffers can exhaust server memory. Use `SET` per-session for analytical queries instead.

Reset to default:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
RESET work_mem;
```

---

#### 2. `shared_buffers` — Shared Memory Cache

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SHOW shared_buffers;
```

Default on Flexible Server: auto-tuned by Azure to ~25% of available memory.

**What it controls:** The size of PostgreSQL's shared buffer pool — the in-memory cache for table and index data pages. Every read goes through this cache; a page found here avoids a disk read.

**You already measured this:** In the profiling section, `pg_stat_database.blks_hit` vs `blks_read` gives you the cache hit ratio. On a properly sized `shared_buffers`, you should see > 99% cache hit.

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SELECT
  blks_hit,
  blks_read,
  ROUND(100.0 * blks_hit / NULLIF(blks_hit + blks_read, 0), 2) AS cache_hit_pct
FROM pg_stat_database
WHERE datname = 'orders_demo';
```

**Do you need to change it?** On Azure Flexible Server, the default is almost always correct. Azure sets it relative to the SKU's memory. Only change it if:
- Cache hit ratio is below 95% consistently
- You have a very specific workload that benefits from a larger cache

> **Note:** Changing `shared_buffers` requires a server restart. This is a `postmaster`-context parameter.

---

#### 3. `effective_cache_size` — Planner's Cache Estimate

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SHOW effective_cache_size;
```

Default on Flexible Server: auto-tuned to ~75% of available memory.

**What it controls:** This does **not** allocate any memory. It tells the query planner how much total cache (shared_buffers + OS page cache) is likely available. A higher value makes the planner more willing to choose index scans (since it assumes index pages are cached), while a lower value biases toward sequential scans.

#### Lab — See the planner's behaviour change

<div class="lang-tag lang-tag-sql">sql</div>
```sql
-- Low estimate: planner assumes very little is cached
SET effective_cache_size = '64MB';

EXPLAIN SELECT * FROM orders WHERE customer_id = 42;
```

<div class="lang-tag lang-tag-sql">sql</div>
```sql
-- High estimate: planner assumes most data is cached
SET effective_cache_size = '4GB';

EXPLAIN SELECT * FROM orders WHERE customer_id = 42;
```

With a low `effective_cache_size`, the planner may choose a sequential scan (assuming random I/O to read index pages is expensive). With a high value, it chooses an index scan (assuming pages are likely in cache).

Reset:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
RESET effective_cache_size;
```

---

#### 4. `maintenance_work_mem` — Memory for Maintenance Operations

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SHOW maintenance_work_mem;
```

Default: `64MB` (on most Flexible Server SKUs).

**What it controls:** Memory available for `VACUUM`, `CREATE INDEX`, `ALTER TABLE ADD FOREIGN KEY`, and similar maintenance operations. These operations are single-threaded, so this is a per-operation allocation.

#### Lab — Index creation speed

<div class="lang-tag lang-tag-sql">sql</div>
```sql
-- Create with default maintenance_work_mem
SET maintenance_work_mem = '64MB';
\timing                 -- meta-command: toggles execution timing on
CREATE INDEX idx_maint_demo ON orders (customer_id, total_amount DESC, order_date DESC);

-- Drop and recreate with more memory
DROP INDEX idx_maint_demo;

SET maintenance_work_mem = '512MB';
CREATE INDEX idx_maint_demo ON orders (customer_id, total_amount DESC, order_date DESC);
```

Compare the creation times. With more memory, PostgreSQL can sort the index entries in memory instead of using temp files, making index creation faster.

Reset and clean up the test index:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
DROP INDEX IF EXISTS idx_maint_demo;
RESET maintenance_work_mem;
```

> **Important:** Drop the index before continuing. The **Index Tuning Lab** later in this chapter expects only primary-key indexes on the `orders_demo` tables. Leaving this index in place will skew the baseline measurements.

**Guideline:** Set to 256MB–1GB for index creation and VACUUM on large tables. It's safe to set high because only one maintenance operation runs per connection.

---

#### 5. `random_page_cost` — I/O Cost Estimate

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SHOW random_page_cost;
```

Default: `4.0`

**What it controls:** The planner's estimate of the cost of a non-sequential (random) disk page fetch, relative to `seq_page_cost` (default `1.0`). A higher value makes the planner prefer sequential scans (because it thinks random I/O is expensive). A lower value makes it prefer index scans.

**When to lower it:** On Azure Flexible Server with Premium SSD or Premium SSD v2 storage, random I/O is fast. A value of `1.1` to `2.0` is more appropriate than the default `4.0`.

#### Lab — See the impact

<div class="lang-tag lang-tag-sql">sql</div>
```sql
-- Default: random I/O is considered 4× more expensive than sequential
SET random_page_cost = 4.0;
EXPLAIN SELECT * FROM orders WHERE customer_id BETWEEN 100 AND 200;

-- SSD-appropriate: random I/O is nearly the same cost as sequential
SET random_page_cost = 1.1;
EXPLAIN SELECT * FROM orders WHERE customer_id BETWEEN 100 AND 200;
```

With `4.0`, the planner may choose a sequential scan for selective queries. With `1.1`, it uses the index.

Reset:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
RESET random_page_cost;
```

---

### Parameter Summary Table

| Parameter | Default | Context | Controls | Tuning tip |
|---|---|---|---|---|
| `work_mem` | 4MB | `user` | Sort/hash memory per operation | Increase for analytical queries (SET per-session); don't set globally above ~64MB |
| `shared_buffers` | ~25% RAM | `postmaster` | Shared buffer cache | Azure auto-tunes; only change if cache hit < 95% |
| `effective_cache_size` | ~75% RAM | `user` | Planner's cache assumption | Azure auto-tunes; raise if planner avoids index scans |
| `maintenance_work_mem` | 64MB | `user` | VACUUM / CREATE INDEX memory | Set 256MB–1GB for maintenance windows |
| `random_page_cost` | 4.0 | `user` | Planner's random I/O cost | Lower to 1.1–2.0 on SSD/Premium storage |
| `wal_buffers` | ~3% shared_buffers | `postmaster` | WAL write buffer | Almost never needs changing |
| `max_connections` | 100 | `postmaster` | Connection limit | Don't increase beyond what PgBouncer serves; each connection uses ~5–10MB |

---

### What About Azure Server Tiers?

Azure Flexible Server auto-configures several parameters based on your SKU:

| SKU | vCores | Memory | shared_buffers | effective_cache_size | max_connections |
|---|---|---|---|---|---|
| Burstable B1ms | 1 | 2 GB | 512 MB | 1.5 GB | 50 |
| GP Standard_D2ds_v4 | 2 | 8 GB | 2 GB | 6 GB | 859 |
| GP Standard_D4ds_v4 | 4 | 16 GB | 4 GB | 12 GB | 1719 |
| MO Standard_E2ds_v4 | 2 | 16 GB | 4 GB | 12 GB | 1719 |

Your workshop server (Standard_D2ds_v4) has 8GB RAM. Azure sets `shared_buffers` to ~2GB and `effective_cache_size` to ~6GB automatically.

> **Takeaway:** On Flexible Server, focus your tuning on `work_mem` (per-session), `maintenance_work_mem` (for maintenance), and `random_page_cost` (for SSD). The big memory parameters are already handled by Azure.