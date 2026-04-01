---

sectionid: demo-workload
sectionclass: h2
parent-id: upandrunning
title: Run Demo Workload — Break Things on Purpose
---

In this section you will run a set of intentionally unoptimised, CPU-heavy queries against the `orders_demo` database you restored in the previous section. The goal is to generate realistic workload that you will observe in the **Monitoring** section and fix in the **Index Tuning Lab**.

> **Prerequisite:** You should have the `orders_demo` database restored from the **Load Data** section and be connected from the jumpbox.

Connect to the database if you are not already:

<div class="lang-tag lang-tag-shell">shell</div>
```sh
psql -h <postgresql-fqdn> -U <pgadmin> -d orders_demo
```

---

### Step 1 — Run CPU-Heavy Demo Queries

> **Important:** Enable timing first so you can see how long each query takes:
> ```psql
> \timing
> ```

These queries are **intentionally unoptimised** — they trigger full sequential scans, large sorts, and heavy computation. This is exactly the kind of workload you will observe in the **next section** — [Monitoring PostgreSQL with Azure Portal](#azure-monitoring).

---

#### Query 1 — Full Cross-Join Aggregation (extreme CPU)

<div class="lang-tag lang-tag-sql">sql</div>
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

<div class="lang-tag lang-tag-sql">sql</div>
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

<div class="lang-tag lang-tag-sql">sql</div>
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

<div class="lang-tag lang-tag-sql">sql</div>
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

**Why it is heavy:** This PL/pgSQL anonymous block runs the same expensive query **20 times** in a tight loop. Each iteration joins 100K orders with 300K order items, computes `md5()` on every joined row, and then filters by a text pattern. The `LIKE '00%'` filter on the hash cannot use any index, so every iteration is a full sequential scan + hash join + function evaluation. The result is sustained, constant CPU utilisation for tens of seconds.

**Understanding the syntax:**

| Element | What it does |
|---|---|
| [`DO`](https://www.postgresql.org/docs/current/sql-do.html) | Executes an anonymous code block — like a one-off function you don't need to save |
| `$$ ... $$` | [Dollar-quoted string](https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-DOLLAR-QUOTING) delimiters — replaces single quotes so you don't have to escape quotes inside the block |
| `BEGIN ... END` | Marks the start and end of the [PL/pgSQL](https://www.postgresql.org/docs/current/plpgsql.html) code block |
| [`FOR i IN 1..20 LOOP`](https://www.postgresql.org/docs/current/plpgsql-control-structures.html#PLPGSQL-INTEGER-FOR) | Integer FOR loop — runs the body 20 times with `i` counting from 1 to 20 |
| [`PERFORM`](https://www.postgresql.org/docs/current/plpgsql-statements.html#PLPGSQL-STATEMENTS-SQL-ONEROW) | Runs a SELECT but discards the result — used when you want the side effects (CPU load) but don't need the output |

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

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SELECT DISTINCT ON (customer_id)
       customer_id, order_id, order_date, total_amount
FROM orders
ORDER BY customer_id, total_amount DESC, order_date DESC;
```

**Why it is heavy:** `DISTINCT ON` requires the result to be sorted by the grouping column (`customer_id`) and then by the tie-breaking columns (`total_amount DESC, order_date DESC`). This forces a full sort of all 100,000 orders. If the sort does not fit in `work_mem`, PostgreSQL spills to temp files on disk, creating I/O pressure.

---

### Step 2 — Generate Maximum Load (Concurrent Execution)

For the best demonstration during monitoring exercises, run multiple queries at the same time from **separate psql sessions**.

Open **three** SSH sessions to the jumpbox, connect to `orders_demo` in each, then run:

| Session | Query | Why |
|---|---|---|
| Session 1 | Query 1 (cross-join aggregation) | Saturates one backend with multi-table joins |
| Session 2 | Query 3 (window functions) | Forces large sorts in another backend |
| Session 3 | Query 5 (loop × 50 or 100) | Sustained CPU from sequential scans |

Running these concurrently will show multiple active backends, high CPU utilisation, temp file usage, and sequential-scan-heavy workload in your monitoring dashboards.

---

### Step 3 — Observe the Impact

After running the workload, check the damage:

#### Active queries

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SELECT pid, state, query_start, LEFT(query, 80) AS query_snippet
FROM pg_stat_activity
WHERE datname = 'orders_demo' AND state != 'idle'
ORDER BY query_start;
```

#### Sequential scan statistics (revisit from the Load Data section)

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SELECT relname AS table,
       seq_scan, seq_tup_read,
       idx_scan, idx_tup_fetch
FROM pg_stat_user_tables
ORDER BY seq_tup_read DESC;
```

**How to read this output:**

| Column | What it means | What to look for |
|---|---|---|
| `seq_scan` | Number of sequential (full table) scans since last stats reset | High on large tables = missing index. After the demo workload, `orders` should show thousands of seq_scans from Query 2 and 5 |
| `seq_tup_read` | Total rows read by sequential scans | The real cost indicator. Millions or billions = massive wasted I/O |
| `idx_scan` | Number of index scans | Should be **much higher** than `seq_scan` on large, frequently queried tables. If it is 0, no index is being used |
| `idx_tup_fetch` | Rows fetched via indexes | Each row was targeted — this is efficient. Compare to `seq_tup_read`: a large gap means most reads are wasteful full scans |

> **Rule of thumb:** If `seq_tup_read` is orders of magnitude larger than `idx_tup_fetch` on a table, that table almost certainly needs an index on the columns used in WHERE/JOIN clauses. You will fix this in the **Index Tuning Lab**.

#### Temp file usage

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SELECT datname, temp_files, pg_size_pretty(temp_bytes) AS temp_size
FROM pg_stat_database
WHERE datname = 'orders_demo';
```

**How to read this output:**

| Column | What it means | What to look for |
|---|---|---|
| `temp_files` | Number of temp files created since last stats reset | Any value > 0 means queries spilled sorts or hashes to disk because they exceeded `work_mem` |
| `temp_bytes` | Total bytes written to temp files | Large values (hundreds of MB+) indicate heavy sort/hash operations. Queries 3, 4, and 6 are the likely culprits |

#### Total database size

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SELECT pg_size_pretty(pg_database_size('orders_demo')) AS db_size;
```

> These statistics feed directly into the **next section** — [Monitoring PostgreSQL with Azure Portal](#azure-monitoring). Leave them as-is — do not reset the stats yet.
