---
sectionid: logicalbackup
sectionclass: h2
parent-id: businesscont-sec
title: Logical Backup and Restore
---

PostgreSQL ships three logical backup utilities: `pg_dump` (single database), `pg_dumpall` (entire cluster), and `pg_restore` (restore non-plain formats). In this section you will practice all the common dump and restore patterns using the `orders_demo` database — which now includes the indexes you added in the **Index Tuning Lab**.

> **Reminder:** If your libpq environment variables are not set, run `source ~/.pg_azure` on the jumpbox first. All commands below run on the **jumpbox Linux shell**, not inside psql.

---

### Step 1 — Plain-Text Dump

The simplest format. Output is a SQL script you can replay with `psql`.

```sh
pg_dump orders_demo > /tmp/orders_demo.plain.sql
```

Inspect the output:

```sh
less /tmp/orders_demo.plain.sql
```

You will see `CREATE TABLE`, `COPY` data blocks, and `CREATE INDEX` statements — including the indexes you added in the tuning lab.

#### Schema only (no data):

```sh
pg_dump --schema-only orders_demo > /tmp/orders_demo_ddl.sql
less /tmp/orders_demo_ddl.sql
```

#### Data only:

```sh
pg_dump --data-only orders_demo > /tmp/orders_demo_data.sql
less /tmp/orders_demo_data.sql
```

#### INSERT statements instead of COPY:

```sh
pg_dump --data-only --inserts orders_demo > /tmp/orders_demo_inserts.sql
less /tmp/orders_demo_inserts.sql
```

> **When to use `--inserts`:** COPY is much faster, but INSERT-based dumps are more portable (e.g., loading into a different RDBMS). Use COPY for PostgreSQL-to-PostgreSQL restores.

#### Single table:

```sh
pg_dump --table=customers orders_demo > /tmp/customers.sql
less /tmp/customers.sql
```

---

### Step 2 — Custom Format Dump

Custom format (`-Fc`) compresses the data and allows selective restore with `pg_restore`:

```sh
pg_dump -Fc orders_demo -f /tmp/orders_demo.custom.dump
ls -lh /tmp/orders_demo.custom.dump
```

Compare the file size to the plain-text dump — custom format is significantly smaller.

---

### Step 3 — Directory Format Dump

Directory format (`-Fd`) is the only format that supports parallel jobs:

```sh
pg_dump -Fd -j 4 orders_demo -f /tmp/orders_demo_dir
ls -la /tmp/orders_demo_dir/
```

The `-j 4` flag uses 4 parallel workers. You will see one compressed file per table plus a `toc.dat` table of contents.

---

### Step 4 — Restore to a Separate Test Database

Instead of dropping `orders_demo`, create a **new** database to practice the restore:

```sh
psql -d postgres -c "CREATE DATABASE orders_demo_restored;"
```

#### Restore from custom format:

```sh
pg_restore -d orders_demo_restored --no-owner --verbose /tmp/orders_demo.custom.dump
```

#### Verify:

```sh
psql -d orders_demo_restored -c "
SELECT 'customers' AS tbl, COUNT(*) FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items;"
```

Check that the indexes you created in the tuning lab are present:

```sh
psql -d orders_demo_restored -c "\di"
```

#### Restore from directory format (parallel):

```sh
psql -d postgres -c "DROP DATABASE IF EXISTS orders_demo_restored;"
psql -d postgres -c "CREATE DATABASE orders_demo_restored;"
pg_restore -d orders_demo_restored -j 4 --no-owner --verbose /tmp/orders_demo_dir
```

---

### Step 5 — Global Objects Dump

`pg_dumpall` is the only tool that can dump **roles, tablespaces, and other cluster-wide objects** that `pg_dump` cannot:

```sh
pg_dumpall > /tmp/whole_cluster.sql
less /tmp/whole_cluster.sql
```

For just the global objects (roles + tablespaces):

```sh
pg_dumpall -g --no-role-passwords > /tmp/globals.sql
less /tmp/globals.sql
```

> The `--no-role-passwords` flag avoids errors on Azure Flexible Server where you cannot export passwords from managed roles.

---

### Step 6 — Clean Up

Drop the test database:

```sh
psql -d postgres -c "DROP DATABASE IF EXISTS orders_demo_restored;"
```

The original `orders_demo` database is untouched and ready for subsequent sections.

---

### Summary

| Tool | Output format | Parallel | Selective restore | Use case |
|---|---|---|---|---|
| `pg_dump` (plain) | SQL text | No | No (full replay) | Simple, human-readable, cross-database |
| `pg_dump -Fc` | Custom binary | No | Yes (`pg_restore -t`) | Standard single-DB backup |
| `pg_dump -Fd` | Directory | Yes (`-j N`) | Yes | Large databases, fastest backup |
| `pg_dumpall` | SQL text | No | No | Global objects + all databases |
| `pg_restore` | *(reads Fc/Fd)* | Yes (`-j N`) | Yes | Restore from custom/directory format |