---
sectionid: extensions
sectionclass: h2
title: "Extensions Overview (Optional)"
parent-id: day2
---

> **This section is optional.** Complete it at your own pace if time permits, or after the workshop as self-study.

Extensions are what make PostgreSQL uniquely powerful. They let you add new data types, functions, index methods, and even entire subsystems without forking the core engine. Azure Flexible Server supports a curated list of extensions — you don't install binaries, you just `CREATE EXTENSION`.

---

### Step 1 — See What's Available

From the jumpbox, connect to `orders_demo`:

<div class="lang-tag lang-tag-shell">shell</div>
```sh
psql -h <postgresql-fqdn> -U <pgadmin> -d orders_demo
```

List all extensions that Azure Flexible Server allows:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SHOW azure.extensions;
```

This returns a comma-separated list. To see the full catalog of extensions available for installation:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SELECT name, default_version, comment
FROM pg_available_extensions
ORDER BY name;
```

List extensions already installed in this database:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SELECT extname, extversion FROM pg_extension ORDER BY extname;
```

You should see at least `plpgsql` (always installed) and `pg_stat_statements` (if you enabled it in the [Monitoring](#azure-monitoring) section).

---

### Step 2 — pg_stat_statements (Already in Use)

You have already been using this throughout the workshop. Quick recap:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- Top queries by execution time
SELECT calls, ROUND(total_exec_time::numeric, 2) AS total_ms,
       ROUND(mean_exec_time::numeric, 2) AS mean_ms,
       LEFT(query, 120) AS query
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 10;
```

This extension is **critical** for production — it's how you find your slowest queries.

---

### Step 3 — pg_trgm (Trigram Text Search)

`pg_trgm` provides fast text similarity searches — useful for fuzzy matching, autocomplete, and `LIKE '%pattern%'` queries that can't use standard B-tree indexes.

<div class="lang-tag lang-tag-sql">sql</div>
```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
```

#### Lab — Fuzzy Customer Search

Without an index, a `LIKE` search on a text column is always a sequential scan:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
EXPLAIN (ANALYZE)
SELECT customer_id, first_name, last_name, email
FROM customers
WHERE email LIKE '%jones%';
```

You will see `Seq Scan` and `Filter`. Now add a trigram GIN index:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
CREATE INDEX idx_customers_email_trgm ON customers USING gin (email gin_trgm_ops);
```

Re-run:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
EXPLAIN (ANALYZE)
SELECT customer_id, first_name, last_name, email
FROM customers
WHERE email LIKE '%jones%';
```

The planner now uses `Bitmap Index Scan` on the GIN index — much faster.

**Similarity search:**

<div class="lang-tag lang-tag-sql">sql</div>
```sql
-- Find customers with names similar to "Smith" (typo-tolerant)
SELECT customer_id, first_name, last_name, similarity(last_name, 'Smith') AS sim
FROM customers
WHERE last_name % 'Smith'
ORDER BY sim DESC
LIMIT 10;
```

The `%` operator returns `true` if the similarity score exceeds `pg_trgm.similarity_threshold` (default 0.3).

Clean up:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
DROP INDEX idx_customers_email_trgm;
```

---

### Step 4 — uuid-ossp and gen_random_uuid()

For generating UUIDs (common for distributed IDs, API keys, etc.):

<div class="lang-tag lang-tag-sql">sql</div>
```sql
-- PostgreSQL 18: gen_random_uuid() is built-in, no extension needed
SELECT gen_random_uuid();

-- If you need other UUID versions (v1, v3, v5):
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
SELECT uuid_generate_v4();  -- random UUID (same as gen_random_uuid)
SELECT uuid_generate_v1();  -- time + MAC-based UUID
```

---

### Step 5 — pgcrypto (Hashing & Encryption)

For password hashing, data encryption, and generating random bytes:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- Hash a password with bcrypt (adaptive cost)
SELECT crypt('my_password', gen_salt('bf', 10)) AS hashed;

-- Verify a password
SELECT (crypt('my_password', hashed) = hashed) AS password_matches
FROM (SELECT crypt('my_password', gen_salt('bf', 10)) AS hashed) sub;

-- Generate random bytes (useful for tokens)
SELECT encode(gen_random_bytes(32), 'hex') AS random_token;
```

---

### Step 6 — pg_cron (Scheduled Jobs)

`pg_cron` lets you schedule recurring SQL jobs directly in PostgreSQL — like a database-level cron. On Azure Flexible Server, it's available via server parameters.

**Enable pg_cron:**

1. Azure Portal → Server parameters
2. Search for `shared_preload_libraries` → ensure `pg_cron` is checked
3. Search for `cron.database_name` → set to `orders_demo`
4. Save (requires restart)

After restart:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Schedule a vacuum every night at 3am UTC
SELECT cron.schedule('nightly-vacuum', '0 3 * * *', 'VACUUM ANALYZE orders');

-- Schedule a stats reset every Sunday
SELECT cron.schedule('weekly-stats-reset', '0 0 * * 0', 'SELECT pg_stat_reset()');

-- List scheduled jobs
SELECT * FROM cron.job;

-- Remove a job
SELECT cron.unschedule('nightly-vacuum');
```

---

### Step 7 — Explore with orders_demo

Try these extension-powered queries against the demo data:

**Trigram search — find orders from cities like "London":**

<div class="lang-tag lang-tag-sql">sql</div>
```sql
CREATE INDEX idx_cust_city_trgm ON customers USING gin (city gin_trgm_ops);

-- Typo-tolerant city search
SELECT customer_id, city, country
FROM customers
WHERE city % 'Londen'
ORDER BY similarity(city, 'Londen') DESC
LIMIT 10;

DROP INDEX idx_cust_city_trgm;
```

**Generate UUIDs for anonymised export:**

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SELECT gen_random_uuid() AS anon_id, city, country, loyalty_points
FROM customers
LIMIT 5;
```

**Hash email addresses for privacy:**

<div class="lang-tag lang-tag-sql">sql</div>
```sql
SELECT customer_id,
       encode(digest(email, 'sha256'), 'hex') AS email_hash,
       city, country
FROM customers
LIMIT 5;
```

---

### Quick Reference — Commonly Used Extensions

| Extension | Purpose | Requires Restart? |
|---|---|---|
| `pg_stat_statements` | Query performance statistics | Yes (shared_preload_libraries) |
| `pg_trgm` | Trigram text similarity & fuzzy search | No |
| `uuid-ossp` | UUID generation (v1, v3, v4, v5) | No |
| `pgcrypto` | Hashing, encryption, random data | No |
| `pg_cron` | Scheduled jobs (cron syntax) | Yes (shared_preload_libraries) |
| `postgis` | Geographic/spatial data & queries | No |
| `hstore` | Key-value store data type | No |
| `citext` | Case-insensitive text type | No |
| `pg_buffercache` | Inspect shared buffer contents | No |
| `pg_prewarm` | Preload tables/indexes into cache | No |
| `azure_storage` | Query Azure Blob Storage from SQL | No |

---

### Clean Up

Remove the extensions you installed (optional — they don't affect the other sections):

<div class="lang-tag lang-tag-sql">sql</div>
```sql
DROP EXTENSION IF EXISTS pg_trgm;
DROP EXTENSION IF EXISTS "uuid-ossp";
DROP EXTENSION IF EXISTS pgcrypto;
-- Keep pg_stat_statements — it's used throughout the workshop
```