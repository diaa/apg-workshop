---
sectionid: cleanup
sectionclass: h1
title: Clean up
is-parent: yes
---

> ⚠️ **DISCLAIMER — Read before you delete anything.**
> The steps below will **permanently delete** all resources inside the `PG-Workshop` resource group, including the PostgreSQL Flexible Server, virtual machines, virtual networks, storage accounts, and any data they contain. This action **cannot be undone**.
> Only proceed if:
> - You have finished the workshop and no longer need the environment.
> - You have confirmed the resource group name matches **exactly** what you created (`PG-Workshop`).
> - You are operating in a **non-production subscription** used for this lab only.
> If you are unsure, **do not delete** — contact your subscription owner first.

---

### Step 1 — Confirm the Resource Group Before Deleting

List the resources inside the group first so you can visually confirm nothing critical is there:

```sh
az resource list --resource-group PG-Workshop --output table
```

You should see the resources you created: the PostgreSQL Flexible Server, jumpbox VM, virtual networks, and DNS zone. If you see anything unexpected, stop and investigate.

---

### Step 2 — Delete the Entire Resource Group

Deleting the resource group removes all resources inside it in a single operation:

**Azure Portal:**
1. Go to **Resource groups** in the Azure Portal.
2. Click on `PG-Workshop`.
3. Click **Delete resource group** at the top.
4. Type `PG-Workshop` in the confirmation box to confirm.
5. Click **Delete**.

**Azure CLI (from CloudShell or your terminal):**

```sh
az group delete --name PG-Workshop --yes --no-wait
```

The `--no-wait` flag returns control immediately; deletion continues in the background. You can check progress in the Azure Portal under **Activity log**.

---

### Step 3 — Verify Deletion

After a few minutes, confirm the resource group is gone:

```sh
az group show --name PG-Workshop
```

You should see: `ResourceGroupNotFound`. If resources still appear, wait and retry — large deployments can take 5–10 minutes to fully remove.

---

### Step 4 — Clean Up Local Files (Optional)

Remove any credentials or connection files you created on the jumpbox or locally:

```sh
# On the jumpbox (if still accessible before VM is deleted)
rm -f ~/.pg_azure ~/.pgpass
```

You can also read [manage Azure resources by using the Azure portal](https://docs.microsoft.com/en-us/azure/azure-resource-manager/manage-resources-portal) or [manage Azure resources by using Azure CLI](https://docs.microsoft.com/en-us/azure/azure-resource-manager/manage-resources-cli) for more details.
