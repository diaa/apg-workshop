---
sectionid: workshop-overview
sectionclass: h2
title: Workshop Overview
parent-id: intro
published: false
---

### Architecture — Full Deployment

You will be deploying the below architecture using Bicep (Option 1 from Prerequisites). If you chose Option 2 (simple deployment), you will deploy only the PostgreSQL server with public access.

![Workshop Architecture — Full Deployment](media/architecture.png)

### Day 1 — Deploy, Connect, Monitor, Administer & Protect

| Time | Topic | What You'll Do |
|---|---|---|
| 09:00–10:45 | Deploy & Connect | Bicep deployment, SSH, psql basics, .pgpass |
| 11:00–12:00 | Load Data & Break Things | Restore `orders_demo`, run CPU-heavy demo workload |
| 13:00–13:35 | Azure Monitoring | Metrics Explorer, QPI, KQL queries, alerts |
| 13:35–14:25 | Admin & Roles | Server parameters, role inheritance, permissions |
| 14:40–16:00 | Business Continuity & Security | Backup/restore, HA/DR, patching, pgAudit |

### Day 2 — Profile, Diagnose & Fix

| Time | Topic | What You'll Do |
|---|---|---|
| 09:10–10:00 | Database Profiling | 22-query health check against catalog views |
| 10:15–10:45 | MVCC Deep Dive | xmin/xmax, dead tuples, VACUUM vs VACUUM FULL |
| 10:45–11:10 | Statistics & Query Planning | EXPLAIN, cost formula, join algorithms |
| 11:10–11:50 | Parameter Tuning | work_mem, maintenance_work_mem, random_page_cost |
| 11:50–13:45 | Index Tuning Lab | Baseline → add indexes → measure 10–50× improvement |
| 13:45–14:05 | Query Rewriting | Correlated subquery → JOIN, LATERAL, CTE inlining |
| 14:20–14:40 | SQL Characteristics | Partial indexes, JSONB operators, GIN indexes |
| 14:40–15:00 | Partitioning | Range/list partitioning, partition pruning, attach/detach |
| 15:00–15:30 | Extensions & Cleanup | pg_trgm, pgcrypto, pg_cron; delete all resources |



