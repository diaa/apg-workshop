---
sectionid: tls
sectionclass: h2
title: Security Management
parent-id: businesscont-sec

---

### Installing pgAudit Extension

Audit logging of database activities in Azure Database for PostgreSQL - Flexible Server is available through the PostgreSQL Audit extension: **pgAudit**. It provides detailed session and/or object audit logging.

#### Step 1 — Allow the Extension

1. In the Azure Portal, go to your PostgreSQL server → **Server parameters**
2. Search for `azure.extensions`
3. Enable **pgaudit**
4. Click **Save**

![pgAudit — Allow extension](media/pgaudit01.png)

#### Step 2 — Add pgAudit to shared_preload_libraries

1. In **Server parameters**, search for `shared_preload_libraries`
2. Check **pgaudit**
3. Click **Save and Restart**

![pgAudit — shared_preload_libraries](media/pgaudit02.png)

#### Step 3 — Create the Extension

Connect to your server from the jumpbox and enable the extension:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
CREATE EXTENSION pgaudit;
```

#### Step 4 — Configure Audit Logging

1. In **Server parameters**, search for `pgaudit.log`
2. Change from `NONE` to `ALL` (or select specific categories: `READ`, `WRITE`, `DDL`, etc.)
3. Click **Save**

![pgAudit — configure logging](media/pgaudit03.png)

From this point, all database actions in your server are being audited.

#### Step 5 — Verify Audit Logging

Open a psql session and run some test commands:

<div class="lang-tag lang-tag-sql">sql</div>
```sql
CREATE TABLE audit_test(id int);
INSERT INTO audit_test SELECT generate_series(1, 100);
DROP TABLE audit_test;
```

#### Step 6 — View Audit Logs

Audit logs are sent to the **Azure diagnostic logs** pipeline. You can view them via:

**Option A — Log Analytics (recommended):**

1. Go to your PostgreSQL server → **Diagnostic settings**
2. Add a diagnostic setting that sends **PostgreSQLLogs** to a **Log Analytics workspace**
3. Click **Save**
4. After a few minutes, go to **Logs** in the left menu and run:

<div class="lang-tag lang-tag-kql">kql</div>
```kql
AzureDiagnostics
| where Category == "PostgreSQLLogs"
| where Message contains "AUDIT"
| project TimeGenerated, Message
| order by TimeGenerated desc
| take 50
```

**Option B — Azure Portal Server Logs:**

1. Go to your PostgreSQL server → **Logs** (under Monitoring)
2. Browse the recent log entries for `AUDIT:` prefixed messages

> **Note:** There is a 1–2 minute delay before log entries appear in Log Analytics.

### Summary

| Concept | Key takeaway |
|---|---|
| **pgAudit** | Extension for detailed session/object audit logging |
| **Diagnostic settings** | Route PostgreSQL logs to Log Analytics, Storage Account, or Event Hub |
| **Log Analytics** | Query audit logs with KQL for compliance and security analysis |


