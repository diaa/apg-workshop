---

sectionid: load-data
sectionclass: h2
parent-id: upandrunning
title: Load Data — Restore the Sample Database
---

In this section you will restore a sample e-commerce database (`orders_demo`) with four tables and ~410K rows, then explore its schema to understand the data you will work with throughout the rest of the workshop.

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

### Step 3 — Explore the Server Before Loading Data

Before restoring any data, run the following meta-commands to understand what is already on the server. These are **psql backslash commands** — they are not SQL; they are interpreted by the psql client itself.

> **psql session skills** (`\timing`, `\x`, `\watch`, `\conninfo`, `\i`, `\?`) are covered in the previous **psql: The PostgreSQL Command-Line Client** section. This step focuses on navigation commands that explore what is on the server.

#### 3.1 — List all databases

```psql
\l
```

**What it does:** Lists every database in the PostgreSQL cluster, including the owner, encoding, collation, and access privileges. You will see the default databases (`postgres`, `azure_maintenance`, `azure_sys`). After the restore in Step 4 you will see `orders_demo` here as well.

#### 3.2 — List schemas

```psql
\dn
```

**What it does:** Lists all schemas in the **current** database. By default you will see `public`. Schemas are namespaces that let you organise tables, views, and functions within a single database.

#### 3.3 — List all tables in all schemas

```psql
\dt *.*
```

**What it does:** The wildcard pattern `*.*` means "every table in every schema." This shows you system catalog tables (in `pg_catalog` and `information_schema`) plus any user tables in `public`. Use this to get a quick inventory of what exists.

#### 3.4 — List all views in all schemas

```psql
\dv *.*
```

**What it does:** Same idea as `\dt` but for **views**. Views are stored queries that act like virtual tables. You will see many built-in system views in `pg_catalog` and `information_schema`.

#### 3.5 — List all indexes in all schemas

```psql
\di *.*
```

**What it does:** Lists every index across all schemas. Indexes speed up queries by providing fast lookup paths. Notice which tables have indexes and which do not — this will be relevant when you run the heavy queries in the next section.

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

```psql
\q
```

#### 4.2 — Download the dump file

The workshop uses a pre-built custom-format dump that contains four tables with realistic e-commerce data (~410K rows total).

```sh
curl -L -O "https://pg.azure-workshops.cloud/database/orders_demo.dump"
```

Verify the file downloaded correctly:

```sh
ls -lh orders_demo.dump
```

You should see a file of roughly 5–10 MB. If the file is missing or 0 bytes, check the URL and try again.

#### 4.3 — Create the target database

```sh
psql -h <postgresql-fqdn> -U <pgadmin> -d postgres -c "CREATE DATABASE orders_demo;"
```

> **Tip:** If you configured `.pg_azure` and `.pgpass` in the previous section, you can omit `-h` and `-U` and you won't be prompted for a password:
> ```sh
> psql -c "CREATE DATABASE orders_demo;"
> ```

#### 4.4 — Restore the dump with pg_restore

```sh
pg_restore -h <postgresql-fqdn> -U <pgadmin> -d orders_demo --no-owner --no-privileges --verbose orders_demo.dump
```

> With `.pg_azure` and `.pgpass` configured:
> ```sh
> pg_restore -d orders_demo --no-owner --no-privileges --verbose orders_demo.dump
> ```

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

```psql
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

```psql
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

```psql
\di
```

> **Note:** You will see only primary-key indexes. There are **no additional indexes** on foreign keys or commonly queried columns — this is intentional. The demo queries in the next section rely on sequential scans to generate CPU load.

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

This shows how many sequential scans vs. index scans each table has received. After running the workload queries in the next section, revisit this to see the impact.

---

### Step 6 — Enable pg_stat_statements

`pg_stat_statements` tracks execution statistics for all SQL statements. It is required for **Query Performance Insight** in the Azure Portal and for the **Monitoring** and **Index Tuning** sections later in the workshop. Set it up now so it collects data from the start.

1. Go to **Azure Portal** → your PostgreSQL server → **Server parameters**
2. Search for `shared_preload_libraries` → ensure **pg_stat_statements** is checked
3. Search for `pg_stat_statements.track` → set to **ALL**
4. Click **Save** — this requires a server restart

After the restart, connect from the jumpbox and create the extension:

```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
```

Verify it is working:

```sql
SELECT calls, query FROM pg_stat_statements LIMIT 5;
```
