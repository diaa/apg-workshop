---
sectionid: roles
sectionclass: h2
title: Roles and Permissions
parent-id: basicadmin
---

In this section you will learn how PostgreSQL manages access control through its **role** system — creating roles, granting privileges, understanding inheritance, and applying least-privilege principles.

> **Prerequisite:** You should have the `quiz` database from the **Data Import** section. If you skipped it, run the CREATE statements from that section first.

---

### Lab Overview

The diagram below shows the complete role hierarchy and permission model you will build in this lab.

```mermaid
graph TB
    subgraph Azure Managed
        azuresu["🔒 azuresu<br/><i>Superuser — Azure managed</i>"]
        azure_pg_admin["azure_pg_admin<br/><i>Create role, Create DB,<br/>Bypass RLS, Replication</i>"]
    end

    subgraph Your Admin
        admin["&lt;your-admin&gt;<br/><i>Login ✅ — member of azure_pg_admin</i>"]
    end

    azure_pg_admin -- "member of" --> azuresu
    admin -- "member of" --> azure_pg_admin

    subgraph Group Roles — Cannot Login
        app_team["app_team<br/><i>NOLOGIN</i>"]
        readonly["readonly<br/><i>NOLOGIN</i>"]
    end

    subgraph Login Roles — Users
        dev_user["dev_user<br/><i>LOGIN — INHERIT ✅</i>"]
        analyst["analyst_user<br/><i>LOGIN — INHERIT ✅</i>"]
        contractor["contractor_user<br/><i>LOGIN — NOINHERIT ⚠️<br/>CONNECTION LIMIT 2</i>"]
    end

    dev_user -- "member of<br/>(inherits automatically)" --> app_team
    contractor -- "member of<br/>(must SET ROLE)" --> app_team
    analyst -- "member of<br/>(inherits automatically)" --> readonly

    subgraph Quiz Database — public schema
        answers["📋 answers table"]
        questions["📋 questions table"]
    end

    app_team -- "ALL privileges<br/>(SELECT, INSERT,<br/>UPDATE, DELETE, ...)" --> answers
    app_team -- "ALL privileges" --> questions
    readonly -- "SELECT only" --> answers
    readonly -- "SELECT only" --> questions

    style azuresu fill:#ff6b6b,stroke:#c0392b,color:#fff
    style azure_pg_admin fill:#e74c3c,stroke:#c0392b,color:#fff
    style admin fill:#3498db,stroke:#2980b9,color:#fff
    style app_team fill:#2ecc71,stroke:#27ae60,color:#fff
    style readonly fill:#f39c12,stroke:#e67e22,color:#fff
    style dev_user fill:#2ecc71,stroke:#27ae60,color:#fff
    style analyst fill:#f39c12,stroke:#e67e22,color:#fff
    style contractor fill:#e67e22,stroke:#d35400,color:#fff
    style answers fill:#ecf0f1,stroke:#bdc3c7,color:#2c3e50
    style questions fill:#ecf0f1,stroke:#bdc3c7,color:#2c3e50
```

**How to read the diagram:**
- **Red** = Azure-managed roles (you cannot use these directly)
- **Blue** = your admin user (the account you deployed with)
- **Green** = `app_team` path — full read/write access. `dev_user` inherits automatically; `contractor_user` must explicitly `SET ROLE` to activate.
- **Orange** = `readonly` path — SELECT only. `analyst_user` inherits automatically.
- Solid arrows show membership. Privilege arrows show what each group role can do on the quiz database tables.

```mermaid
flowchart LR
    subgraph INHERIT — dev_user
        A["dev_user connects"] --> B["Automatically has<br/>app_team privileges"]
        B --> C["✅ SELECT, INSERT,<br/>UPDATE, DELETE"]
    end

    subgraph NOINHERIT — contractor_user
        D["contractor_user connects"] --> E["❌ No privileges<br/>by default"]
        E --> F["SET ROLE app_team"]
        F --> G["✅ Now has<br/>app_team privileges"]
    end

    style A fill:#2ecc71,stroke:#27ae60,color:#fff
    style B fill:#2ecc71,stroke:#27ae60,color:#fff
    style C fill:#2ecc71,stroke:#27ae60,color:#fff
    style D fill:#e67e22,stroke:#d35400,color:#fff
    style E fill:#e74c3c,stroke:#c0392b,color:#fff
    style F fill:#f39c12,stroke:#e67e22,color:#fff
    style G fill:#2ecc71,stroke:#27ae60,color:#fff
```

---

### Understanding Roles in PostgreSQL

PostgreSQL has a single concept for managing access: the **role**. There are no separate "users" and "groups" — everything is a role. The `CREATE USER` and `CREATE GROUP` commands are just convenience aliases:

| Command | What it actually does |
|---|---|
| `CREATE ROLE app_role;` | Creates a role that **cannot login** by default |
| `CREATE USER app_user;` | Same as `CREATE ROLE app_user LOGIN;` — adds login capability |
| `CREATE GROUP app_group;` | Same as `CREATE ROLE app_group;` — deprecated alias |

This is fundamentally different from Oracle (where users and roles are distinct objects) and SQL Server (where logins, users, and roles are separate layers).

---

### Azure Flexible Server Role Hierarchy

On Azure Database for PostgreSQL Flexible Server, the admin user you created during deployment is **not** a superuser. Instead, it is a member of the `azure_pg_admin` role, which has most — but not all — superuser privileges.

Connect to the server from the jumpbox:

```sql
psql -h <postgresql-fqdn> -U <pgadmin> -d postgres
```

View the existing roles:

```sql
\du
```

You will see something like:

```
                                       List of roles
    Role name     |                         Attributes                         | Member of
------------------+------------------------------------------------------------+------------------
 azure_pg_admin   | Create role, Create DB, Bypass RLS, Replication            | {}
 <your-admin>     | Create role, Create DB                                     | {azure_pg_admin}
 azuresu          | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
```

Key points:
- **`azuresu`** — the true superuser, managed by Azure. You cannot use this role.
- **`azure_pg_admin`** — the highest role available to you. Your admin user is a member of this role.
- **`<your-admin>`** — your admin user. It can create roles, create databases, and grant privileges, but it cannot load extensions that require superuser or access the file system.

---

### Step 1 — Create Application Roles

A good practice is to create a **group role** (cannot login) that holds privileges, then add **login roles** (users) as members.

```sql
-- Create a group role for the application team
CREATE ROLE app_team NOLOGIN;

-- Create a read-only role
CREATE ROLE readonly NOLOGIN;
```

Now create two users and assign them to roles:

```sql
-- Developer: inherits app_team privileges automatically
CREATE ROLE dev_user LOGIN PASSWORD 'Workshop#Dev1' IN ROLE app_team INHERIT;

-- Analyst: inherits readonly privileges automatically
CREATE ROLE analyst_user LOGIN PASSWORD 'Workshop#Read1' IN ROLE readonly INHERIT;

-- Contractor: member of app_team but does NOT inherit privileges automatically
CREATE ROLE contractor_user LOGIN PASSWORD 'Workshop#Ext1' IN ROLE app_team NOINHERIT CONNECTION LIMIT 2;
```

Verify the roles:

```sql
\du
```

```
    Role name        |                 Attributes                      | Member of
---------------------+-------------------------------------------------+------------------
 analyst_user        |                                                 | {readonly}
 app_team            | Cannot login                                    | {}
 contractor_user     | No inheritance, 2 connections                   | {app_team}
 dev_user            |                                                 | {app_team}
 readonly            | Cannot login                                    | {}
```

---

### Step 2 — Grant Privileges on the Quiz Database

Switch to the `quiz` database:

```sql
\c quiz
```

Grant privileges to each group role:

```sql
-- app_team gets full access to all tables and sequences in public
GRANT USAGE ON SCHEMA public TO app_team;
GRANT ALL ON ALL TABLES IN SCHEMA public TO app_team;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO app_team;

-- readonly gets SELECT only
GRANT USAGE ON SCHEMA public TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;
```

> **Why GRANT USAGE ON SCHEMA?** In PostgreSQL, even if you have table-level privileges, you also need `USAGE` on the schema that contains the table. This is a common gotcha for people coming from Oracle or SQL Server where schema access works differently.

---

### Step 3 — Test INHERIT vs NOINHERIT

This is the most important concept in this section. Use `SET ROLE` to impersonate each user and see the difference.

First, grant yourself the ability to switch to these roles:

```sql
-- Run as your admin user
GRANT dev_user TO <your-admin>;
GRANT analyst_user TO <your-admin>;
GRANT contractor_user TO <your-admin>;
```

#### Test `dev_user` (INHERIT):

```sql
SET ROLE dev_user;

-- This should work — dev_user inherits app_team privileges
SELECT * FROM answers;

-- This should also work — app_team has ALL privileges
INSERT INTO questions (question_id, question) VALUES (2, 'What is the capital of France?');

-- Switch back
RESET ROLE;
```

#### Test `analyst_user` (INHERIT, readonly):

```sql
SET ROLE analyst_user;

-- SELECT works — analyst_user inherits readonly privileges
SELECT * FROM answers;

-- INSERT fails — readonly only has SELECT
INSERT INTO questions (question_id, question) VALUES (3, 'Test');
-- ERROR: permission denied for table questions

RESET ROLE;
```

#### Test `contractor_user` (NOINHERIT):

```sql
SET ROLE contractor_user;

-- This FAILS — contractor_user does NOT inherit app_team privileges
SELECT * FROM answers;
-- ERROR: permission denied for table answers
```

**Why?** `contractor_user` was created with `NOINHERIT`. Even though it is a member of `app_team`, it does not automatically receive `app_team`'s privileges. The user must explicitly activate the role:

```sql
-- Explicitly activate the parent role
SET ROLE app_team;

-- Now it works
SELECT * FROM answers;

RESET ROLE;
```

**When to use NOINHERIT:** For users who should have access but must consciously "elevate" to use it — similar to `sudo` on Linux or `runas` on Windows. Useful for contractors, automated accounts, or break-glass scenarios.

```
┌─────────────────────────────────────────────────────┐
│  INHERIT (dev_user)        NOINHERIT (contractor)   │
│                                                     │
│  dev_user ──inherits──► app_team privileges         │
│  (automatic)                                        │
│                                                     │
│  contractor ──member of──► app_team                 │
│  (must SET ROLE to activate)                        │
└─────────────────────────────────────────────────────┘
```

---

### Step 4 — View and Read Privilege Codes

Run the following to see all granted privileges:

```sql
RESET ROLE;
\dp
```

You will see output like:

```
                                  Access privileges
 Schema |   Name    | Type  |       Access privileges        | ...
--------+-----------+-------+--------------------------------+
 public | answers   | table | <admin>=arwdDxt/<admin>       +|
        |           |       | app_team=arwdDxt/<admin>      +|
        |           |       | readonly=r/<admin>             |
 public | questions | table | <admin>=arwdDxt/<admin>       +|
        |           |       | app_team=arwdDxt/<admin>      +|
        |           |       | readonly=r/<admin>             |
```

**Reading the privilege codes:**

| Code | Privilege | Applies to |
|---|---|---|
| `r` | SELECT (read) | Tables, views |
| `a` | INSERT (append) | Tables |
| `w` | UPDATE (write) | Tables |
| `d` | DELETE | Tables |
| `D` | TRUNCATE | Tables |
| `x` | REFERENCES | Tables (foreign keys) |
| `t` | TRIGGER | Tables |
| `U` | USAGE | Schemas, sequences |
| `C` | CREATE | Schemas, databases |
| `c` | CONNECT | Databases |
| `T` | TEMPORARY | Databases |

The format is `role=privileges/grantor`. So `app_team=arwdDxt/<admin>` means: `app_team` has SELECT, INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, and TRIGGER on this table, granted by your admin user.

---

### Step 5 — REVOKE Privileges

Remove INSERT/UPDATE/DELETE from `app_team` on the `answers` table, keeping only SELECT:

```sql
REVOKE INSERT, UPDATE, DELETE ON TABLE answers FROM app_team;
```

Verify:

```sql
SET ROLE dev_user;

-- SELECT still works
SELECT * FROM answers;

-- INSERT now fails
INSERT INTO answers (question_id, answer, is_correct) VALUES (1, 'Test', false);
-- ERROR: permission denied for table answers

RESET ROLE;
```

Check the privilege codes again:

```sql
\dp answers
```

You should see `app_team=rDxt/<admin>` — the `a`, `w`, and `d` codes are gone.

---

### Step 6 — Default Privileges for Future Tables

The `GRANT ALL ON ALL TABLES` command only affects tables that **already exist**. If you create a new table later, the grants are not applied automatically. This catches many people by surprise.

Fix this with `ALTER DEFAULT PRIVILEGES`:

```sql
-- Any future table created by your admin in the public schema
-- will automatically grant SELECT to readonly and ALL to app_team
ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT SELECT ON TABLES TO readonly;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
  GRANT ALL ON TABLES TO app_team;
```

Test it:

```sql
-- Create a new table
CREATE TABLE test_defaults (id serial, name text);

-- Check privileges — readonly and app_team should already have access
\dp test_defaults
```

You should see `readonly=r/<admin>` and `app_team=arwdDxt/<admin>` without any explicit GRANT.

Clean up:

```sql
DROP TABLE test_defaults;
```

---

### Step 7 — Schema-Level Isolation

For a more realistic setup, create a separate schema for the application and restrict the `public` schema:

```sql
-- Create an application schema
CREATE SCHEMA app AUTHORIZATION app_team;

-- Revoke default public access (PostgreSQL grants USAGE + CREATE on public to everyone by default)
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
```

> **About the `PUBLIC` keyword:** In PostgreSQL, `PUBLIC` (all-caps in GRANT/REVOKE context) means "every role." By default, every role has `USAGE` and `CREATE` on the `public` schema — this is a well-known security concern. Revoking `CREATE` from `PUBLIC` is a recommended hardening step.

---

### Step 8 — Verify Permissions Work End-to-End

Open a **new** psql session as `dev_user` to verify everything works without `SET ROLE`:

```sql
-- On the jumpbox, open a new connection
psql -h <postgresql-fqdn> -U dev_user -d quiz
```

```sql
-- Should work (inherited from app_team → readonly has SELECT, app_team has ALL on questions)
SELECT * FROM questions;

-- Should fail (we revoked INSERT on answers from app_team in Step 5)
INSERT INTO answers (question_id, answer, is_correct) VALUES (1, 'Test', false);
-- ERROR: permission denied for table answers

-- Disconnect
\q
```

---

### Step 9 — Clean Up Roles

Switch back to your admin user and clean up:

```sql
psql -h <postgresql-fqdn> -U <pgadmin> -d quiz

-- Revoke privileges first (required before dropping roles)
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM app_team;
REVOKE ALL ON ALL TABLES IN SCHEMA public FROM readonly;
REVOKE ALL ON ALL SEQUENCES IN SCHEMA public FROM app_team;
REVOKE USAGE ON SCHEMA public FROM app_team;
REVOKE USAGE ON SCHEMA public FROM readonly;

-- Re-grant CREATE on public schema (we revoked it in Step 7)
GRANT CREATE ON SCHEMA public TO PUBLIC;

-- Drop the schema we created
DROP SCHEMA IF EXISTS app;

-- Drop users first, then group roles
DROP ROLE IF EXISTS dev_user;
DROP ROLE IF EXISTS analyst_user;
DROP ROLE IF EXISTS contractor_user;
DROP ROLE IF EXISTS app_team;
DROP ROLE IF EXISTS readonly;

-- Remove the test data from Step 3
DELETE FROM questions WHERE question_id = 2;
```

---

### Summary

| Concept | What you learned |
|---|---|
| **Roles** | PostgreSQL has one concept: roles. `CREATE USER` = `CREATE ROLE ... LOGIN`. No separate users/groups. |
| **INHERIT vs NOINHERIT** | `INHERIT` = automatic privilege access. `NOINHERIT` = must explicitly `SET ROLE` to activate. |
| **Privilege codes** | `r`=SELECT, `a`=INSERT, `w`=UPDATE, `d`=DELETE, `D`=TRUNCATE, `x`=REFERENCES, `t`=TRIGGER |
| **GRANT / REVOKE** | Grant to group roles, not individual users. Revoke to remove specific privileges. |
| **Default privileges** | `ALTER DEFAULT PRIVILEGES` ensures future tables get the right grants automatically. |
| **Schema isolation** | Revoke `CREATE` on `public` from `PUBLIC`. Use dedicated schemas per application. |
| **Azure specifics** | Your admin is not a superuser — it's a member of `azure_pg_admin`. `azuresu` is Azure-managed. |

Try again as `Graham`:

```sh
SET ROLE TO graham;
DELETE FROM answers;
-- ERROR: permission denied for table answers
```

Grant `DELETE` privilege to `Graham`:

```sh
SET ROLE TO adminuser;
GRANT DELETE ON TABLE answers TO graham;
SET ROLE TO Graham;
DELETE FROM answers;
```

## Displaying Permissions and Roles

Show object permissions and role information:

```sh
\dp
\dg
```

## Role Inheritance

Without `INHERIT`, membership in another role only allows you to `SET ROLE` to that role; privileges are available only after switching.

## Revoking Privileges

Revoke `DELETE` privilege from `Eric`:

```sh
REVOKE DELETE ON TABLE answers FROM eric;
SET ROLE TO eric;
DELETE FROM answers;
```

**Note:**  
Eric can still delete records because of his membership in the `monty_python` role.
