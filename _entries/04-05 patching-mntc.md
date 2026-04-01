---
sectionid: patching-mntc
sectionclass: h2
title: Patching and maintenance windows
parent-id: businesscont-sec

---

### Scheduled maintenance in Azure Database for PostgreSQL – Flexible server

Azure Database for PostgreSQL - Flexible server performs periodic maintenance to keep your managed database secure, stable, and up-to-date. During maintenance, the server gets new features, updates, and patches.

#### What happens during maintenance?

| Aspect | Details |
|---|---|
| **What’s patched** | OS-level security patches, PostgreSQL minor version upgrades, Azure platform updates |
| **Frequency** | Approximately once per month, though critical security patches may arrive sooner |
| **Downtime** | Typically **a few seconds to a couple of minutes** — the server restarts after patching. If HA is enabled, failover minimises the window further. |
| **Notification** | Azure sends a **5-day advance notification** to subscription admins before scheduled maintenance |
| **Custom schedule** | You can choose your preferred **day of the week** and **start hour** (30-minute window), or let Azure decide (system-managed) |

> **Best practice:** Set the custom maintenance window to a **low-traffic period** (e.g., Saturday 02:00 UTC) so restarts have minimal impact.

#### Configuring a custom maintenance window

#### Configuring a custom maintenance window

Navigate to the maintenance tab in Azure portal for your flexible server.

![Maintenance configuration](media/maintenence/Configure.png)

Select a custom schedule from the options available in the drop down.

![Custom schedule selection](media/maintenence/Configure2.png)

Click on save schedule to complete the configuration.

![Maintenance schedule saved](media/maintenence/Completed.png)

#### Using the Azure CLI

You can also configure the maintenance window via CLI:

<span class="lang-tag lang-tag-shell">shell</span>
```sh
az postgres flexible-server update \
  --resource-group PG-Workshop \
  --name <server-name> \
  --maintenance-window "Sat:02:00"
```