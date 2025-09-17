---
sectionid: roles
sectionclass: h2
title: Roles and Permissions
parent-id: basicadmin
---

## Connecting to PostgreSQL

Connect to your PostgreSQL instance:

```sh
psql
```

Example output:

```
psql (13.5, server 13.6)
SSL connection (protocol: TLSv1.3, cipher: TLS_AES_256_GCM_SHA384, bits: 256, compression: off)
Type "help" for help.

postgres=>
```

## Creating Roles and Users

Create a new group:

```sh
CREATE GROUP monty_python;
```

Create a user `Graham` in the `monty_python` group, with a maximum of 2 active connections and **no** privilege inheritance:

```sh
CREATE USER Graham CONNECTION LIMIT 2 IN ROLE monty_python NOINHERIT;
```

Create a user `Eric` in the `monty_python` group, with a maximum of 2 active connections and **privilege inheritance**:

```sh
CREATE USER Eric CONNECTION LIMIT 2 IN ROLE monty_python INHERIT;
```

## Viewing Roles

Display all roles in the cluster:

```sh
\dg
```

Example output:

```
List of roles
 Role name   | Attributes | Member of
-------------+------------+-----------
eric         | 2 connections | {monty_python}
graham       | No inheritance, 2 connections | {monty_python}
monty_python | Cannot login | {}
postgres     | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
```

## Granting Privileges

Connect to the `quiz` database:

```sh
\c quiz
```

Grant all privileges on all tables in the `public` schema to the `monty_python` group:

```sh
GRANT ALL ON ALL TABLES IN SCHEMA public TO monty_python;
```

## Switching Roles

To switch to another role, grant the role to your admin user (replace *adminuser* with your actual admin username):

```sh
GRANT graham TO adminuser;
GRANT eric TO adminuser;
```

Switch to the `Graham` user:

```sh
SET ROLE TO graham;
```

Try to query the `answers` table as `Graham`:

```sh
TABLE answers;
-- ERROR: permission denied for table answers
```

Switch to the `Eric` user and try again:

```sh
SET ROLE TO eric;
TABLE answers;
-- Table content displayed
```

**Why can't Graham view the table?**  
Graham does not inherit privileges from the group.

## Changing Permissions

Grant `SELECT` privilege on the `answers` table to `Graham`:

```sh
GRANT SELECT ON TABLE answers TO Graham;
```

If you get a warning, switch back to the superuser and try again:

```sh
SET ROLE TO adminuser;
GRANT SELECT ON TABLE answers TO Graham;
```

Check if `Graham` can now query the table:

```sh
SET ROLE TO graham;
TABLE answers;
-- Table content displayed
```

## Displaying Privileges

Show all granted privileges:

```sh
\dp
```

Example output:

```
Access privileges
 Schema | Name     | Type  | Access privileges
--------+----------+-------+-------------------------------
public  | answers  | table | postgres=arwdDxt/postgres
                        monty_python=arwdDxt/postgres
                        graham=r/postgres
public  | questions| table | postgres=arwdDxt/postgres
                        monty_python=arwdDxt/postgres
```

## Granting Roles

As `Graham`, try to delete all records from `answers`:

```sh
DELETE FROM answers;
-- ERROR: permission denied for table answers
```

As `adminuser`, copy all privileges from `Eric` to `Graham`:

```sh
GRANT eric TO graham;
```

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
