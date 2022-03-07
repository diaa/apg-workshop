---
sectionid: tls
sectionclass: h2
title: Roles and Permissions
parent-id: basicadmin

---

Connect to the PostgreSQL instance
```sh 
[postgres@localhost ~]$ psql
psql (11.5)
Type "help" for help.

postgres=> 
```

Create new group
```sh 
postgres=> CREATE GROUP monty_python;
```

Create a new user Graham that belongs to monty_python group and doesn't inherit any privileges from the group. Allow the user to have maximum 2 active connection.

```sh 
postgres=> CREATE USER Graham CONNECTION LIMIT 2 IN ROLE monty_python NOINHERIT;
```

Create a new user Eric that belongs to monty_python group and inherits privileges from the group. Allow the user to have maximum 2 active connection.

```sh 
postgres=> CREATE USER Eric CONNECTION LIMIT 2 IN ROLE monty_python INHERIT;
```

Display all the roles available in the cluster

```sh 
postgres=> \dg
                                        List of roles
   Role name    |                         Attributes                         |   Member of
----------------+------------------------------------------------------------+----------------
 eric           | 2 connections                                              | {monty_python}
 graham         | No inheritance                                            +| {monty_python}
                | 2 connections                                              |
 monty_python   | Cannot login                                               | {}
 postgres       | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
```

Connect to the quiz database

```sh 
postgres=> \c quiz
```

Grant all privileges for all tables in schema public to group monty_python

```sh 
quiz=> GRANT ALL ON ALL TABLES IN SCHEMA public TO monty_python;
GRANT
```

In order to be able to switch to another role you need to grant this permission to the current user:
```sh
GRANT graham to adminuser;
GRANT graham to adminuser;
```

Switch to the Graham user

```sh 
quiz=> SET ROLE TO graham;
SET
```

Try to check the content of answers table as user Graham

```sh 
quiz=> TABLE answers;
ERROR:  permission denied for table answers
```

Change the user and try to query the table again

```sh 
quiz=> SET ROLE TO eric;
SET
quiz=> table answers;
 question_id | answer | is_correct
-------------+--------+------------
           1 | Au     | f
           1 | O      | t
           1 | Oxy    | f
           1 | Tl     | f
(4 rows)
```

Why user Graham doesn't have permission to view the content of answer table?

Changing permissions

Grant the SELECT privilege on table answers to user Graham.

```sh
quiz=> GRANT SELECT ON TABLE answers TO Graham;
WARNING:  no privileges were granted for "answers"
GRANT
```

Switch back to the superuser account and try again.

```sh
quiz=> SET ROLE TO adminuser;
SET
quiz=> GRANT SELECT ON TABLE answers TO Graham;
GRANT
```

Check if user Graham is able to query the table.

```sh
quiz=> SET ROLE TO graham;
SET
quiz=> TABLE answers;
 question_id | answer | is_correct
-------------+--------+------------
           1 | Au     | f
           1 | O      | t
           1 | Oxy    | f
           1 | Tl     | f
(4 rows)
```

Display all granted privileges.

```sh
quiz=> \dp
                                     Access privileges
 Schema |   Name    | Type  |       Access privileges       | Column privileges | Policies
--------+-----------+-------+-------------------------------+-------------------+----------
 public | answers   | table | postgres=arwdDxt/postgres    +|                   |
        |           |       | monty_python=arwdDxt/postgres+|                   |
        |           |       | graham=r/postgres             |                   |
 public | questions | table | postgres=arwdDxt/postgres    +|                   |
        |           |       | monty_python=arwdDxt/postgres |                   |
(2 rows)
```

Granting roles
As user Graham try to DELETE all records from table answers.

```sh
quiz=> DELETE FROM answers ;
ERROR:  permission denied for table answers
```

As adminuser copy all privileges from user eric to user graham.

```sh
quiz=> \c
You are now connected to database "quiz" as user "postgres".
quiz=> GRANT eric TO graham ;
GRANT ROLE
```

As user Graham try to DELETE all records from table answers.

```sh
quiz=> set role to graham;
SET
quiz=> DELETE FROM answers ;
ERROR:  permission denied for table answers
quiz=> SET ROLE TO adminuser;
quiz=> GRANT DELETE ON TABLE answers TO graham;
GRANT
quiz=> SET role TO Graham;
SET
quiz=> DELETE FROM answers ;
```

Display permissions granted to objects and information about roles.

```sh
quiz=> \dp
                                     Access privileges
 Schema |   Name    | Type  |       Access privileges       | Column privileges | Policies

--------+-----------+-------+-------------------------------+-------------------+---------
-
 public | answers   | table | postgres=arwdDxt/postgres    +|                   |
        |           |       | monty_python=arwdDxt/postgres+|                   |
        |           |       | graham=r/postgres            +|                   |
        |           |       | eric=d/postgres               |                   |
 public | questions | table | postgres=arwdDxt/postgres    +|                   |
        |           |       | monty_python=arwdDxt/postgres |                   |
(2 rows)

quiz=> \dg
                                           List of roles
   Role name    |                         Attributes                         |      Member of
----------------+------------------------------------------------------------+---------------------
 eric           | 2 connections                                              | {monty_python}
 graham         | No inheritance                                            +| {monty_python,eric}
                | 2 connections                                              |
 monty_python   | Cannot login                                               | {}
 postgres       | Superuser, Create role, Create DB, Replication, Bypass RLS | {}
```

Without INHERIT, membership in another role only grants the ability to SET ROLE to that other role; the privileges of the other role are only available after having done so.

Revoke DELETE privilege from eric.

```sh
quiz=> \c
You are now connected to database "quiz" as user "adminuser".
quiz=> REVOKE DELETE ON TABLE answers FROM eric;
REVOKE
quiz=> set role to eric;
SET
quiz=> delete from answers ;
DELETE 0
```

As you see user Eric is still able to perform DELETE operation because of his membership in role monty_python.