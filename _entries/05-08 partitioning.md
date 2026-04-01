---
sectionid: partitioning
sectionclass: h2
parent-id: day2
title: Table Partitioning
---

As tables grow into the millions of rows, even well-indexed queries slow down because indexes themselves become large. **Partitioning** splits a logical table into smaller physical pieces so the planner can skip entire partitions it doesn't need — a technique called **partition pruning**.

![Partitioning with Partition Pruning](media/diagram-partitioning.svg)

All exercises use the **orders_demo** database. Connect first:

<div class="lang-tag lang-tag-shell">shell</div>
```sh
psql "host=$PGHOST dbname=orders_demo user=$PGUSER sslmode=require"
```

<div class="lang-tag lang-tag-psql">psql</div>
```psql
\timing
\pset pager off
```

---

### Step 1 — Create a Partitioned Table (Range by Date)

Create a partitioned copy of the `orders` table, split by `order_date` into quarterly partitions:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
CREATE TABLE orders_partitioned (
    order_id        INTEGER      NOT NULL,
    customer_id     INTEGER      NOT NULL,
    order_date      DATE         NOT NULL,
    total_amount    NUMERIC(10,2),
    status          VARCHAR(20),
    shipping_country VARCHAR(50)
) PARTITION BY RANGE (order_date);
```

Create partitions for each quarter:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
CREATE TABLE orders_p_2024_q1 PARTITION OF orders_partitioned
  FOR VALUES FROM ('2024-01-01') TO ('2024-04-01');

CREATE TABLE orders_p_2024_q2 PARTITION OF orders_partitioned
  FOR VALUES FROM ('2024-04-01') TO ('2024-07-01');

CREATE TABLE orders_p_2024_q3 PARTITION OF orders_partitioned
  FOR VALUES FROM ('2024-07-01') TO ('2024-10-01');

CREATE TABLE orders_p_2024_q4 PARTITION OF orders_partitioned
  FOR VALUES FROM ('2024-10-01') TO ('2025-01-01');

-- Catch-all for dates outside the defined ranges
CREATE TABLE orders_p_default PARTITION OF orders_partitioned DEFAULT;
```

> **Note:** The upper bound in `FOR VALUES FROM … TO …` is **exclusive**. A row dated `2024-04-01` lands in Q2, not Q1.

Load data from the existing `orders` table:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
INSERT INTO orders_partitioned
  SELECT order_id, customer_id, order_date, total_amount, status, shipping_country
  FROM orders;
```

Verify the distribution:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SELECT tableoid::regclass AS partition, COUNT(*) AS rows
FROM orders_partitioned
GROUP BY tableoid
ORDER BY partition;
```

---

### Step 2 — Partition Pruning with EXPLAIN

Run a query that filters by date on both the original table and the partitioned table:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
-- Unpartitioned: scans all 100 000 rows
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*), SUM(total_amount)
FROM orders
WHERE order_date BETWEEN '2024-07-01' AND '2024-09-30';

-- Partitioned: prunes to Q3 only
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*), SUM(total_amount)
FROM orders_partitioned
WHERE order_date BETWEEN '2024-07-01' AND '2024-09-30';
```

**What to look for in the EXPLAIN output:**
- The partitioned query shows `Seq Scan on orders_p_2024_q3` — only one partition is touched.
- Other partitions are listed with `(never executed)` or omitted entirely.
- Compare `Buffers: shared hit` — the partitioned query reads far fewer pages.

Verify that pruning is enabled:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SHOW enable_partition_pruning;   -- should be 'on' (default)
```

---

### Step 3 — List Partitioning (by Status)

Not all partitioning is date-based. List partitioning is useful when rows fall into a fixed set of categories:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
CREATE TABLE orders_by_status (
    order_id        INTEGER      NOT NULL,
    customer_id     INTEGER      NOT NULL,
    order_date      DATE         NOT NULL,
    total_amount    NUMERIC(10,2),
    status          VARCHAR(20)  NOT NULL,
    shipping_country VARCHAR(50)
) PARTITION BY LIST (status);

CREATE TABLE orders_status_pending  PARTITION OF orders_by_status FOR VALUES IN ('pending');
CREATE TABLE orders_status_shipped  PARTITION OF orders_by_status FOR VALUES IN ('shipped');
CREATE TABLE orders_status_delivered PARTITION OF orders_by_status FOR VALUES IN ('delivered');
CREATE TABLE orders_status_other    PARTITION OF orders_by_status DEFAULT;

INSERT INTO orders_by_status
  SELECT order_id, customer_id, order_date, total_amount, status, shipping_country
  FROM orders;
```

Test pruning:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
EXPLAIN (ANALYZE)
SELECT COUNT(*) FROM orders_by_status WHERE status = 'pending';
```

Only the `orders_status_pending` partition is scanned.

---

### Step 4 — Indexes on Partitioned Tables

Indexes on the parent table are automatically created on all partitions:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
CREATE INDEX idx_orders_part_customer ON orders_partitioned (customer_id);
```

Verify with psql:

<div class="lang-tag lang-tag-psql">psql</div>
```psql
\di orders_p_*
```

Each partition now has its own `idx_orders_part_customer` index. The planner combines pruning (skip partitions) with index scan (fast lookup within the partition):

<div class="lang-tag lang-tag-sql">sql</div>
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, order_date, total_amount
FROM orders_partitioned
WHERE order_date BETWEEN '2024-07-01' AND '2024-09-30'
  AND customer_id = 42;
```

---

### Step 5 — Attach and Detach Partitions

A common operations pattern is to **attach** new partitions for upcoming periods and **detach** old ones for archival.

Create a new partition for Q1 2025:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
-- Create the table first (could be loaded offline)
CREATE TABLE orders_p_2025_q1 (LIKE orders_partitioned INCLUDING DEFAULTS INCLUDING CONSTRAINTS);

-- Attach it (instant metadata operation)
ALTER TABLE orders_partitioned
  ATTACH PARTITION orders_p_2025_q1 FOR VALUES FROM ('2025-01-01') TO ('2025-04-01');
```

Detach an old partition for archival:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
-- Detach without blocking concurrent reads (PG 14+)
ALTER TABLE orders_partitioned DETACH PARTITION orders_p_2024_q1 CONCURRENTLY;
```

> **CONCURRENTLY** (PostgreSQL 14+) avoids an `ACCESS EXCLUSIVE` lock on the parent table. Without it, all queries against `orders_partitioned` are blocked during the detach.

The detached table still exists as a standalone table — you can query it, archive it, or drop it:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SELECT COUNT(*) FROM orders_p_2024_q1;   -- still accessible as a regular table
```

---

### Step 6 — Cleanup

<div class="lang-tag lang-tag-sql">sql</div>
```sql
DROP TABLE IF EXISTS orders_partitioned CASCADE;
DROP TABLE IF EXISTS orders_by_status CASCADE;
DROP TABLE IF EXISTS orders_p_2024_q1;   -- was detached, so not dropped by CASCADE
```

---

### When to Partition

| Scenario | Partition Strategy | Why |
|---|---|---|
| Time-series data (logs, orders, events) | **Range** by date | Prune old months, archive by detaching |
| Status / category-based queries | **List** by status | Each status gets its own small table |
| Even distribution across workers | **Hash** by ID | Useful for parallel query / sharding |
| Table < 1M rows | **Don't partition** | Overhead outweighs benefit for small tables |

**Key trade-offs:**

| Benefit | Cost |
|---|---|
| Partition pruning skips irrelevant data | More complex DDL and maintenance |
| Smaller per-partition indexes | Cross-partition queries (no filter on partition key) scan all partitions |
| Easy data lifecycle (attach/detach) | Unique constraints must include the partition key |
| Parallel scans across partitions | Foreign keys referencing partitioned tables require PG 12+ |

**Rule of thumb:** Partition when a table has millions of rows, queries consistently filter on the partition key, and you have a data lifecycle requirement (archival, retention).
