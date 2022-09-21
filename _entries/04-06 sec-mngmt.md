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

From the second terminal configure a mounted container location so you can have the storage account mounted on your filesystem:

### Mounting Storage Account to VM
In this section you will mount Storage Account to your dns VM to be able to easier manipulate on log files.

First let's download and install necessary packages. Feel free to simply copy and paste the following commands:

```sh
sudo rpm -Uvh https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
sudo dnf -y install blobfuse
sudo mkdir /mnt/ramdisk
sudo mount -t tmpfs -o size=16g tmpfs /mnt/ramdisk
sudo mkdir /mnt/ramdisk/blobfusetmp
sudo chown <your VM admin> /mnt/ramdisk/blobfusetmp
```

#### Authorize access to your storage account
You can authorize access to your storage account by using the account access key, a shared access signature, a managed identity, or a service principal. Authorization information can be provided on the command line, in a config file, or in environment variables. 

For this exercise we will authorize with the account access keys and storing them in a config file. The config file should have the following format:

```shell
accountName myaccount
accountKey storageaccesskey
containerName insights-logs-postgresqllogs
```

Please prepare the following file in editor of your choice. Values for the accountName and accountKey you will find in the Azure Portal. 
Please navigate to your storage account in the portal and then choose Access keys page:

![Server Parameters](media/sa-accesskeys.png)

Copy accountName and accountKey and paste it to the file. Copy the content of your file and paste it to the ***fuse_connection.cfg*** file in your home directory, then mount your storage account container onto the directory in your VM: 

```shell
vi fuse_connection.cfg
chmod 600 fuse_connection.cfg
mkdir ~/mycontainer
sudo blobfuse ~/mycontainer --tmp-path=/mnt/resource/blobfusetmp  --config-file=/home/<your VM admin>/fuse_connection.cfg -o attr_timeout=240 -o entry_timeout=240 -o negative_timeout=120

sudo -i
cd /home/<your VM admin>/mycontainer/
ls # check if you see mounted container
# Please use tab key for directory autocompletion; do not copy and paste!
cd resourceId\=/SUBSCRIPTIONS/<your subscription id>/RESOURCEGROUPS/PG-WORKSHOP/PROVIDERS/MICROSOFT.DBFORPOSTGRESQL/FLEXIBLESERVERS/PSQLFLEXIKHLYQLERJGTM/y\=2022/m\=06/d\=16/h\=09/m\=00/
ls
less
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


