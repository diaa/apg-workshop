---

sectionid: psql
sectionclass: h2
parent-id: upandrunning
title: "psql: The PostgreSQL Command-Line Client"
---

`psql` is the interactive terminal for PostgreSQL. You will use it throughout this workshop to run queries, explore schemas, import data, and administer the server. This section teaches you the essential skills for working with `psql` efficiently.

> **Prerequisite:** You should have connected to PostgreSQL from the jumpbox in the previous section. If your environment variables and `.pgpass` are set up, simply run `psql` to connect.

---

### Backslash Meta-Commands

Anything you type in `psql` that begins with a backslash (`\`) is a **meta-command** — it is processed by the `psql` client itself, not sent to the PostgreSQL server. These are your primary navigation tools.

#### Exploring the Server

| Command | What it shows |
|---|---|
| `\l` | List all databases |
| `\l+` | Databases with sizes |
| `\c <dbname>` | Switch to a different database |
| `\dn` | List schemas in the current database |
| `\dt` | List tables in the current schema |
| `\dt *.*` | List tables in **all** schemas |
| `\di` | List indexes |
| `\dv` | List views |
| `\df` | List functions |
| `\du` | List roles / users |
| `\d <table>` | Describe a table — columns, types, constraints |
| `\d+ <table>` | Same, with sizes and storage info |

Try these now against the `postgres` database:

```sql
\l
\dn
\dt *.*
\du
\conninfo
```

`\conninfo` shows your current connection details — host, port, user, database, and SSL status.

---

### Display Modes

By default, `psql` displays query results as a horizontal table. This becomes unreadable when tables have many columns.

**Toggle expanded (vertical) display:**

```sql
\x auto
```

With `\x auto`, `psql` automatically switches to vertical display when the output is too wide for your terminal. Try it:

```sql
SELECT * FROM pg_stat_activity;
```

Without `\x auto`, this is a wall of text. With it, each row is displayed vertically.

**Toggle query timing:**

```sql
\timing
```

This shows how long each query takes. Enable it now — you will want it for every query in the workshop.

---

### Getting Help

```sql
\?            -- list all backslash meta-commands
\h            -- list all SQL commands
\h CREATE TABLE  -- show syntax help for a specific SQL command
```

---

### Watching a Query

`\watch` re-runs the last query at a set interval — useful for monitoring:

```sql
SELECT count(*) FROM pg_stat_activity;
\watch 2
```

This runs the count every 2 seconds. Press `Ctrl+C` to stop.

---

### Command History

```sql
\s            -- print command history
```

Use `Ctrl+R` to search history interactively — type part of a previous command and `psql` will find it.

---

### Inspecting Functions

You can view the source of any function:

```sql
\sf abs(bigint)
```

This prints the `CREATE FUNCTION` definition — useful for understanding built-in or custom functions.

---

### Running SQL from a File

Instead of pasting SQL into `psql`, you can run a file:

```sql
\i /path/to/script.sql
```

Or from the command line:

```sh
psql -f /path/to/script.sql
```

This is how you will restore database dumps and run batch scripts later in the workshop.

---

### Quick Reference

| Command | Purpose |
|---|---|
| `\l` | List databases |
| `\c <db>` | Switch database |
| `\dt` | List tables |
| `\d <table>` | Describe table |
| `\du` | List roles |
| `\x auto` | Auto-toggle vertical display |
| `\timing` | Show query execution time |
| `\watch N` | Re-run last query every N seconds |
| `\s` | Command history |
| `\i file` | Run SQL from file |
| `\q` | Quit psql |

> **Next:** In the next section you will restore the `orders_demo` database and use these `psql` skills to explore its schema and run a demo workload.
```




