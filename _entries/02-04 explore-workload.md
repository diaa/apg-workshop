---

sectionid: explore-workload
sectionclass: h2
parent-id: upandrunning
title: Explore PostgreSQL & Run Demo Workload
---

In this section you will connect to PostgreSQL from the jumpbox, learn essential meta-commands, restore a sample database, explore its schema, and then run a set of CPU-heavy queries to generate realistic workload for monitoring exercises later in the workshop.

---

### Step 1 — SSH into the Jumpbox

Connect to the jumpbox VM using the public IP from your deployment output:

```sh
ssh <vmUsername>@<jumpbox-public-ip>
```

> Replace `<vmUsername>` and `<jumpbox-public-ip>` with the values from your Bicep deployment output.

---

### Step 2 — Connect to PostgreSQL with psql

From the jumpbox, connect to the default `postgres` database:

```sh
psql -h <postgresql-fqdn> -U <pgadmin> -d postgres
```

You should see the `postgres=>` prompt.

---

### Step 3 — Explore the Server with Meta-Commands

Before restoring any data, run the following meta-commands to understand what is already on the server. These are **psql backslash commands** — they are not SQL; they are interpreted by the psql client itself.

#### 3.1 — List all databases

```sql
\l
```

**What it does:** Lists every database in the PostgreSQL cluster, including the owner, encoding, collation, and access privileges. You will see the default databases (`postgres`, `azure_maintenance`, `azure_sys`). After the restore in Step 4 you will see `orders_demo` here as well.

#### 3.2 — List schemas

```sql
\dn
```

**What it does:** Lists all schemas in the **current** database. By default you will see `public`. Schemas are namespaces that let you organise tables, views, and functions within a single database.

#### 3.3 — List all tables in all schemas

```sql
\dt *.*
```

**What it does:** The wildcard pattern `*.*` means "every table in every schema." This shows you system catalog tables (in `pg_catalog` and `information_schema`) plus any user tables in `public`. Use this to get a quick inventory of what exists.

#### 3.4 — List all views in all schemas

```sql
\dv *.*
```

**What it does:** Same idea as `\dt` but for **views**. Views are stored queries that act like virtual tables. You will see many built-in system views in `pg_catalog` and `information_schema`.

#### 3.5 — List all indexes in all schemas

```sql
\di *.*
```

**What it does:** Lists every index across all schemas. Indexes speed up queries by providing fast lookup paths. Notice which tables have indexes and which do not — this will be relevant when you run the heavy queries later.

#### 3.6 — Additional useful meta-commands

| Command | Description |
|---|---|
| `\l+` | Databases with sizes and tablespace info |
| `\dt+` | Tables with sizes (current database, public schema) |
| `\d <table>` | Describe a specific table — columns, types, constraints |
| `\df *.*` | List all functions in all schemas |
| `\du` | List all roles / users |
| `\conninfo` | Show current connection info (host, port, user, database) |
| `\timing` | Toggle query execution timing on/off — very useful for benchmarks |
| `\x` | Toggle expanded (vertical) display for wide result sets |

> **Tip:** Run `\timing` now so that every query you run from this point forward shows how long it took.

---

### Step 4 — Download and Restore the Sample Database

#### 4.1 — Exit psql

```sql
\q
```

#### 4.2 — Download the dump file

The workshop uses a pre-built custom-format dump that contains four tables with realistic e-commerce data (~410K rows total).

```sh
curl -L -o orders_demo.dump "<dump-file-url>"
```

> Replace `<dump-file-url>` with the URL provided by your instructor.

Verify the file downloaded correctly:

```sh
ls -lh orders_demo.dump
```

You should see a file of roughly 5–10 MB. If the file is missing or 0 bytes, check the URL and try again.

#### 4.3 — Create the target database

```sh
psql -h <postgresql-fqdn> -U <pgadmin> -d postgres -c "CREATE DATABASE orders_demo;"
```

#### 4.4 — Restore the dump with pg_restore

```sh
pg_restore -h <postgresql-fqdn> -U <pgadmin> -d orders_demo --no-owner --no-privileges --verbose orders_demo.dump
```

Flag reference:
- `--no-owner` — skip ownership assignment (avoids errors when the original owner doesn't exist on this server)
- `--no-privileges` — skip privilege (GRANT/REVOKE) statements from the source
- `--verbose` — print progress as each object is restored

You should see output listing each table and index being created, followed by data loading via COPY. If you see errors about roles not existing, they are safe to ignore (that's what `--no-owner` handles).

#### 4.5 — Verify the restore succeeded

Connect to the new database and confirm the tables exist with data:

```sh
psql -h <postgresql-fqdn> -U <pgadmin> -d orders_demo -c "
SELECT 'customers' AS tbl, COUNT(*) FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items;"
```

Expected output:

```
    tbl     | count
------------+--------
 customers  |  10000
 products   |    500
 orders     | 100000
 order_items| 300000
```

If you see all four tables with the expected row counts, the restore was successful.

---

### Step 5 — Explore the Restored Database

Connect to the new database interactively:

```sh
psql -h <postgresql-fqdn> -U <pgadmin> -d orders_demo
```

#### 5.1 — Confirm the tables exist

```sql
\dt
```

You should see four tables:

| Table | Description |
|---|---|
| `customers` | 10,000 customer profiles with city, country, loyalty points |
| `products` | 500 products across 5 categories |
| `orders` | 100,000 orders over the past year with status and shipping info |
| `order_items` | 300,000 line items linking orders to products |

#### 5.2 — Inspect table structures

```sql
\d customers
\d products
\d orders
\d order_items
```

Pay attention to data types, primary keys, and whether any foreign key constraints exist.

#### 5.3 — Check row counts

```sql
SELECT 'customers' AS table_name, COUNT(*) AS rows FROM customers
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items;
```

#### 5.4 — Check table sizes

```sql
SELECT relname AS table_name,
       pg_size_pretty(pg_total_relation_size(oid)) AS total_size,
       pg_size_pretty(pg_relation_size(oid)) AS table_size,
       pg_size_pretty(pg_indexes_size(oid)) AS index_size
FROM pg_class
WHERE relname IN ('customers','products','orders','order_items')
ORDER BY pg_total_relation_size(oid) DESC;
```

#### 5.5 — List indexes

```sql
\di
```

> **Note:** You will see only primary-key indexes. There are **no additional indexes** on foreign keys or commonly queried columns — this is intentional. The demo queries rely on sequential scans to generate CPU load.

#### 5.6 — Explore sample data

```sql
-- Peek at customers
SELECT * FROM customers LIMIT 5;

-- Product categories
SELECT category, COUNT(*) AS count FROM products GROUP BY category ORDER BY count DESC;

-- Order status distribution
SELECT status, COUNT(*) AS count FROM orders GROUP BY status ORDER BY count DESC;

-- Most recent orders
SELECT order_id, customer_id, order_date, total_amount, status
FROM orders ORDER BY order_date DESC LIMIT 10;

-- Average items per order
SELECT ROUND(AVG(item_count), 2) AS avg_items_per_order
FROM (SELECT order_id, COUNT(*) AS item_count FROM order_items GROUP BY order_id) sub;
```

#### 5.7 — Check for missing indexes (useful diagnostic)

```sql
SELECT relname AS table,
       seq_scan, seq_tup_read,
       idx_scan, idx_tup_fetch,
       CASE WHEN seq_scan > 0
            THEN ROUND(seq_tup_read::numeric / seq_scan, 0)
            ELSE 0
       END AS avg_rows_per_seq_scan
FROM pg_stat_user_tables
ORDER BY seq_tup_read DESC;
```

This shows how many sequential scans vs. index scans each table has received. After running the workload queries below, revisit this to see the impact.

---

### Step 6 — Run CPU-Heavy Demo Queries

> **Important:** Enable timing first so you can see how long each query takes:
> ```sql
> \timing
> ```

These queries are **intentionally unoptimised** — they trigger full sequential scans, large sorts, and heavy computation. This is exactly the kind of workload you want to observe in the monitoring section of the workshop.

---

#### Query 1 — Full Cross-Join Aggregation (extreme CPU)

```sql
SELECT c.city, c.country, p.category,
       COUNT(DISTINCT o.order_id) AS total_orders,
       SUM(oi.quantity * oi.unit_price * (1 - oi.discount/100)) AS revenue
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY c.city, c.country, p.category
ORDER BY revenue DESC;
```

**Why it is heavy:** This joins all four tables (10K × 100K × 300K × 500 rows of data in the pipeline) and groups by three columns. The `COUNT(DISTINCT ...)` forces a sort-based deduplication for every group. With no indexes on the join columns other than primary keys, the planner must do multiple sequential scans and hash joins, then a large sort for the `ORDER BY`.

---

#### Query 2 — Correlated Subquery (no index, sequential scans)

```sql
SELECT c.customer_id, c.first_name, c.last_name,
       (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id) AS order_count,
       (SELECT COALESCE(SUM(total_amount),0) FROM orders o WHERE o.customer_id = c.customer_id) AS lifetime_value
FROM customers c
ORDER BY lifetime_value DESC
LIMIT 100;
```

**Why it is heavy:** For **each** of the 10,000 customers, PostgreSQL executes two subqueries against the 100,000-row `orders` table. Without an index on `orders.customer_id`, each subquery triggers a full sequential scan — resulting in ~20,000 sequential scans of the orders table in total.

---

#### Query 3 — Window Functions Over Large Dataset (memory + CPU)

```sql
SELECT order_id, customer_id, order_date, total_amount,
       SUM(total_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS running_total,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY total_amount DESC) AS rank_by_amount,
       AVG(total_amount) OVER (PARTITION BY shipping_country ORDER BY order_date ROWS BETWEEN 100 PRECEDING AND CURRENT ROW) AS moving_avg
FROM orders;
```

**Why it is heavy:** Three separate window functions each require sorting the full 100,000-row `orders` table by different partition/order keys. The `running_total` computes a cumulative sum per customer; `rank_by_amount` assigns a row number per customer by descending amount; `moving_avg` computes a sliding 101-row average across shipping countries. PostgreSQL may need to materialise intermediate sort results to temp files if `work_mem` is limited.

---

#### Query 4 — Heavy Text Computation + Sort (CPU + temp disk)

```sql
SELECT c.email, md5(c.email || o.order_id::TEXT) AS hash_key,
       string_agg(p.product_name, ', ' ORDER BY oi.unit_price DESC) AS products_bought
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
JOIN products p ON p.product_id = oi.product_id
GROUP BY c.email, o.order_id
ORDER BY hash_key;
```

**Why it is heavy:** The `md5()` function computes a hash for every row in the join result (~300,000 rows). `string_agg(... ORDER BY ...)` sorts product names within each group by descending price. The final `ORDER BY hash_key` sorts all ~100,000 result groups by a computed hash — the result is essentially random, which defeats any natural ordering and forces a full sort.

---

#### Query 5 — Repeated Sequential Scan Loop (sustained CPU for ~30s+)

```sql
DO $$
BEGIN
  FOR i IN 1..20 LOOP
    PERFORM COUNT(*) FROM orders o
    JOIN order_items oi ON oi.order_id = o.order_id
    WHERE md5(o.status || oi.quantity::TEXT) LIKE '00%';
  END LOOP;
END $$;
```

**Why it is heavy:** This PL/pgSQL anonymous block runs the same expensive query **20 times** in a tight loop. Each iteration joins 100K orders with 300K order items, computes `md5()` on every joined row, and then filters by a text pattern. The `LIKE '00%'` filter on the hash cannot use any index, so every iteration is a full sequential scan + hash join + function evaluation. The result is sustained, constant CPU utilisation for tens of seconds.

> **Tip:** Increase the loop count to `50` or `100` for longer sustained load:
> ```sql
> DO $$
> BEGIN
>   FOR i IN 1..100 LOOP
>     PERFORM COUNT(*) FROM orders o
>     JOIN order_items oi ON oi.order_id = o.order_id
>     WHERE md5(o.status || oi.quantity::TEXT) LIKE '00%';
>   END LOOP;
> END $$;
> ```

---

#### Query 6 — Large Temp-Table Sort + Distinct (IOPS + memory pressure)

```sql
SELECT DISTINCT ON (customer_id)
       customer_id, order_id, order_date, total_amount
FROM orders
ORDER BY customer_id, total_amount DESC, order_date DESC;
```

**Why it is heavy:** `DISTINCT ON` requires the result to be sorted by the grouping column (`customer_id`) and then by the tie-breaking columns (`total_amount DESC, order_date DESC`). This forces a full sort of all 100,000 orders. If the sort does not fit in `work_mem`, PostgreSQL spills to temp files on disk, creating I/O pressure.

---

### Step 7 — Generate Maximum Load (Concurrent Execution)

For the best demonstration during monitoring exercises, run multiple queries at the same time from **separate psql sessions**.

Open **three** SSH sessions to the jumpbox, connect to `orders_demo` in each, then run:

| Session | Query | Why |
|---|---|---|
| Session 1 | Query 1 (cross-join aggregation) | Saturates one backend with multi-table joins |
| Session 2 | Query 3 (window functions) | Forces large sorts in another backend |
| Session 3 | Query 5 (loop × 50 or 100) | Sustained CPU from sequential scans |

Running these concurrently will show multiple active backends, high CPU utilisation, temp file usage, and sequential-scan-heavy workload in your monitoring dashboards.

---

### Step 8 — Observe the Impact

After running the workload, check the damage:

#### Active queries

```sql
SELECT pid, state, query_start, LEFT(query, 80) AS query_snippet
FROM pg_stat_activity
WHERE datname = 'orders_demo' AND state != 'idle'
ORDER BY query_start;
```

#### Sequential scan statistics (revisit from Step 5.7)

```sql
SELECT relname AS table,
       seq_scan, seq_tup_read,
       idx_scan, idx_tup_fetch
FROM pg_stat_user_tables
ORDER BY seq_tup_read DESC;
```

#### Temp file usage

```sql
SELECT datname, temp_files, pg_size_pretty(temp_bytes) AS temp_size
FROM pg_stat_database
WHERE datname = 'orders_demo';
```

#### Total database size

```sql
SELECT pg_size_pretty(pg_database_size('orders_demo')) AS db_size;
```

> These statistics feed directly into the **Monitoring and Troubleshooting** section of the workshop. Leave them as-is — do not reset the stats yet.
