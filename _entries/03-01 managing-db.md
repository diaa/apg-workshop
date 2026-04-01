---
sectionid: managing-db
sectionclass: h2
title: Managing PostgreSQL DB
parent-id: basicadmin
---

> **Note:** The Azure Portal is updated frequently. Screenshots in this section may look slightly different from what you see, but the functionality and steps are the same — you will be able to perform all tasks described here.

### Managing Compute and Storage

Navigate to **Compute + Storage** to alter storage and compute settings. You can also change the backup retention period here.

> **Note:** Increasing the compute size may incur additional costs. Only adjust if necessary.

![Compute and Storage](media/compute_storage.png)

### Managing Server Parameters

PostgreSQL's behaviour is controlled by hundreds of **server parameters** (also called GUCs — Grand Unified Configuration). These control everything from memory allocation (`shared_buffers`, `work_mem`) to query planning (`random_page_cost`), logging (`log_min_duration_statement`), replication, autovacuum thresholds, and more.

In a self-managed PostgreSQL installation, you would edit `postgresql.conf` directly. On Azure Database for PostgreSQL Flexible Server, you **do not have access to configuration files**. Instead, you manage parameters through the Azure Portal (**Server parameters** blade) or via the Azure CLI / REST API.

Changes made in the portal apply as the **server-level default** — they affect all databases, roles, and sessions unless overridden at a lower level.


![Managing parameters](media/pg-parameters.png)

#### Parameter types: Dynamic, Static, and Read-Only

Not all parameters behave the same way when you change them:

| Type | Behaviour | Examples |
|---|---|---|
| **Dynamic** | Takes effect immediately — no restart needed | `work_mem`, `log_min_duration_statement`, `statement_timeout` |
| **Static** | Requires a **server restart** to take effect. The portal will prompt you to restart after saving. | `shared_buffers`, `shared_preload_libraries`, `max_connections` |
| **Read-only** | Managed by Azure — you cannot change these. They are set based on your SKU and storage tier. | `max_locks_per_transaction`, `block_size` |

> **Tip:** In the portal, the **Server parameters** blade shows a note next to each parameter indicating whether it is dynamic or requires a restart.

#### Scope levels

You can override the server-level default at narrower scopes. Each level inherits from the one above unless explicitly overridden:

| Scope | How to set | Lifetime | Use case |
|---|---|---|---|
| **Server** (global default) | Azure Portal / CLI | Persists across restarts | Baseline configuration for all workloads |
| **Database** | [`ALTER DATABASE`](https://www.postgresql.org/docs/current/sql-alterdatabase.html) `dbname SET param = value;` | Persists — applies to all sessions in that database | Different `work_mem` for an analytics DB vs. OLTP DB |
| **Role** | [`ALTER ROLE`](https://www.postgresql.org/docs/current/sql-alterrole.html) `username SET param = value;` | Persists — applies whenever that role connects | Higher `statement_timeout` for a batch-processing role |
| **Session** | [`SET`](https://www.postgresql.org/docs/current/sql-set.html) `param = value;` | Current session only — lost on disconnect | Temporary tuning for a specific query or script |

To check the current effective value of any parameter in your session:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SHOW work_mem;
```

To see all non-default parameter values:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SELECT name, setting, source
FROM pg_settings
WHERE source != 'default'
ORDER BY name;
```


To enable PgBouncer, type **pgbouncer** in the search box and set its value to **TRUE**:

![Managing parameters](media/pgbouncer.png)

Click **Save** and wait for the deployment to complete successfully:

![Managing parameters](media/pgbouncer-success.png)

Once you see the success screen, access PostgreSQL through port 6432 on your VM:

<div class="lang-tag lang-tag-shell">shell</div>
```sh
psql -p 6432
```
![Managing parameters](media/pgbouncer-test.png)

> **Want to go deeper?** For pool modes, `pgbench` load testing, and PgBouncer monitoring commands, see [Connection Pooling with PgBouncer](#pgbouncer).

### Applying Server Locks

Navigate to **Locks**:

![Managing locks](media/pg-server-locks.png)

Click **+Add**, enter a lock name of your choice, and select the lock type **Delete**:

![Managing locks](media/pg-delete-locks.png)

If you attempt to delete the server, you should see an error similar to the following:

![Managing locks](media/pg-delete-lock-error.png)