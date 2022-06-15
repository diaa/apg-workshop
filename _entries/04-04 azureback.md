---
sectionid: azurebackup
sectionclass: h2
title: Azure Backup
parent-id: businesscont-sec

---

### Backup and restore in Azure Database for PostgreSQL - Flexible Server

Azure Database for PostgreSQL - Flexible Server automatically performs regular backups of your server. You can then do a point-in-time recovery (PITR) as seen in the previous section, within a retention period that you specify.

Tasks:

* Manual backup: Backing up database

You can manually take a backup by using the PostgreSQL tool pg_dump and pg_restore. 

SSH into to the jumpbox vm. 

```sh
ssh username@<jumpbox-ip
```

Execute below command to take a back up of the database.

```sh 
pg_dump -Fc -v --host=<host> --username=<name> --dbname=<database name> -f <database>.dump
```

* Restore manual dabase backup using pg_restore

```sh 
pg_restore -v --no-owner --host=<server name> --port=<port> --username=<user-name> --dbname=<target database name> <database>.dump
```

You can read how to optimize the migration process [here](https://docs.microsoft.com/en-us/azure/postgresql/howto-migrate-using-dump-and-restore#for-the-restore)