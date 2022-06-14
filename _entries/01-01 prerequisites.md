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
#### Azure Cloud Shell

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


#### Tips for uploading and editing files in Azure Cloud Shell

- You can use `code <file you want to edit>` in Azure Cloud Shell to open the built-in text editor.
- You can upload files to the Azure Cloud Shell by dragging and dropping them
- You can also do a `curl -o filename.ext https://file-url/filename.ext` to download a file from the internet.
