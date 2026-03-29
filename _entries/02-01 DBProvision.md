---
sectionid: deploy
sectionclass: h2
title: Deploy Azure Database for PostgreSQL with Bicep
parent-id: upandrunning
---

Azure Database for PostgreSQL Flexible Server is a fully-managed database as a service with built-in capabilities such as high availability, intelligent performance, and enterprise security.

In this section you will use [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep) and Azure Cloud Shell to deploy the workshop environment.

### Step 1 — Install Bicep and Create a Resource Group

Log in to your Azure Cloud Shell (Bash). Install the Bicep CLI:

```sh
az bicep install
```

![Install Bicep](media/bicep/1-bicep-install.png)

Create a new [Azure resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal). The name **PG-Workshop** is used throughout the workshop — change it if needed, but be consistent.

```sh
az group create -l Eastus -n PG-Workshop
```
![Create PG workshop resource group](media/bicep/4-create-resource-group.png)

### Step 2 — Download the Bicep Templates

Clone the workshop repository to get the Bicep templates:

```sh
git clone https://github.com/Azure/apg-workshop.git
cd apg-workshop
```

> If `git` is not available in your environment, download the templates directly:
> ```sh
> wget https://pg.azure-workshops.cloud/scripts/bicep.zip && unzip bicep.zip
> ```

### Step 3 — Deploy the Environment

Deploy the Bicep template to the resource group. You will be prompted for four values:

- Admin username for the jumpbox VM
- Admin password for the jumpbox VM
- Admin username for the PostgreSQL database (use your name rather than admin/root)
- Admin password for the PostgreSQL database (use a strong password)

```sh 
az deployment group create --resource-group PG-Workshop --template-file bicep/main.bicep
```

![Bicep deployment](media/bicep/5-bicep-deploy.png)

The deployment takes several minutes. When it finishes, the output will show **succeeded** in the last few lines.

![Deployment succeeded](media/resource-groups-sucess.png)

### Step 4 — Verify the Deployed Resources

Go to **Resource Groups** in the Azure Portal and click on **PG-Workshop**.

![Resource Groups](media/bicep/6-resource-groups.png)

You should see the jumpbox VM, PostgreSQL Flexible Server, virtual networks, DNS zone, and storage account.

![Resource Groups](media/bicep/7-resources-dns-pg.png)

### Step 5 — Collect Connection Details

You need two values for the rest of the workshop:

1. **Jumpbox VM public IP** — found on the jumpbox VM overview page
2. **PostgreSQL Flexible Server endpoint** (FQDN) — found on the PostgreSQL server overview page

![Jumpbox public IP](media/bicep/8-dns-publicip.png)

![PostgreSQL endpoint](media/bicep/9-pg-endpoint.png)

Keep both values accessible — you will use them in every subsequent section.
