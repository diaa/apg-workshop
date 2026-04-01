---
sectionid: deploy
sectionclass: h2
title: Deploy Azure Database for PostgreSQL with Bicep
parent-id: upandrunning
---

In this section you will deploy the workshop environment using [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep). Choose the option that matches your scenario.

### Prerequisites

- **Windows 10/11** with PowerShell, **macOS**, or **Linux** (or use [Azure Cloud Shell](https://shell.azure.com))
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) installed
- An Azure subscription with **Contributor** access

---

## Option 1 — Enterprise Deployment

Deploys the full hub-and-spoke architecture: jumpbox VM, private VNet, PostgreSQL Flexible Server with private access, and a private DNS zone.

#### Step 1 — Download the Bicep templates

Open [Azure Cloud Shell](https://shell.azure.com) (Bash), or a local terminal with Azure CLI installed, and download the templates:

<span class="lang-tag lang-tag-shell">shell</span>
```sh
curl -O https://pg.azure-workshops.cloud/scripts/bicep.zip
unzip bicep.zip
cd bicep
```

> **PowerShell?** Use `Invoke-WebRequest` instead:
> ```powershell
> Invoke-WebRequest -Uri https://pg.azure-workshops.cloud/scripts/bicep.zip -OutFile bicep.zip
> Expand-Archive bicep.zip -DestinationPath .
> cd bicep
> ```

#### Step 2 — Log in to Azure

<span class="lang-tag lang-tag-shell">shell</span>
```sh
az login
```

This opens a browser window. Sign in with your Azure account.

Verify you are on the correct subscription:

<span class="lang-tag lang-tag-shell">shell</span>
```sh
az account show --query "{name:name, id:id, state:state}" -o table
```

If the subscription shown is not the one you intend to use, list all available subscriptions and set the correct one:

<span class="lang-tag lang-tag-shell">shell</span>
```sh
az account list --query "[].{Name:name, ID:id, Default:isDefault}" -o table
az account set --subscription "<subscription-name-or-id>"
```

#### Step 3 — Create the resource group

<span class="lang-tag lang-tag-shell">shell</span>
```sh
az group create --name PG-Workshop --location uksouth
```

![Create PG workshop resource group](media/bicep/4-create-resource-group.png)

#### Step 4 — Deploy the Bicep template

<span class="lang-tag lang-tag-shell">shell</span>
```sh
az deployment group create --resource-group PG-Workshop --template-file main.bicep
```

You will be prompted for four values:

| Parameter | Description |
|---|---|
| `vmAdminUsername` | Username for the jumpbox VM (e.g. `workshopuser`) |
| `vmAdminPassword` | A strong password for the jumpbox VM |
| `postgreSqlAdministratorLogin` | Username for PostgreSQL — use your name, avoid `admin` or `root` |
| `postgreSqlAdministratorLoginPassword` | A strong password (min 8 chars, mix of upper/lower/number/special) |

![Bicep deployment](media/bicep/5-bicep-deploy.png)

The deployment takes approximately **10–15 minutes**. When it finishes, note the **outputs** — they contain the jumpbox public IP and the PostgreSQL FQDN.

![Deployment succeeded](media/resource-groups-sucess.png)

#### Step 5 — Verify resources and collect connection details

Go to **Resource Groups** in the Azure Portal and click on **PG-Workshop**. You should see:

- Jumpbox VM (`jumpbox`)
- PostgreSQL Flexible Server
- Hub and Spoke virtual networks
- Private DNS zone
- Network security group
- Storage account

Keep these values accessible — you will use them in every subsequent section:

| Value | Where to find it |
|---|---|
| **Jumpbox VM public IP** | Azure Portal → `PG-Workshop` → `jumpbox` VM → **Overview** → Public IP address |
| **PostgreSQL FQDN** | Azure Portal → `PG-Workshop` → PostgreSQL Flexible Server → **Overview** → Server name |
| **VM admin username** | The `vmAdminUsername` you entered in Step 4 |
| **PostgreSQL admin username** | The `postgreSqlAdministratorLogin` you entered in Step 4 |

#### Step 6 — SSH into the jumpbox and verify connectivity

<span class="lang-tag lang-tag-shell">shell</span>
```sh
ssh <vmAdminUsername>@<jumpbox-public-ip>
```

Use the password you provided in Step 4. Once connected, verify the PostgreSQL client is installed:

<span class="lang-tag lang-tag-shell">shell</span>
```sh
psql --version
```

You should see `psql (PostgreSQL) 18.x`. Then test connectivity to the database:

<span class="lang-tag lang-tag-shell">shell</span>
```sh
psql -h <postgresql-fqdn> -U <pgAdminUsername> -d postgres
```

Enter the PostgreSQL password when prompted. If you see the `postgres=>` prompt, the deployment is working correctly.

Check the PostgreSQL server version:

<span class="lang-tag lang-tag-sql">sql</span>
```sql
SELECT version();
```

You should see output containing `PostgreSQL 18.x`. To exit `psql`:

<span class="lang-tag lang-tag-sql">sql</span>
```sql
\q
```

> **Next:** Proceed to **[Connecting to PostgreSQL](#connecting-db)** for detailed connection methods, SSH tunnels, and VS Code setup.

---

## Option 2 — Simple Deployment (Public Network)

Deploys only a PostgreSQL Flexible Server with a **public endpoint** and a firewall rule for your IP. No jumpbox VM is created — you connect directly from your machine.

#### Step 1 — Download templates and navigate to the simple folder

If you haven't already downloaded the templates, do so now (see Option 1 — Step 1). Then navigate to the simple folder:

<span class="lang-tag lang-tag-shell">shell</span>
```sh
cd bicep/simple
```

#### Step 2 — Log in and create the resource group

Skip this step if you already logged in and created the resource group above.

<span class="lang-tag lang-tag-shell">shell</span>
```sh
az login
az group create --name PG-Workshop --location uksouth
```

#### Step 3 — Get your public IP

On **PowerShell** (Windows):
```powershell
(Invoke-WebRequest -Uri "https://ifconfig.me/ip").Content
```

On **Bash** (Linux/macOS/Cloud Shell):
<span class="lang-tag lang-tag-shell">shell</span>
```sh
curl -s ifconfig.me
```

Note the IP address returned.

#### Step 4 — Deploy

<span class="lang-tag lang-tag-shell">shell</span>
```sh
az deployment group create --resource-group PG-Workshop \
  --template-file main.bicep \
  --parameters clientIPAddress="<your-public-ip>"
```

You will be prompted for:

| Parameter | Description |
|---|---|
| `administratorLogin` | Username for PostgreSQL (e.g. `pgadmin`) |
| `administratorPassword` | A strong password (min 12 chars, mix of upper/lower/number/special) |

#### Step 5 — Connect from your local machine

The deployment output includes a ready-to-use `psqlCommand`. If you have `psql` installed locally:

<span class="lang-tag lang-tag-shell">shell</span>
```sh
psql "host=<server-fqdn> user=<administratorLogin> dbname=postgres sslmode=require"
```

If you do not have `psql` installed, you can connect from the Azure Portal: go to your PostgreSQL server → **Connect** blade.

#### Step 6 — Verify resources and collect connection details

Go to **Resource Groups** in the Azure Portal and click on **PG-Workshop**. You should see:

- PostgreSQL Flexible Server
- Firewall rule with your IP address

Keep these values accessible — you will use them in every subsequent section:

| Value | Where to find it |
|---|---|
| **PostgreSQL FQDN** | Azure Portal → `PG-Workshop` → PostgreSQL Flexible Server → **Overview** → Server name |
| **PostgreSQL admin username** | The `administratorLogin` you entered in Step 4 |

Once connected via `psql`, check the PostgreSQL server version:

<span class="lang-tag lang-tag-sql">sql</span>
```sql
SELECT version();
```

You should see output containing `PostgreSQL 18.x`. To exit `psql`:

<span class="lang-tag lang-tag-sql">sql</span>
```sql
\q
```

> **Next:** Proceed to **[Connecting to PostgreSQL](#connecting-db)** for detailed connection methods and VS Code setup.
