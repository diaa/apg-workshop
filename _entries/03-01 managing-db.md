---
sectionid: managing-db
sectionclass: h2
title: Managing PostgreSQL DB
parent-id: basicadmin
---

### Managing Compute and Storage

Navigate to **Compute + Storage** to alter storage and compute settings. You can also change the backup retention period here.

> **Note:** Increasing the compute size may incur additional costs. Only adjust if necessary.

![Compute and Storage](media/compute_storage.png)

### Managing Server Parameters

Since you do not have access to configuration files, you can change server parameters through the Azure Portal or APIs. Changes made here apply default values to the **entire cluster**.

You can also make changes at different levels:
- **Database level:** Use the [ALTER DATABASE](https://www.postgresql.org/docs/current/sql-alterdatabase.html) command.
- **Role level:** Use the [ALTER ROLE](https://www.postgresql.org/docs/current/sql-alterrole.html) command.
- **Session level:** Use the [SET](https://www.postgresql.org/docs/current/sql-set.html) command.

![Managing parameters](media/pg-parameters.png)

To enable PgBouncer, type **pgbouncer** in the search box and set its value to **TRUE**:

![Managing parameters](media/pgbouncer.png)

Click **Save** and wait for the deployment to complete successfully:

![Managing parameters](media/pgbouncer-success.png)

Once you see the success screen, access PostgreSQL through port 6432 on your VM:

```sh
psql -p 6432
```
![Managing parameters](media/pgbouncer-test.png)

### Applying Server Locks

Navigate to **Locks**:

![Managing locks](media/pg-server-locks.png)

Click **+Add**, enter a lock name of your choice, and select the lock type **Delete**:

![Managing locks](media/pg-delete-locks.png)

If you attempt to delete the server, you should see an error similar to the following:

![Managing locks](media/pg-delete-lock-error.png)