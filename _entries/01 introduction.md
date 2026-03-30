---
sectionid: intro
sectionclass: h1
title: The Azure PostgreSQL Workshop
type: nocount
is-parent: yes
---

Welcome to the **Azure PostgreSQL Workshop** — a hands-on, scenario-driven lab that takes you from zero to confidently operating Azure Database for PostgreSQL Flexible Server in production.

You will deploy infrastructure with Bicep, load realistic data, deliberately break things, observe the damage through monitoring, diagnose root causes, and fix them — the same cycle you follow in real operations.

This is a **two-day workshop**. We'll move at a comfortable pace with plenty of time for questions, discussion, and troubleshooting. Whether you're coming from an Oracle, SQL Server, or cloud-native background — please ask questions as we go. There are no silly questions, and the best workshops are the ones where everyone participates!

### Who Is This For?

- **Developers** building applications on Azure PostgreSQL who want to understand the platform deeply
- **Platform / DevOps engineers** responsible for deploying, securing, and monitoring PostgreSQL on Azure
- **DBAs** migrating from Oracle, or on-premises PostgreSQL to Azure

### Workshop Journey

Follow these 10 steps from infrastructure deployment to teardown:

![Workshop Journey — 10 Steps](media/workshop-journey.svg)

| Step | Phase | What You Do |
|---|---|---|
| 1 — Deploy | Bicep → PG Flex + jumpbox + VNets, DNS, storage | Deploy the full environment or the simple server |
| 2 — Connect | SSH to jumpbox → psql, .pg_azure, .pgpass | Establish connectivity and store credentials securely |
| 3 — Load Data | pg_restore orders_demo — 4 tables, ~410K rows | Import a realistic e-commerce dataset |
| 4 — Break Workload | 6 heavy queries — CPU + IOPS + temp spills | Run intentionally unoptimised queries to generate load |
| 5 — Monitor | Azure Metrics, QPI, alerts, diagnostic settings | Observe the impact while the damage is fresh |
| 6 — Admin & Access | Roles, permissions, RBAC, PgBouncer pooling | Learn PostgreSQL access control and connection pooling |
| 7 — Protect | Backup, replication, HA/DR, security, patching | Cover business continuity and security management |
| 8 — Diagnose | DB profiling, MVCC, statistics, EXPLAIN, parameter tuning | Understand *why* the workload was slow |
| 9 — Fix | Index tuning lab — before → after comparison | Add the right indexes and prove the improvement |
| 10 — Clean Up | Delete resource group, remove credentials | Tear down all resources |

### Day 1 — Deploy, Connect, Monitor, Administer & Protect

| Time | Session | What We'll Do | Duration |
|---|---|---|---|
| 09:00 | **Welcome & Setup** | Introductions, prerequisites, Azure Cloud Shell | 30 min |
| 09:30 | **Deploy** | Bicep → PostgreSQL Flex + jumpbox + VNets, DNS, storage | 35 min |
| 10:05 | **Connect** | SSH to jumpbox, psql basics, SSH tunnels, VS Code | 40 min |
| 10:45 | ☕ **Break** | | 15 min |
| 11:00 | **Load Data** | Restore orders_demo (4 tables, ~410K rows), explore the schema | 25 min |
| 11:25 | **Break the Workload** | Run 6 intentionally heavy queries — CPU, IOPS, temp spills | 25 min |
| 11:50 | **Q&A — Morning Recap** | Questions on everything so far, troubleshoot any setup issues | 10 min |
| 12:00 | 🍽️ **Lunch** | | 60 min |
| 13:00 | **Azure Monitoring** | Portal metrics, QPI, KQL, alerts — correlate spikes to the demo queries | 35 min |
| 13:35 | **Administration & Roles** | Server parameters, roles, GRANT/REVOKE, INHERIT vs NOINHERIT | 50 min |
| 14:25 | ☕ **Break** | | 15 min |
| 14:40 | **Logical Backup** | pg_dump / pg_restore — formats, selective restore, verification | 25 min |
| 15:05 | **Business Continuity** | Physical backup & PITR, HA/DR failover, security & patching | 30 min |
| 15:35 | **Q&A — Day 1 Wrap-up** | Open discussion, review key concepts, preview of Day 2 | 25 min |
| 16:00 | **End of Day 1** | | |

### Day 2 — Profile, Diagnose & Fix

| Time | Session | What We'll Do | Duration |
|---|---|---|---|
| 09:00 | **Day 2 Kick-off** | Quick recap of Day 1, questions from overnight | 10 min |
| 09:10 | **Database Profiling** | 22 diagnostic queries — health check & performance triage scripts | 50 min |
| 10:00 | ☕ **Break** | | 15 min |
| 10:15 | **MVCC & Autovacuum** | Dead tuples, VACUUM vs VACUUM FULL, bloat, autovacuum tuning | 30 min |
| 10:45 | **Parameter Tuning** | work_mem, shared_buffers, effective_cache_size — measure the impact | 30 min |
| 11:15 | **Q&A — Internals** | Pause for questions — this is the densest part of the workshop | 15 min |
| 11:30 | **SQL Characteristics** | Partial indexes, JSONB, GIN indexes — PostgreSQL superpowers | 20 min |
| 11:50 | **Statistics & Query Planning** | EXPLAIN, cost model, join algorithms — nested loop vs hash vs merge | 25 min |
| 12:15 | 🍽️ **Lunch** | | 60 min |
| 13:15 | **Index Tuning Lab** | Add 5 indexes, re-run the broken workload, measure 2–50× speedup | 45 min |
| 14:00 | ☕ **Break** | | 15 min |
| 14:15 | **Extensions** *(optional)* | pg_trgm, uuid-ossp, pgcrypto, pg_cron | 20 min |
| 14:35 | **Clean Up** | Delete resource group, verify everything is gone | 10 min |
| 14:45 | **Final Q&A & Wrap-up** | Open floor — ask anything! Feedback, next steps, resources | 30 min |
| 15:15 | **End of Workshop** | | |

### What You Will Learn

| Theme | Topics |
|---|---|
| **Deployment & Access** | Bicep IaC, Azure Flexible Server provisioning, networking (VNet, private DNS, peering), connection methods (psql, SSH tunnel, VS Code), roles & permissions, connection pooling |
| **Business Continuity & Security** | Logical backup (pg_dump / pg_restore), physical backup & PITR, logical replication, HA/DR with zone redundancy, patching & maintenance windows, pgAudit & security management |
| **Day Two Operations** | Azure Monitor metrics, Query Performance Insight, database profiling (catalog views), MVCC & autovacuum, parameter tuning (work_mem, shared_buffers), EXPLAIN & statistics, index tuning, SQL features (partial indexes, JSONB), extensions |

