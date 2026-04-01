---
sectionid: query-rewriting
sectionclass: h2
parent-id: day2
title: Query Rewriting — Fix What Indexes Can't
---

In the Index Tuning Lab you fixed three workload queries with indexes alone.
But Queries 2, 3, and 5 still had room for improvement — or couldn't be helped by B-tree indexes at all.
This section shows how **rewriting** a query can be just as powerful as adding an index, and the two techniques stack.

![Query Rewriting Decision Tree](media/diagram-query-rewriting.svg)

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

### Step 1 — Correlated Subquery → JOIN + GROUP BY

**Original (Query 2):**

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

Even with an index, each correlated subquery still executes once per customer (10 000 loops). The planner cannot merge them.

**Rewrite — single pass with a JOIN:**

<div class="lang-tag lang-tag-sql">sql</div>
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.customer_id, c.first_name, c.last_name,
       COUNT(o.order_id)                    AS order_count,
       COALESCE(SUM(o.total_amount), 0)     AS lifetime_value
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY lifetime_value DESC
LIMIT 100;
```

**Why it is faster:**
- A single `Hash Aggregate` or `Group Aggregate` replaces 20 000 index lookups.
- `LEFT JOIN` preserves customers who have zero orders (same semantics as the `COALESCE` subquery).

Compare the `Execution Time` values side by side.

---

### Step 2 — EXISTS vs IN

A common anti-pattern is `IN (SELECT …)` with a large subquery. PostgreSQL can sometimes flatten it, but not always.

**Slow — IN with subquery:**

<div class="lang-tag lang-tag-sql">sql</div>
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT customer_id, first_name, last_name
FROM customers
WHERE customer_id IN (
  SELECT DISTINCT customer_id FROM orders WHERE total_amount > 500
);
```

**Faster — EXISTS (semi-join):**

<div class="lang-tag lang-tag-sql">sql</div>
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.customer_id, c.first_name, c.last_name
FROM customers c
WHERE EXISTS (
  SELECT 1 FROM orders o
  WHERE o.customer_id = c.customer_id AND o.total_amount > 500
);
```

**Why it can be faster:** `EXISTS` stops scanning the inner table as soon as it finds the *first* matching row. `IN` may build and sort the full subquery result before probing. Check the EXPLAIN plans — look for `Semi Join` vs `Hash Join`.

> **Tip:** Modern PostgreSQL (≥ 12) often rewrites `IN` into a semi-join automatically. If both plans look identical, PostgreSQL already optimised for you. The habit still matters when working with older versions or complex subqueries.

---

### Step 3 — Replace SELECT * with Explicit Columns

Run two versions of a simple lookup and compare the buffer counts:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
-- Reads every column from the heap
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM orders WHERE customer_id = 42;

-- Can use an Index Only Scan if a covering index exists
EXPLAIN (ANALYZE, BUFFERS)
SELECT order_id, order_date, total_amount
FROM orders WHERE customer_id = 42;
```

If `idx_orders_cust_amount_date` from the Index Tuning Lab is still in place, the second query can satisfy the request entirely from the index (`Index Only Scan`) — zero heap fetches.

**Rule of thumb:** Only request the columns you need. This enables covering indexes and reduces I/O.

---

### Step 4 — LATERAL JOIN for Top-N-Per-Group

Suppose you need the **three most recent orders per customer**. A common approach uses `ROW_NUMBER()`:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM (
  SELECT c.customer_id, c.first_name, o.order_id, o.order_date, o.total_amount,
         ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY o.order_date DESC) AS rn
  FROM customers c
  JOIN orders o ON o.customer_id = c.customer_id
) sub
WHERE rn <= 3;
```

This scans and sorts **all** 100 000 orders, then discards everything beyond rank 3.

**Rewrite — LATERAL subquery:**

<div class="lang-tag lang-tag-sql">sql</div>
```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT c.customer_id, c.first_name,
       lat.order_id, lat.order_date, lat.total_amount
FROM customers c
CROSS JOIN LATERAL (
  SELECT o.order_id, o.order_date, o.total_amount
  FROM orders o
  WHERE o.customer_id = c.customer_id
  ORDER BY o.order_date DESC
  LIMIT 3
) lat;
```

**Why it is faster:** For each customer, the `LATERAL` subquery fetches only 3 rows using an index seek + `LIMIT` instead of sorting the entire table. With the `idx_orders_customer_id` index in place, each probe is a fast index scan.

Compare the `Execution Time` and `Buffers: shared hit` values.

---

### Step 5 — CTE vs Subquery Materialisation

Before PostgreSQL 12, CTEs (`WITH` queries) were **always materialised** — the planner could not push predicates into them. Since PostgreSQL 12+, the planner can inline CTEs unless you add `MATERIALIZED`.

**Inlined (default in PG 12+):**

<div class="lang-tag lang-tag-sql">sql</div>
```sql
EXPLAIN (ANALYZE, BUFFERS)
WITH big_orders AS (
  SELECT order_id, customer_id, total_amount
  FROM orders
  WHERE total_amount > 500
)
SELECT c.first_name, c.last_name, bo.total_amount
FROM customers c
JOIN big_orders bo ON bo.customer_id = c.customer_id
WHERE c.country = 'Germany';
```

**Forced materialisation:**

<div class="lang-tag lang-tag-sql">sql</div>
```sql
EXPLAIN (ANALYZE, BUFFERS)
WITH big_orders AS MATERIALIZED (
  SELECT order_id, customer_id, total_amount
  FROM orders
  WHERE total_amount > 500
)
SELECT c.first_name, c.last_name, bo.total_amount
FROM customers c
JOIN big_orders bo ON bo.customer_id = c.customer_id
WHERE c.country = 'Germany';
```

Compare the two plans. In the inlined version, PostgreSQL pushes the `country = 'Germany'` filter into the join, reducing the number of rows early. In the materialised version, the CTE scans all orders with `total_amount > 500` first, then filters by country — more work.

> **When to use MATERIALIZED:** When a CTE is referenced multiple times in the outer query and is expensive to re-evaluate. Otherwise, let the planner inline it.

---

### Step 6 — Expression Index for Computed Filters

Query 5 from the workload uses `md5(o.status || oi.quantity::TEXT) LIKE '00%'`. No B-tree index helps because the WHERE clause applies a function to column values.

**Create a functional index:**

<div class="lang-tag lang-tag-sql">sql</div>
```sql
CREATE INDEX idx_oi_md5_status_qty
  ON order_items ((md5(
      (SELECT status FROM orders WHERE orders.order_id = order_items.order_id)
      || quantity::TEXT)));
```

That won't work — you can't reference another table inside an index expression.

**Practical alternative — precompute in a materialised view or rewrite the filter:**

<div class="lang-tag lang-tag-sql">sql</div>
```sql
-- Instead of computing md5 at query time, filter by the columns directly
EXPLAIN (ANALYZE, BUFFERS)
SELECT COUNT(*)
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'shipped' AND oi.quantity > 5;
```

**Lesson:** If you find yourself computing hashes in a WHERE clause, ask whether the business requirement can be expressed with direct column filters. md5-based filters are testing artefacts, not production patterns. When you genuinely need a computed filter, a **generated column** + index is the clean solution:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
-- Example: generated column (don't run — just for illustration)
ALTER TABLE orders ADD COLUMN status_hash TEXT
  GENERATED ALWAYS AS (md5(status)) STORED;

CREATE INDEX idx_orders_status_hash ON orders (status_hash);
```

---

### Summary

| Technique | When to Use | Typical Gain |
|---|---|---|
| Correlated subquery → JOIN | Subquery runs once per outer row | 5–50× |
| EXISTS vs IN | Checking membership in a large set | 1–5× (PG often auto-optimises) |
| Explicit columns vs SELECT * | Covering index available | 2–10× (avoids heap fetch) |
| LATERAL JOIN | Top-N-per-group patterns | 3–20× vs ROW_NUMBER() |
| CTE inlining (PG 12+) | Single-use CTEs with outer filters | 2–5× |
| Expression / generated index | Computed WHERE filters | Varies — eliminate the computation |

**Key takeaway:** Indexing and query rewriting are complementary. Indexes speed up *access paths*; rewrites reduce *how much work* PostgreSQL needs to do in the first place. Always check `EXPLAIN (ANALYZE, BUFFERS)` before and after.
