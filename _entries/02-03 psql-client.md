---

sectionid: psql
sectionclass: h2
parent-id: upandrunning
title: "psql: The PostgreSQL Command-Line Client"
---

`psql` is the interactive terminal for PostgreSQL. You will use it throughout this workshop to run queries, explore schemas, import data, and administer the server. This section teaches you the essential skills for working with `psql` efficiently.

> **Prerequisite:** You should have connected to PostgreSQL from the jumpbox in the previous section. If your environment variables and `.pgpass` are set up, simply run `psql` to connect.

---

> **Code block conventions used throughout this workshop:**
> - ` ```sh ` — run in the Linux shell on the jumpbox
> - ` ```sql ` — SQL sent to the PostgreSQL server (type inside psql)
> - ` ```psql ` — psql meta-commands (type inside psql, processed by the client — not sent to the server)

### Backslash Meta-Commands

Anything you type in `psql` that begins with a backslash (`\`) is a **meta-command** — it is processed by the `psql` client itself, not sent to the PostgreSQL server.

> **Note:** The meta-commands for exploring databases, schemas, tables, indexes, and roles (`\l`, `\dt`, `\dn`, `\du`, `\d`, etc.) are covered step-by-step in the **Load Data** section, where you will use them hands-on against real data. This section focuses on the `psql` session skills you need to work efficiently.

#### \conninfo — Always Verify Your Connection First

Before running any commands, confirm that you are connected to the right server, database, and user:

```psql
\conninfo
```

Example output:

```
You are connected to database "postgres" as user "pgadmin" on host "myserver.postgres.database.azure.com" at port "5432".
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
```

What each field tells you:

| Field | Why it matters |
|---|---|
| **database** | Confirms you are on `postgres` (default) or `orders_demo` (after restore) — a wrong database is the #1 cause of "table not found" errors |
| **user** | Confirms the role you connected as — important for privilege troubleshooting |
| **host** | Full FQDN of the Flexible Server — confirms you are not on localhost by mistake |
| **port** | Should be `5432` (direct) or `6432` if you are going through PgBouncer |
| **SSL** | Confirms the connection is encrypted — Azure Flexible Server enforces TLS by default |

Run `\conninfo` any time you are unsure which server or database your session is on.

---

### Display Modes

By default, `psql` displays query results as a horizontal table. This becomes unreadable when tables have many columns.

**Toggle expanded (vertical) display:**

```psql
\x auto
```

With `\x auto`, `psql` automatically switches to vertical display when the output is too wide for your terminal. Try it:

```sql
SELECT * FROM pg_stat_activity;
```

Without `\x auto`, this is a wall of text. With it, each row is displayed vertically.

**Toggle query timing:**

```psql
\timing
```

This shows how long each query takes. Enable it now — you will want it for every query in the workshop.

---

### Getting Help

```psql
\?            -- list all backslash meta-commands
\h            -- list all SQL commands
\h CREATE TABLE  -- show syntax help for a specific SQL command
```

---

### Watching a Query

`\watch` re-runs the last query at a set interval — useful for monitoring:

```sql
SELECT count(*) FROM pg_stat_activity;
```

```psql
\watch 2    -- meta-command: re-runs the last query every 2 seconds. Press Ctrl+C to stop.
```

This runs the count every 2 seconds. Press `Ctrl+C` to stop.

---

### Command History

```psql
\s            -- print command history
```

Use `Ctrl+R` to search history interactively — type part of a previous command and `psql` will find it.

---

### Inspecting Functions

You can view the source of any function:

```psql
\sf abs(bigint)
```

This prints the `CREATE FUNCTION` definition — useful for understanding built-in or custom functions.

---

### Running SQL from a File

Instead of pasting SQL into `psql`, you can run a file:

```psql
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
| `\conninfo` | Show current connection (host, port, user, database, SSL) |
| `\x auto` | Auto-toggle vertical display for wide results |
| `\timing` | Toggle query execution time display |
| `\watch N` | Re-run last query every N seconds |
| `\s` | Print command history |
| `\sf <func>` | Show function definition |
| `\i file` | Run SQL from a file |
| `\?` | List all backslash meta-commands |
| `\h <cmd>` | SQL syntax help for a command |
| `\q` | Quit psql |

> **Navigation commands** (`\l`, `\dt`, `\dn`, `\d <table>`, `\du`, etc.) are covered hands-on in the **Load Data** section.




