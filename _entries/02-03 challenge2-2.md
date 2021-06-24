---

sectionid: db
sectionclass: h2
parent-id: upandrunning
title: Multiversion Concurrency Control, MVCC
hide: false
published: true
---

This section describes the behavior of the PostgreSQL database system when two or more sessions try to access the same data at the same time. The goals in that situation are to allow efficient access for all sessions while maintaining strict data integrity. Every developer of database applications and DBA should be familiar with the topics covered in this chapter.


**Task Hints**
* We will use the portal to change the PostgreSQL parameters.
* Inspect the table size and see the impact of autovacuum.


### Tasks

#### Inspect and change server paramerters

You can list, show, and update configuration parameters for an Azure Database for PostgreSQL server through the Azure portal.

* Go to the Azure PostgreSQL resource

![Go PostgreSQL server parameteres](media/mvcc-postgres-server-params-2.png)

* Change Autovacuum server paramerter to off and **Save**

![Go PostgreSQL server parameteres](media/mvcc-postgres-autovacuum-off-3.png)


