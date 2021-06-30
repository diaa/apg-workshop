---
sectionid: Statistics
sectionclass: h2
parent-id: upandrunning
title: Statistics and Query Planning
---
### EXPLAIN
Recreate the random_data table:
```sql 
DROP TABLE IF EXISTS random_data;

CREATE TABLE random_data
AS
SELECT s                           AS first_column,
       md5(random() :: TEXT)       AS second_column,
       md5((random() / 2) :: TEXT) AS third_column
FROM generate_series(1, 500000) s;
```

Run EXPLAIN command to see what's the execution plan of 'SELECT *' query:
```sql
EXPLAIN TABLE random_data;
```

Output:
```sql
Seq Scan on random_data  (cost=0.00..11420.05 rows=524705 width=68)
```

Check the statistics that Postgres currently has for random_data table:
```sql
SELECT relpages, reltuples FROM pg_class WHERE relname = 'random_data';
```

Output:
```sql
 relpages | reltuples
----------+-----------
        0 |         0
(1 row)
```

Run the VACUUM ANALYZE command against random_data and check the statisctics again:
```sql
VACUUM ANALYSE random_data;

SELECT relpages, reltuples FROM pg_class WHERE relname = 'random_data';
```

Output:
```sql
 relpages | reltuples
----------+-----------
     6173 |    500000
(1 row)
```

Check the EXPLAIN output again:
```sql
EXPLAIN TABLE random_data;
```

Are the numbers more accurate? 

Output:
```sql
                             QUERY PLAN
---------------------------------------------------------------------
 Seq Scan on random_data  (cost=0.00..11173.00 rows=500000 width=70)
(1 row)
```

Let's calculate the cost as Postgres query planner does:
```sql
SELECT relpages * current_setting('seq_page_cost')::numeric
           + reltuples * current_setting('cpu_tuple_cost')::numeric
FROM pg_class
WHERE relname = 'random_data';
```

Output:
```sql
 ?column?
----------
    11173
(1 row)
```

As you can see that's the same cost as shown in the EXPLAIN output;

Let's add a WHERE condition to the query:
```sql
EXPLAIN SELECT * FROM random_data WHERE first_column < 2000;
```

Output:
```sql
Gather  (cost=1000.00..9971.17 rows=1940 width=70)
  Workers Planned: 2
  ->  Parallel Seq Scan on random_data  (cost=0.00..8777.17 rows=808 width=70)
        Filter: (first_column < 2000)
```

Let's add ANALYZE to EXPLAIN clause:
```sql
EXPLAIN ANALYSE SELECT * FROM random_data WHERE first_column < 2000;
```

Output:
```sql
Gather  (cost=1000.00..9971.17 rows=1940 width=70) (actual time=0.498..727.918 rows=1999 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  ->  Parallel Seq Scan on random_data  (cost=0.00..8777.17 rows=808 width=70) (actual time=0.004..83.350 rows=666 loops=3)
        Filter: (first_column < 2000)
        Rows Removed by Filter: 166000
Planning Time: 0.098 ms
Execution Time: 728.032 ms
```

Now not only the plan was shown but also the query was executed.

Create an index and see how the execution plan has changed:
```sql
CREATE INDEX ON random_data(first_column);

EXPLAIN ANALYZE SELECT * FROM random_data WHERE first_column < 2000;
```

Output:
```sql
Index Scan using random_data_first_column_idx on random_data  (cost=0.42..86.67 rows=1957 width=70) (actual time=0.012..0.330 rows=1999 loops=1)
  Index Cond: (first_column < 2000)
Planning Time: 0.107 ms
Execution Time: 0.421 ms
```

Why Index Scan not Index Only Scan was used?

See the execution plan for a selfjoin:
```sql
EXPLAIN ANALYZE
SELECT t5.*
FROM random_data
         JOIN random_data t5 USING (first_column)
WHERE t5.first_column < 2000;
```

Output:
```sql
Nested Loop  (cost=0.84..5543.32 rows=1957 width=70) (actual time=0.025..3.809 rows=1999 loops=1)
  ->  Index Scan using random_data_first_column_idx on random_data t5  (cost=0.42..86.67 rows=1957 width=70) (actual time=0.016..0.422 rows=1999 loops=1)
        Index Cond: (first_column < 2000)
  ->  Index Only Scan using random_data_first_column_idx on random_data  (cost=0.42..2.78 rows=1 width=4) (actual time=0.001..0.001 rows=1 loops=1999)
        Index Cond: (first_column = t5.first_column)
        Heap Fetches: 0
Planning Time: 0.331 ms
Execution Time: 3.928 ms
```

Why Nested Loop was used?

Check if planner has chosen the right plan by disabling the nested loop:

```sql
SET ENABLE_NESTLOOP TO OFF;

EXPLAIN ANALYZE
SELECT t5.*
FROM random_data
         JOIN random_data t5 USING (first_column)
WHERE t5.first_column < 2000;
```

Output:
```sql
Gather  (cost=1111.13..10352.56 rows=1957 width=70) (actual time=0.965..114.698 rows=1999 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  ->  Hash Join  (cost=111.13..9156.86 rows=815 width=70) (actual time=35.316..67.464 rows=666 loops=3)
        Hash Cond: (random_data.first_column = t5.first_column)
        ->  Parallel Seq Scan on random_data  (cost=0.00..8256.33 rows=208333 width=4) (actual time=0.011..38.918 rows=166667 loops=3)
        ->  Hash  (cost=86.67..86.67 rows=1957 width=70) (actual time=0.786..0.787 rows=1999 loops=3)
              Buckets: 2048  Batches: 1  Memory Usage: 216kB
              ->  Index Scan using random_data_first_column_idx on random_data t5  (cost=0.42..86.67 rows=1957 width=70) (actual time=0.038..0.442 rows=1999 loops=3)
                    Index Cond: (first_column < 2000)
Planning Time: 0.219 ms
Execution Time: 114.823 ms
```

Disable also Hash Joins:
```sql
SET ENABLE_HASHJOIN TO OFF;

EXPLAIN ANALYZE
SELECT t5.*
FROM random_data
         JOIN random_data t5 USING (first_column)
WHERE t5.first_column < 2000;
```

Output:
```sql
Gather  (cost=1000.85..11896.00 rows=1957 width=70) (actual time=0.446..287.762 rows=1999 loops=1)
  Workers Planned: 2
  Workers Launched: 2
  ->  Merge Join  (cost=0.84..10700.30 rows=815 width=70) (actual time=13.313..16.500 rows=666 loops=3)
        Merge Cond: (random_data.first_column = t5.first_column)
        ->  Parallel Index Only Scan using random_data_first_column_idx on random_data  (cost=0.42..10079.76 rows=208333 width=4) (actual time=12.803..12.873 rows=667 loops=3)
              Heap Fetches: 0
        ->  Index Scan using random_data_first_column_idx on random_data t5  (cost=0.42..86.67 rows=1957 width=70) (actual time=0.085..0.552 rows=1999 loops=3)
              Index Cond: (first_column < 2000)
Planning Time: 0.255 ms
Execution Time: 287.901 ms
```

Which algorithm was the fastest for this query and why?

### work_mem Setting
Run EXPLAIN command to see what's the execution plan of the SELECT query that requires sorting:
```sql
EXPLAIN ANALYSE SELECT second_column FROM random_data ORDER BY 1 DESC;
```

Output:
```sql
Sort  (cost=73824.53..75136.30 rows=524705 width=32) (actual time=10705.361..14201.555 rows=500000 loops=1)
  Sort Key: second_column DESC
  Sort Method: external merge  Disk: 21096kB
  ->  Seq Scan on random_data  (cost=0.00..11420.05 rows=524705 width=32) (actual time=0.018..808.240 rows=500000 loops=1)
Planning Time: 0.087 ms
Execution Time: 14378.488 ms
```

As you see external merge was used as a sort method. It means that your data were sorted on the disk. This is because work_mem value was to small to sort the data in memory.

Check the current value of work_mem:
```sql
SHOW work_mem;
```

How much memory do you need to sort the data in RAM?

You can change the work_mem value just for the session to try it out. Set the proper value and try to rerun the query.
```sql
SET work_mem = '10MB';
```

After chosing the right work_mem value you will see that execution plan has changed:
```sql
Sort  (cost=61270.03..62581.80 rows=524705 width=32) (actual time=11884.004..12146.057 rows=500000 loops=1)
  Sort Key: second_column DESC
  Sort Method: quicksort  Memory: 51351kB
  ->  Seq Scan on random_data  (cost=0.00..11420.05 rows=524705 width=32) (actual time=0.013..579.455 rows=500000 loops=1)
Planning Time: 0.051 ms
Execution Time: 12206.274 ms
```

Now quicksort Memory was used instead of external merge. Why more memory is needed for the same sort operation in memory than on the disk?

