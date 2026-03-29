---
sectionid: statistics
sectionclass: h2
parent-id: day2
title: Statistics and Query Planning
---

![Statistics and Query Planning Cycle](media/diagram-statistics-cycle.svg)

All exercises use the **orders_demo** database you restored earlier. Connect to it first:

```bash
psql "host=$PGHOST dbname=orders_demo user=$PGUSER sslmode=require"
```

### EXPLAIN

Run `EXPLAIN` on the `orders` table (~100 000 rows) to see the default execution plan:

```sql
EXPLAIN SELECT * FROM orders;
```

Sample output:
```
Seq Scan on orders  (cost=0.00..2541.00 rows=100000 width=24)
```

Check the statistics Postgres currently holds for this table:

```sql
SELECT relpages, reltuples FROM pg_class WHERE relname = 'orders';
```

If `reltuples` shows 0, the autovacuum hasn't run yet. Force a refresh:

```sql
VACUUM ANALYZE orders;

SELECT relpages, reltuples FROM pg_class WHERE relname = 'orders';
```

Expected output (approximate):
```
 relpages | reltuples
----------+-----------
      541 |    100000
```

Check `EXPLAIN` again — the row estimate should now match reality:

```sql
EXPLAIN SELECT * FROM orders;
```

```
Seq Scan on orders  (cost=0.00..2041.00 rows=100000 width=24)
```

### How the planner calculates cost

The total cost of a sequential scan equals `(relpages × seq_page_cost) + (reltuples × cpu_tuple_cost)`. Verify:

```sql
SELECT relpages * current_setting('seq_page_cost')::numeric
     + reltuples * current_setting('cpu_tuple_cost')::numeric
       AS estimated_cost
FROM pg_class
WHERE relname = 'orders';
```

The result should match the cost in the `EXPLAIN` output above.

### Adding a WHERE filter

```sql
EXPLAIN SELECT * FROM orders WHERE customer_id < 200;
```

Sample output:
```
Seq Scan on orders  (cost=0.00..2291.00 rows=1990 width=24)
  Filter: (customer_id < 200)
```

Add `ANALYZE` to see actual vs. estimated:

```sql
EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id < 200;
```

Sample output:
```
Seq Scan on orders  (cost=0.00..2291.00 rows=1990 width=24) (actual time=0.021..12.345 rows=1999 loops=1)
  Filter: (customer_id < 200)
  Rows Removed by Filter: 98001
Planning Time: 0.08 ms
Execution Time: 12.50 ms
```

Now not only the plan was shown but also the query was executed.

### Index scan vs. sequential scan

Create an index on `customer_id` and observe the plan change:

```sql
CREATE INDEX idx_orders_customer_id ON orders(customer_id);

EXPLAIN ANALYZE SELECT * FROM orders WHERE customer_id < 200;
```

Sample output:
```
Index Scan using idx_orders_customer_id on orders  (cost=0.29..82.10 rows=1990 width=24) (actual time=0.015..0.350 rows=1999 loops=1)
  Index Cond: (customer_id < 200)
Planning Time: 0.12 ms
Execution Time: 0.42 ms
```

> **Think about it:** Why did the planner choose **Index Scan** rather than **Index Only Scan**? (Hint: the query selects columns not in the index.)

### Join strategies

Use a join between `orders` and `customers` to explore how the planner picks join algorithms:

```sql
EXPLAIN ANALYZE
SELECT o.order_id, c.name, o.total_amount
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.customer_id < 200;
```

The planner will likely choose a **Nested Loop** — it can use the index on `orders.customer_id` to fetch a small number of rows, then look up each customer by primary key.

Now force the planner away from nested loops:

```sql
SET enable_nestloop TO off;

EXPLAIN ANALYZE
SELECT o.order_id, c.name, o.total_amount
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.customer_id < 200;
```

The plan switches to a **Hash Join** — it builds a hash table of the matching customers and probes it for each order.

Disable hash joins as well:

```sql
SET enable_hashjoin TO off;

EXPLAIN ANALYZE
SELECT o.order_id, c.name, o.total_amount
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.customer_id < 200;
```

The plan falls back to a **Merge Join** — both inputs must be sorted first.

> **Think about it:** Which algorithm was the fastest for this query and why? Compare the **Execution Time** from each plan.

### Cleanup

```sql
RESET enable_nestloop;
RESET enable_hashjoin;
DROP INDEX IF EXISTS idx_orders_customer_id;
```

