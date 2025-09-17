---
sectionid: backupandresotre
sectionclass: h2
parent-id: businesscont-sec
title: Physical Backup and Point in Time Restore
hide: false
published: true
---

### Backup

When creating a server through the Azure portal, use the **Compute tier** tab to select either **Burstable**, **General Purpose**, or **Memory Optimized** for your server. This window is also where you set the **Backup Retention Period**—the number of days backups are stored.

![Azure backup](media/backup-retention.png)

The backup retention period determines how far back in time you can restore using point-in-time restore, as it depends on the available backups.

![Azure backup](media/backup-retention-2.png)

After changing the retention period, make sure to click **Save**.

When the deployment is finished, the retention period has been updated.

![Azure backup](media/backup-retention-done.png)

---

### Point-in-Time Restore

Azure Database for PostgreSQL Flexible Server allows you to restore your server to a specific point in time, creating a new copy of the server. You can use this new server to recover data or redirect your client applications.

For example, if a table was accidentally dropped at noon, you can restore to just before noon and retrieve the missing table and data from the new server copy. Note: Point-in-time restore operates at the server level, not the database level.

**To restore to a point in time:**

1. In the Azure portal, select your Azure Database for PostgreSQL Flexible Server.
2. On the server's Overview page, click **Restore** in the toolbar.

![Azure backup](media/azure_postgresql-restore.png)
![Azure backup](media/azure_postgresql-restore2.png)

The new server created by point-in-time restore will have the same server admin login name and password as the original server at the selected restore time. You can change the password from the new server's Overview page.

**Important:**  
The new server created during a restore does **not** have the firewall rules or VNet service endpoints from the original server. You must set up these rules separately for the new server.