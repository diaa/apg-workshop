---
sectionid: backupandresotre
sectionclass: h2
parent-id: businesscont-sec
title: Physical Backup and Point in Time Restore
hide: false
published: true
---

### Backup
While creating a server through the Azure portal, the **Compute tier** tab is where you select either **Burstable **, **"General purpose"** or **Memory Optimized** backups for your server. This window is also where you select the **Backup Retention Period** - how long (in number of days) you want the server backups stored for.


![Azure backup](media/backup-retention.png)



The backup retention period governs how far back in time a point-in-time restore can be retrieved, since it's based on backups available. Point-in-time restore is described further in the following section.

![Azure backup](media/backup-retention-2.png)

After changing the retention period make sure to click **Save**

When you see the deployment finished, it means that retention period has changed

![Azure backup](media/backup-retention-done.png)


### Point-in-time restore

Azure Database for PostgreSQL Flexible server allows you to restore the server back to a point-in-time and into to a new copy of the server. You can use this new server to recover your data, or have your client applications point to this new server.

For example, if a table was accidentally dropped at noon today, you could restore to the time just before noon and retrieve the missing table and data from that new copy of the server. Point-in-time restore is at the server level, not at the database level.

The following steps restore the sample server to a point-in-time:

* In the Azure portal, select your Azure Database for PostgreSQL Flexible server.

* In the toolbar of the server's Overview page, select Restore.

![Azure backup](media/azure_postgresql-restore.png)


![Azure backup](media/azure_postgresql-restore2.png)

The new server created by point-in-time restore has the same server admin login name and password that was valid for the existing server at the point-in-time chose. You can change the password from the new server's Overview page.

The new server created during a restore does not have the firewall rules or VNet service endpoints that existed on the original server. These rules need to be set up separately for this new server.