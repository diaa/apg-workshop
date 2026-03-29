---
sectionid: workshop-overview
sectionclass: h2
title: Workshop Overview
parent-id: intro
hide: false
---

### Architecture — Full Deployment

You will be deploying the below architecture using Bicep (Option 1 from Prerequisites). If you chose Option 2 (simple deployment), you will deploy only the PostgreSQL server with public access.

![Workshop Architecture — Full Deployment](media/architecture.png)

### Workshop Journey

Follow these 10 steps from infrastructure deployment to teardown:

![Workshop Journey — 10 Steps](media/workshop-journey.svg)

| Step | Phase | What You Do |
|---|---|---|
| 1 — Deploy | Bicep → PG Flex + jumpbox + VNets, DNS, storage | Deploy the full environment or the simple server |
| 2 — Connect | SSH to jumpbox → psql, .pg_azure, .pgpass | Establish connectivity and store credentials securely |
| 3 — Load Data | pg_restore orders_demo — 4 tables, ~410K rows | Import a realistic e-commerce dataset |
| 4 — Break Workload | 6 heavy queries — CPU + IOPS + temp spills | Run intentionally unoptimised queries to generate load |
| 5 — Admin & Access | Roles, permissions, RBAC, PgBouncer pooling | Learn PostgreSQL access control and connection pooling |
| 6 — Protect | Backup, replication, HA/DR, security, patching | Cover business continuity and security management |
| 7 — Monitor | Azure Metrics, QPI, alerts, DB profiling | Observe the impact of the broken workload |
| 8 — Diagnose | MVCC, statistics, EXPLAIN, parameter tuning | Understand *why* the workload was slow |
| 9 — Fix | Index tuning lab — before → after comparison | Add the right indexes and prove the improvement |
| 10 — Clean Up | Delete resource group, remove credentials | Tear down all resources |

