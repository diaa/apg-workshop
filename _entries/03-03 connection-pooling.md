---

sectionid: pgbouncer
sectionclass: h2
parent-id: basicadmin
title: "Connection Pooling with PgBouncer (Optional)"
---

> **This section is optional.** Complete it at your own pace if time permits, or after the workshop as self-study.

PostgreSQL creates a **new process** for every client connection. Each process consumes 5–10 MB of memory and a slot in the connection table. With hundreds of application instances opening connections, this becomes a bottleneck — even if most connections are idle.

Azure Database for PostgreSQL Flexible Server includes a **built-in PgBouncer** connection pooler. This section shows you how to enable it and measure the difference.

---

### Why Connection Pooling Matters

| Without pooling | With pooling |
|---|---|
| 100 app instances = 100 PostgreSQL processes | 100 app instances → PgBouncer → 20 PostgreSQL processes |
| Each process: ~5–10 MB RAM | Shared pool: much less total RAM |
| Connection setup: ~5–50 ms per connection (TCP + TLS + auth) | Connection reuse: < 1 ms |
| Max connections limit hit easily | App can open many connections safely |

**How it differs from Oracle and SQL Server:**
- **Oracle:** Uses a thread-based model with shared server processes. Connection pooling is at the app level (e.g., Oracle Connection Pool in JDBC).
- **SQL Server:** Uses thread-per-request with lightweight worker threads (~512 KB each). Built-in connection pooling in ADO.NET.
- **PostgreSQL:** Process-per-connection (~5–10 MB each). Connection pooling is **external** — PgBouncer, PgPool-II, or the built-in PgBouncer in Azure.

---

### Step 1 — Check Current Connection Usage

Connect to `orders_demo`:

```sh
psql -h <postgresql-fqdn> -U <pgadmin> -d orders_demo
```

Once connected, check the current connections:

```sql
-- Current connections
SELECT count(*) AS total_connections FROM pg_stat_activity;

-- Breakdown by state
SELECT state, count(*)
FROM pg_stat_activity
GROUP BY state
ORDER BY count DESC;

-- Max allowed
SHOW max_connections;
```

---

### Step 2 — Enable Built-in PgBouncer

1. Go to **Azure Portal** → your PostgreSQL server → **Server parameters**
2. Search for `pgbouncer.enabled`
3. Set to **true**
4. Configure these parameters:

| Parameter | Recommended Value | Meaning |
|---|---|---|
| `pgbouncer.enabled` | `true` | Enables the built-in PgBouncer |
| `pgbouncer.pool_mode` | `transaction` | Connections are returned to the pool after each transaction |
| `pgbouncer.default_pool_size` | `20` | Max server connections per user/database pair |
| `pgbouncer.max_client_conn` | `200` | Max client connections PgBouncer accepts |
| `pgbouncer.min_pool_size` | `5` | Minimum idle connections kept warm |

5. Click **Save**

**Pool modes explained:**

| Mode | Connection returned when | Use case |
|---|---|---|
| `session` | Client disconnects | Long-lived sessions, PREPARE/LISTEN | 
| `transaction` | Transaction ends (COMMIT/ROLLBACK) | Most web apps — **recommended** |
| `statement` | Each SQL statement completes | Multi-statement transactions break — rarely used |

> **Warning:** In `transaction` mode, session-level features like `SET`, `PREPARE`, temporary tables, and `LISTEN/NOTIFY` do not persist across transactions. If your application relies on these, use `session` mode.

---

### Step 3 — Connect Through PgBouncer

PgBouncer listens on port **6432** (not the default 5432):

```sh
psql -h <postgresql-fqdn> -U <pgadmin> -d orders_demo -p 6432
```

Verify you're going through PgBouncer:

```sql
SHOW server_version;  -- works: forwarded to PostgreSQL
```

Run a query to confirm:

```sql
SELECT count(*) FROM orders;
```

---

### Step 4 — Load Test: With and Without PgBouncer

Use `pgbench` from the jumpbox to simulate concurrent connections.

#### Without PgBouncer (port 5432):

```bash
pgbench -h <postgresql-fqdn> -U <pgadmin> -d orders_demo -p 5432 \
  -c 50 -j 4 -T 30 -S
```

Flags:
- `-c 50` — 50 concurrent client connections
- `-j 4` — 4 worker threads
- `-T 30` — run for 30 seconds
- `-S` — SELECT-only workload (read-only)

Note the **TPS (transactions per second)** and **latency average**.

#### With PgBouncer (port 6432):

```bash
pgbench -h <postgresql-fqdn> -U <pgadmin> -d orders_demo -p 6432 \
  -c 50 -j 4 -T 30 -S
```

Compare:

| Metric | Port 5432 (direct) | Port 6432 (PgBouncer) |
|---|---|---|
| TPS | _____ | _____ |
| Avg latency (ms) | _____ | _____ |
| Connection errors | _____ | _____ |

Typical results:
- PgBouncer shows higher TPS and lower latency because connection setup is eliminated
- At higher concurrency (200+ clients), direct connections may hit `max_connections` and fail; PgBouncer queues them

---

### Step 5 — Monitor PgBouncer via Server Parameters

PgBouncer statistics are available through the `pgbouncer` virtual database:

```sh
psql -h <postgresql-fqdn> -U <pgadmin> -d pgbouncer -p 6432

SHOW POOLS;
SHOW STATS;
SHOW CLIENTS;
SHOW SERVERS;
```

| View | Shows |
|---|---|
| `SHOW POOLS` | Active/waiting/idle connections per pool |
| `SHOW STATS` | Requests, bytes in/out, query time per pool |
| `SHOW CLIENTS` | Every connected client and their state |
| `SHOW SERVERS` | Backend PostgreSQL connections being used |

---

### Summary

| Concept | Key takeaway |
|---|---|
| **Process-per-connection** | PostgreSQL forks a process for each client — expensive at scale |
| **PgBouncer** | Multiplexes many client connections onto fewer backend connections |
| **Transaction mode** | Best for web apps — connections are recycled after each COMMIT |
| **Port 6432** | Built-in PgBouncer listens here on Azure Flexible Server |
| **pgbench** | Built-in tool for load testing connection handling |