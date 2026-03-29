---
sectionid: prereq
sectionclass: h2
title: Prerequisites
parent-id: intro
---

Before you begin, make sure you have the items below ready. The exact requirements depend on which **deployment option** you choose — see the comparison table at the bottom of this page.

### Azure Subscription

You need an Azure subscription with **Contributor** access.

- Sign in at <https://portal.azure.com>
- Authenticate the Azure CLI: `az login`

{% comment %}
{% collapsible If the workshop uses an Azure Pass %}

1. Use the provided link (e.g. `https://azcheck.in/xxxxxxx`) to sign in with a GitHub account.
2. Copy the code and go to <https://www.microsoftazurepass.com/> → click **Start** to redeem the voucher.

For details: <https://www.microsoftazurepass.com/Home/HowTo?Length=5>

{% endcollapsible %}
{% endcomment %}

### Required Tools

| Tool | Download | Required for |
|---|---|---|
| **Azure CLI** | [Install Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) | All options |
| **SSH client** | Built into Windows 10+, macOS, Linux | Option 1 (Enterprise) |
| **psql** (PostgreSQL client) | Pre-installed on jumpbox VM (Option 1), or install locally via [PostgreSQL downloads](https://www.postgresql.org/download/) | All options |
| **VS Code** + PostgreSQL extension *(optional)* | [Download VS Code](https://code.visualstudio.com/) + install [PostgreSQL extension](https://marketplace.visualstudio.com/items?itemName=ms-ossdata.vscode-postgresql) | Option 2, Option 3 (or via SSH tunnel with Option 1) |

### Shell Environment

Your choice of shell depends on your deployment option:

- **Option 1 (Enterprise):** Use [Azure Cloud Shell](https://shell.azure.com) (Bash) to deploy. After deployment, you SSH into the **jumpbox Linux VM** which has `psql`, `pg_dump`, `pg_restore`, and other PostgreSQL 18 utilities pre-installed. All database work happens on the jumpbox.
- **Option 2 (Simple) / Option 3 (BYOS):** Use **any terminal** — Azure Cloud Shell, PowerShell, Bash, or Windows Terminal. You connect to PostgreSQL directly from your machine, so you need `psql` installed locally (or use the VS Code PostgreSQL extension or the Azure Portal Connect blade).

{% collapsible Setting up Azure Cloud Shell (first time only) %}

Head over to <https://shell.azure.com> and sign in.

Select **Bash** as your shell.

![Select Bash](media/cloudshell/0-bash.png)

Select **Show advanced settings**

![Select show advanced settings](media/cloudshell/1-mountstorage-advanced.png)

Set the **Storage account** and **File share** names to your resource group name (all lowercase, without special characters), then click **Create storage**.

![Azure Cloud Shell](media/cloudshell/2-storageaccount-fileshare.png)

You should now have access to the Azure Cloud Shell.

![Cloud Shell ready](media/cloudshell/3-cloudshell.png)

{% endcollapsible %}

---

### Deployment Options

The workshop provides **three** deployment options. Choose the one that best fits your scenario.

| | Option 1 — Enterprise | Option 2 — Simple | Option 3 — BYOS |
|---|---|---|---|
| **What's deployed** | Hub-spoke VNet, jumpbox VM, PG Flex (private access), private DNS | PG Flex (public access) + firewall rule | Nothing — you bring your own server |
| **How you connect** | SSH → jumpbox → `psql` (private network) | Direct from your machine (`psql`, VS Code, Portal) | Direct or via jumpbox |
| **SSH tunnel needed?** | Yes — for GUI tools (VS Code, pgAdmin) on your laptop | No | Depends on your setup |
| **Cloud Shell required?** | Recommended for deployment | No — any terminal works | No |
| **Best for** | Enterprise private networking scenarios | Quick start, developer-focused | Instructor-led or pre-provisioned |

---

#### Option 1 — Enterprise Deployment (Recommended)

Deploy the complete hub-and-spoke architecture using Bicep. This is the default path used throughout the workshop.

**What gets deployed:**

![Workshop Architecture — Full Deployment](media/architecture.png)

- **Hub VNet** with a jumpbox Linux VM (Rocky Linux 9, PostgreSQL 18 client pre-installed)
- **Spoke VNet** with Azure Database for PostgreSQL Flexible Server (private access via delegated subnet)
- VNet peering between hub and spoke
- Private DNS zone (`private.postgres.database.azure.com`)
- NSG with SSH access
- Storage account (for diagnostic logs)

**How to connect:**
1. **SSH** into the jumpbox VM from Cloud Shell or your local terminal
2. Use `psql` directly on the jumpbox to reach PostgreSQL over the private network
3. *(Optional)* Set up an **SSH tunnel** to use GUI tools (VS Code PostgreSQL extension, pgAdmin) from your laptop — see **Connecting to PostgreSQL** for details

**Best for:** Enterprise-like scenarios with private networking, DNS resolution, and a jump-box access pattern.

---

#### Option 2 — Simple Deployment (Public Access)

Deploy only a PostgreSQL Flexible Server with **public network access** and a firewall rule for your IP. No VNet, no jumpbox, no DNS.

<img src="media/diagram-simple-deployment.svg" alt="Simple Deployment — Public Access" style="max-width:680px;">

**What gets deployed:**
- Azure Database for PostgreSQL Flexible Server (public access, firewall whitelist)

**How to connect:** Directly from your machine using:
- `psql` (install locally or use Cloud Shell)
- [VS Code PostgreSQL extension](https://marketplace.visualstudio.com/items?itemName=ms-ossdata.vscode-postgresql)
- Azure Portal → PostgreSQL server → **Connect** blade

No SSH tunnel needed.

**Best for:** Quick start, simple labs, or when you already have a PostgreSQL client installed and want minimal setup.

> See the **Deploy with Bicep** section for step-by-step instructions.

---

#### Option 3 — Bring Your Own Server

If you already have an Azure Database for PostgreSQL Flexible Server (or are attending an instructor-led session where infrastructure is pre-provisioned), skip the deployment section entirely and proceed to **Connecting to PostgreSQL**.

<img src="media/diagram-byos-deployment.svg" alt="Bring Your Own Server — Jumpbox + Public Access" style="max-width:680px;">

**You will need:**
- PostgreSQL server FQDN
- Admin username and password
- Jumpbox VM IP address (if applicable) and SSH credentials
- Network access (either public endpoint with your IP whitelisted, or SSH to the jumpbox)

---

#### Tips for Azure Cloud Shell

- Use `code <filename>` to open the built-in text editor
- Drag and drop files to upload them
- Use `curl -o filename.ext https://url/filename.ext` to download files directly
