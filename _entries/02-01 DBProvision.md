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

#### Step 1 — Download and extract the templates

Download the Bicep templates from the workshop page:

📦 [**bicep.zip**](https://pg.azure-workshops.cloud/scripts/bicep.zip)

Extract the zip file and open a terminal in the extracted folder:

```sh
cd C:\path\to\extracted\bicep
```

> **Cloud Shell?** Upload the zip or download it directly:
> ```sh
> curl -O https://pg.azure-workshops.cloud/scripts/bicep.zip && unzip bicep.zip
> cd bicep
> ```

#### Step 2 — Log in to Azure

```sh
az login
```

This opens a browser window. Sign in with your Azure account. If you have multiple subscriptions, set the correct one:

```sh
az account set --subscription "<subscription-name-or-id>"
```

#### Step 3 — Create the resource group

```sh
az group create --name PG-Workshop --location uksouth
```

![Create PG workshop resource group](media/bicep/4-create-resource-group.png)

#### Step 4 — Deploy the Bicep template

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

#### Step 5 — SSH into the jumpbox and verify connectivity

```sh
ssh <vmAdminUsername>@<jumpbox-public-ip>
```

Use the password you provided in Step 4. Once connected, verify the PostgreSQL client is installed:

```sh
psql --version
```

You should see `psql (PostgreSQL) 18.x`. Then test connectivity to the database:

```sh
psql -h <postgresql-fqdn> -U <pgAdminUsername> -d postgres
```

Enter the PostgreSQL password when prompted. If you see the `postgres=>` prompt, the deployment is working correctly.

---

## Option 2 — Simple Deployment (Public Network)

Deploys only a PostgreSQL Flexible Server with a **public endpoint** and a firewall rule for your IP. No jumpbox VM is created — you connect directly from your machine.

#### Step 1 — Navigate to the simple folder

From the extracted `bicep` folder:

```sh
cd C:\path\to\extracted\bicep\simple
```

#### Step 2 — Log in and create the resource group

Skip this step if you already logged in and created the resource group above.

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
```sh
curl -s ifconfig.me
```

Note the IP address returned.

#### Step 4 — Deploy

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

```sh
psql "host=<server-fqdn> user=<administratorLogin> dbname=postgres sslmode=require"
```

If you do not have `psql` installed, you can connect from the Azure Portal: go to your PostgreSQL server → **Connect** blade.

---

### Verify the Deployed Resources

Go to **Resource Groups** in the Azure Portal and click on **PG-Workshop**.

You should see the deployed resources (jumpbox VM, PostgreSQL Flexible Server, virtual networks, DNS zone for Option 1 — or just the PostgreSQL server for Option 2).

### Collect Connection Details

Keep these values accessible — you will use them in every subsequent section:

1. **Jumpbox VM public IP** *(Option 1 only)* — found on the jumpbox VM overview page
2. **PostgreSQL Flexible Server endpoint** (FQDN) — found on the PostgreSQL server overview page
