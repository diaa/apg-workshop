---
sectionid: tls
sectionclass: h2
title: Security Management PostgreSQL
parent-id: businesscont-sec

---
### Installing pgAudit extension
Audit logging of database activities in Azure Database for PostgreSQL - Flexible server is available through the PostgreSQL Audit extension: pgAudit. pgAudit provides detailed session and/or object audit logging.
To enable pgAudit on Azure Database for PostgreSQL - Flexible Server please follow the steps below.

On the sidebar, select Server Parameters and type **extension** in the search field.

![pgAuditWhitelistExtensions](media/pgaudit01.png)


Hit **Save**

Once deployment is done go back to the Server Parameters and search for **shared_preload_libraries** and choose pgAudit.

![pgAuditWhitelistExtensions](media/pgaudit02.png)


Hit **Save** and then choose **Save and Restart**.

At this point you have the extension installed and you can go ahead and CREATE EXTENSION is the database.
Connect to your server using a client (like psql) and enable the pgAudit extension.

```sql
CREATE EXTENSION pgaudit;
```

Once you have enabled pgAudit, you can configure its parameters to start logging. To configure pgAudit you can follow below instructions. Using the Azure portal:
On the sidebar, select Server Parameters and search for **pgaudit**. Change the **pgaudit.log** from NONE to ALL:

![pgAuditWhitelistExtensions](media/pgaudit03.png)

From now on all the actions in your database will be traced.

### Viewing audit logs
The way you access the logs depends on which endpoint you choose. We have configured storage account and mounted it into the VM.

Open two cloud shell terminals, one will be needed to run some SQL commands (**psql**) and on the second we will observe log generation.
From psql run some queries:

```sql
CREATE TABLE a(id int);
INSERT into a SELECT generate_series(1,1000);
```

From the second terminal go to your mounted container location as described in the **Configure PgBadger** chapter, for instance:
```shell
cd mycontainer/resourceId\=/SUBSCRIPTIONS/<your subscription id>/RESOURCEGROUPS/PG-WORKSHOP/PROVIDERS/MICROSOFT.DBFORPOSTGRESQL/FLEXIBLESERVERS/PSQLFLEXIKHLYQLERJGTM/y\=2022/m\=05/d\=16/h\=09/m\=00/
```

and output appended data as the log file grows with the tail command:

```shell
tail -f 
```

After a minute or two (please expect a slight delay) you will see your commands being registered by pgAudit. You should see the following lines:

```shell
{ "properties": {"timestamp": "2022-05-23 08:23:59.526 UTC","processId": 9300,"errorLevel": "LOG","sqlerrcode": "00000","message": "2022-05-23 08:23:59 UTC 9300 5-1 db-pgbench,user-pgadmin,app-psql,client-192.168.0.4 LOG:  AUDIT: SESSION,1,1,DDL,CREATE TABLE,TABLE,public.a,CREATE TABLE a(id int);,<not logged>"}, "resourceId": "/SUBSCRIPTIONS/***/RESOURCEGROUPS/PG-WORKSHOP/PROVIDERS/MICROSOFT.DBFORPOSTGRESQL/FLEXIBLESERVERS/PSQLFLEXIKHLYQLERJGTM", "category": "PostgreSQLLogs", "operationName": "LogEvent"}
{ "properties": {"timestamp": "2022-05-23 08:24:00.511 UTC","processId": 9300,"errorLevel": "LOG","sqlerrcode": "00000","message": "2022-05-23 08:24:00 UTC 9300 9-1 db-pgbench,user-pgadmin,app-psql,client-192.168.0.4 LOG:  AUDIT: SESSION,2,1,WRITE,INSERT,,,\"INSERT into a SELECT generate_series(1,1000);\",<not logged>"}, "resourceId": "/SUBSCRIPTIONS/***/RESOURCEGROUPS/PG-WORKSHOP/PROVIDERS/MICROSOFT.DBFORPOSTGRESQL/FLEXIBLESERVERS/PSQLFLEXIKHLYQLERJGTM", "category": "PostgreSQLLogs", "operationName": "LogEvent"}
```


