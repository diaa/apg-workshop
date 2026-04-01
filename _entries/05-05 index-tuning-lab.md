---

sectionid: index-tuning
sectionclass: h2
parent-id: day2
title: Index Tuning Lab — Fix the Broken Workload
---

This is the most satisfying section of the workshop. In the **Run Demo Workload** section you ran six intentionally unoptimised queries. In **Monitoring** you saw the CPU spikes and IOPS pressure they caused. In **Statistics & Query Planning** you learned how EXPLAIN works. Now you will **fix the problems** by adding the right indexes and comparing before/after performance.

> **Prerequisite:** You need the `orders_demo` database with the demo data. You should have `\timing` enabled and `pg_stat_statements` installed.

![Index Tuning Workflow](media/diagram-index-tuning.svg)

---

### Step 1 — Reset Statistics and Remove Stale Indexes

Start with a clean baseline so your before/after comparison is accurate:

<div class="lang-tag lang-tag-shell">shell</div>
```sh
psql -h <postgresql-fqdn> -U <pgadmin> -d orders_demo
```

<div class="lang-tag lang-tag-psql">psql</div>
```psql
\timing
```

<div class="lang-tag lang-tag-sql">sql</div>
```sql
-- Drop any indexes left over from earlier sections (e.g. parameter tuning, statistics)
DROP INDEX IF EXISTS idx_orders_cust_amount_date;
DROP INDEX IF EXISTS idx_orders_customer_id;

-- Reset table-level stats
SELECT pg_stat_reset();

-- Reset pg_stat_statements
SELECT pg_stat_statements_reset();
```

---

### Step 2 — Confirm the Current State (No Indexes)

Check what indexes exist:

<div class="lang-tag lang-tag-psql">psql</div>
```psql
\di
```

You should see only primary key indexes:
- `customers_pkey`
- `products_pkey`
- `orders_pkey`
- `order_items_pkey`

There are **no indexes** on foreign key columns (`customer_id`, `product_id`, `order_id` in child tables).

---

### Step 3 — Run the Problem Queries and Record Baseline

Run each query and note the execution time. These are the same queries from the workload section.

#### Query 2 — Correlated Subquery (worst offender)

<div class="lang-tag lang-tag-sql">sql</div>
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.customer_id, c.first_name, c.last_name,
       (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id) AS order_count,
       (SELECT COALESCE(SUM(total_amount),0) FROM orders o WHERE o.customer_id = c.customer_id) AS lifetime_value
FROM customers c
ORDER BY lifetime_value DESC
LIMIT 100;
```

**What to look for in the plan:**
- `Seq Scan on orders` inside the subquery — this runs once per customer (10,000 times)
- Huge `actual loops=10000` on the subquery nodes
- High `Buffers: shared hit=...` or `shared read=...` — repeated reads of the same pages

Record the `Execution Time` from the bottom of the EXPLAIN output.

#### Query 1 — Cross-Join Aggregation

<div class="lang-tag lang-tag-sql">sql</div>
```sql
EXPLAIN (ANALYZE, BUFFERS)
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

**What to look for:** `Hash Join` or `Merge Join` nodes with `Seq Scan` on both sides of every join.

#### Query 6 — DISTINCT ON

<div class="lang-tag lang-tag-sql">sql</div>
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT ON (customer_id)
       customer_id, order_id, order_date, total_amount
FROM orders
ORDER BY customer_id, total_amount DESC, order_date DESC;
```

**What to look for:** `Sort` node with high `Sort Space Used` and possibly `Sort Method: external merge` (temp file spill).

---

### Step 4 — Add the Missing Indexes

These are the indexes the demo database was designed to lack:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
-- Foreign key: orders.customer_id (used by Q1, Q2, Q6)
CREATE INDEX idx_orders_customer_id ON orders (customer_id);

-- Foreign key: order_items.order_id (used by Q1, Q4, Q5)
CREATE INDEX idx_order_items_order_id ON order_items (order_id);

-- Foreign key: order_items.product_id (used by Q1, Q4)
CREATE INDEX idx_order_items_product_id ON order_items (product_id);

-- Composite for DISTINCT ON in Q6 (covers the sort order)
CREATE INDEX idx_orders_cust_amount_date ON orders (customer_id, total_amount DESC, order_date DESC);

-- For Q2 correlated subquery: covers both COUNT and SUM
CREATE INDEX idx_orders_cust_total ON orders (customer_id, total_amount);
```

Verify they were created:

<div class="lang-tag lang-tag-psql">psql</div>
```psql
\di
```

You should now see 9 indexes (4 PKs + 5 new).

Run ANALYZE to update planner statistics with the new indexes:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
ANALYZE customers, orders, order_items, products;
```

---

### Step 5 — Re-Run the Queries and Compare

#### Query 2 — Correlated Subquery (after indexing)

<div class="lang-tag lang-tag-sql">sql</div>
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.customer_id, c.first_name, c.last_name,
       (SELECT COUNT(*) FROM orders o WHERE o.customer_id = c.customer_id) AS order_count,
       (SELECT COALESCE(SUM(total_amount),0) FROM orders o WHERE o.customer_id = c.customer_id) AS lifetime_value
FROM customers c
ORDER BY lifetime_value DESC
LIMIT 100;
```

**Expected change:** The subqueries now use `Index Only Scan` on `idx_orders_cust_total` instead of `Seq Scan`. The loops are still 10,000 but each loop reads a few index pages instead of scanning 100,000 rows.

#### Query 1 — Cross-Join Aggregation (after indexing)

<div class="lang-tag lang-tag-sql">sql</div>
```sql
EXPLAIN (ANALYZE, BUFFERS)
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

**Expected change:** At least some joins switch from `Hash Join (Seq Scan)` to `Nested Loop (Index Scan)` or `Merge Join (Index Scan)`, reducing buffer reads significantly.

#### Query 6 — DISTINCT ON (after indexing)

<div class="lang-tag lang-tag-sql">sql</div>
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT DISTINCT ON (customer_id)
       customer_id, order_id, order_date, total_amount
FROM orders
ORDER BY customer_id, total_amount DESC, order_date DESC;
```

**Expected change:** The `Sort` node disappears entirely. The planner uses `Index Scan` on `idx_orders_cust_amount_date` which is already sorted in the right order. No temp files needed.

---

### Step 6 — Build the Comparison Table

Fill in your actual numbers:

| Query | Before (ms) | After (ms) | Speedup | Key Change |
|---|---|---|---|---|
| Q2 — Correlated subquery | _____ | _____ | ×_____ | Seq Scan → Index Only Scan |
| Q1 — Cross-join aggregation | _____ | _____ | ×_____ | Hash Join (Seq Scan) → Index lookups |
| Q6 — DISTINCT ON | _____ | _____ | ×_____ | Sort (external merge) → Index Scan |

Typical improvements you should see:
- **Q2:** 10–50× faster (the correlated subquery benefits most from indexing)
- **Q1:** 2–5× faster (still a large aggregation, but joins are cheaper)
- **Q6:** 3–10× faster (eliminates the sort entirely)

---

### Step 7 — Check the New Sequential Scan Stats

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SELECT
  relname,
  seq_scan,
  seq_tup_read,
  idx_scan,
  idx_tup_fetch
FROM pg_stat_user_tables
WHERE relname IN ('customers', 'orders', 'order_items', 'products')
ORDER BY relname;
```

Compare `idx_scan` (should be high now) vs `seq_scan` (should be lower). Before indexing, `idx_scan` was 0 for most tables. Now it should dominate for the orders-related queries.

---

### Step 8 — pg_stat_statements Comparison

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SELECT
  calls,
  ROUND(total_exec_time::numeric, 2) AS total_ms,
  ROUND(mean_exec_time::numeric, 2)  AS mean_ms,
  shared_blks_hit,
  shared_blks_read,
  temp_blks_written,
  LEFT(query, 120) AS query
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

After the indexes, the same queries should show:
- Lower `mean_ms`
- Lower `shared_blks_read` (fewer disk reads)
- Lower or zero `temp_blks_written` (sorts fit in memory)

---

### Step 9 — What Queries Don't Benefit from Indexing?

Re-run Queries 3 and 5 to see that some workloads can't be fixed with indexes alone:

#### Query 3 — Window Functions

<div class="lang-tag lang-tag-sql">sql</div>
```sql
\timing                 -- meta-command: toggles execution timing on
SELECT order_id, customer_id, order_date, total_amount,
       SUM(total_amount) OVER (PARTITION BY customer_id ORDER BY order_date) AS running_total,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY total_amount DESC) AS rank_by_amount,
       AVG(total_amount) OVER (PARTITION BY shipping_country ORDER BY order_date ROWS BETWEEN 100 PRECEDING AND CURRENT ROW) AS moving_avg
FROM orders;
```

**Why indexing doesn't help much:** Window functions always need to process the *entire* result set. An index can help with the `PARTITION BY` sort, but PostgreSQL still reads every row. The real solution here is parameter tuning (`work_mem`) to avoid temp file spills.

#### Query 5 — md5 Loop

<div class="lang-tag lang-tag-sql">sql</div>
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

**Why indexing doesn't help:** The `WHERE` clause applies a function (`md5()`) to column values. No B-tree index can satisfy `md5(col) LIKE '00%'` — every row must be read and the function evaluated. Solutions:
- A **functional index** on `md5(status || quantity::TEXT)` — but only if this is a real query pattern
- Rewrite the query to avoid the computed filter

---

### Step 10 — Index Maintenance Awareness

Indexes aren't free. Check how much space they now consume:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SELECT
  tablename,
  indexname,
  pg_size_pretty(pg_relation_size(indexname::regclass)) AS index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexname::regclass) DESC;
```

**Trade-offs of indexes:**

| Benefit | Cost |
|---|---|
| Faster SELECT queries | Slower INSERT / UPDATE / DELETE (each must update all indexes) |
| Reduced I/O for lookups | Additional disk space |
| Sorted access (avoids sorts) | Additional vacuum work (indexes have dead entries too) |

The goal is not "add indexes on everything" — it's "add indexes where the read improvement justifies the write overhead."

---

### Summary

| Step | What you did | What you learned |
|---|---|---|
| Baseline | Ran queries with no indexes | Sequential scans on every join, temp file spills on sorts |
| Added 5 indexes | FK columns + composite + covering | Targeted the specific access patterns of the demo queries |
| After | Re-ran queries, measured improvement | 2–50× faster depending on query type |
| Limits | Tested Q3 and Q5 | Window functions and computed filters don't benefit from standard indexes |
| Costs | Measured index sizes | Indexes have write overhead and space cost — add only what's needed |

This completes the workshop's **break → measure → fix → prove** cycle: you created a bad workload (Run Demo Workload), observed the damage (Monitoring), profiled it (DB Profiling), understood the planner (Statistics), and now fixed it with targeted indexes.