---
sectionid: managing-db
sectionclass: h2
title: Managing PostgreSQL DB
parent-id: basicadmin

---


### Managing Compute and Storage
Navigate to **Compute + Storage**, you will be able to alter storage and compute. Also, navigate to change the backup retention.

You don't have to change the compute size as it might have additional cost for having a bigger instance. 

![Compute and Storage](media/compute_storage.png)


### Managing Server Parameters

As you don't have access to configuration files, you can change server parameters through the Azure Portal/APIs. All the changes made here provide default values for the **entire cluster**. 
Users can also make changes on the database level with [ALTER DATABASE](https://www.postgresql.org/docs/current/sql-alterdatabase.html) command, on the role level with [ALTER ROLE](https://www.postgresql.org/docs/current/sql-alterrole.html) command, or
on the session level with the [SET](https://www.postgresql.org/docs/current/sql-set.html) command.

![managing parameters](media/pg-parameters.png)

In the search box type **pgbouncer** and change the value to **TRUE**:

![managing parameters](media/pgbouncer.png)

**Save** the changes, and wait until the new deployment finish successfully:

![managing parameters](media/pgbouncer-success.png)

Once you see the success screen, go to the VM and try to access PostgreSQL through port 6432:

```sh
psql -p 6432
```
![managing parameters](media/pgbouncer-test.png)

### Apply Server Locks

Navigate to **Locks**:

![managing locks](media/pg-server-locks.png)

Click on **+Add**, add Lock name of your choice and lock type with **Delete**:

![managing locks](media/pg-delete-locks.png)

If you try to delete the server it should give the such below error:


![managing locks](media/pg-delete-lock-error.png)
