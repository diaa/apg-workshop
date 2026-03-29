---
sectionid: prereq
sectionclass: h2
title: Prerequisites
parent-id: intro
---

### Tools

You can use the Azure Cloud Shell accessible at <https://shell.azure.com> once you login with an Azure subscription. The Azure Cloud Shell has the Azure CLI pre-installed and configured to connect to your Azure subscription as well as `psql` and other Postgres utilities like `pg_dump`, `createdb` or `createuser` that will be used throughout the training, your access to the database might be through a jump-box in between cloudshell and PostgreSQL environment.

### Azure subscription

#### If the workshop will run on your Azure subscription

{% collapsible %}

Please use your username and password to login to <https://portal.azure.com>.

Also please authenticate your Azure CLI by running the command below on your machine and following the instructions.

```sh
az account show
az login
```

{% endcollapsible %}


#### If the workshop will run on [Azure Pass](https://www.microsoftazurepass.com/)
{% collapsible %}

* Login with a github account with the provided link: https://azcheck.in/xxxxxxx (Please use the provided one)
    ![Azure Cloud Shell](media/1-az-checkin.png)
* Follow the instructions, basically copy the code and go to: <https://www.microsoftazurepass.com/> to redeem the voucher and click on **Start>**.

    ![Azure Cloud Shell](media/2-azure-pass.png)


For more information follow : <https://www.microsoftazurepass.com/Home/HowTo?Length=5>

{% endcollapsible %}

### Azure Cloud Shell

You can use the Azure Cloud Shell accessible at <https://shell.azure.com> once you login with an Azure subscription.

Head over to <https://shell.azure.com> and sign in with your Azure Subscription details.

Select **Bash** as your shell.

![Select Bash](media/cloudshell/0-bash.png)

Select **Show advanced settings**

![Select show advanced settings](media/cloudshell/1-mountstorage-advanced.png)

Set the **Storage account** and **File share** names to your resource group name (all lowercase, without any special characters), then hit **Create storage**

![Azure Cloud Shell](media/cloudshell/2-storageaccount-fileshare.png)

You should now have access to the Azure Cloud Shell

![Set the storage account and fileshare names](media/cloudshell/3-cloudshell.png)

### Deployment Options

The workshop provides **three** deployment options. Choose the one that best fits your scenario:

---

#### Option 1 — Full Deployment (Recommended for the workshop)

Deploy the complete hub-and-spoke architecture using Bicep. This is the default path used throughout the workshop.

**What gets deployed:**

![Workshop Architecture — Full Deployment](media/architecture.png)

- **Hub VNet** with a jumpbox Linux VM (DNS forwarder, PostgreSQL 18 client pre-installed)
- **Spoke VNet** with Azure Database for PostgreSQL Flexible Server (private access via delegated subnet)
- VNet peering between hub and spoke
- Private DNS zone (`private.postgres.database.azure.com`)
- NSG with SSH access
- Storage account (for diagnostic logs)

**How to connect:** SSH into the jumpbox VM → use `psql` to reach PostgreSQL over the private network. See the **Connecting to PostgreSQL** section for SSH tunnel and VS Code options.

**Best for:** Enterprise-like scenarios with private networking, DNS resolution, and a jump-box access pattern.

---

#### Option 2 — Simple Deployment (Public Access)

Deploy only a PostgreSQL Flexible Server with **public network access** and a firewall rule for your IP. No VNet, no jumpbox, no DNS.

<img src="media/diagram-simple-deployment.svg" alt="Simple Deployment — Public Access" style="max-width:420px;">

**What gets deployed:**
- Azure Database for PostgreSQL Flexible Server (public access, firewall whitelist)
- Optional: read replica in a secondary zone

**How to connect:** Directly from your local machine using `psql`, VS Code PostgreSQL extension, or any PostgreSQL client — no SSH tunnel needed.

**Best for:** Quick start, simple labs, or when you already have a local PostgreSQL client installed and want minimal setup.

> See the **Deploy with Bicep** section for step-by-step instructions.

---

#### Option 3 — Bring Your Own Server

If you already have an Azure Database for PostgreSQL Flexible Server (or are attending an instructor-led session where infrastructure is pre-provisioned), skip the deployment section entirely and proceed to **Connecting to PostgreSQL**.

In this option your environment includes a **jumpbox VM** with the PostgreSQL 18 client (`psql`) pre-installed, and a **publicly accessible PostgreSQL Flexible Server** with your IP whitelisted in the firewall. You can connect either way — through the VM or directly from your laptop.

<img src="media/diagram-byos-deployment.svg" alt="Bring Your Own Server — Jumpbox + Public Access" style="max-width:420px;">

You will need:
- PostgreSQL server FQDN
- Admin username and password
- Jumpbox VM IP address (if applicable) and SSH credentials
- Network access (either public endpoint with your IP whitelisted, or SSH to the jumpbox)

---

#### Tips for uploading and editing files in Azure Cloud Shell

- You can use `code <file you want to edit>` in Azure Cloud Shell to open the built-in text editor.
- You can upload files to the Azure Cloud Shell by dragging and dropping them.
- You can also do a `curl -o filename.ext https://file-url/filename.ext` to download a file from the internet.
