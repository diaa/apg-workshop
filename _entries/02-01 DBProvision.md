---
sectionid: deploy
sectionclass: h2
title: Deploy Azure Database for PostgreSQL with Azure Portal
parent-id: upandrunning
---

Azure Database for PostgreSQL is a fully-managed database as a service with built-in capabilities, such as high availability and intelligence. 

### Tasks

* Use [Bicep](https://docs.microsoft.com/en-us/azure/azure-resource-manager/bicep/overview?tabs=bicep) to deploy Azure Database for PostgreSQL - Flexible server.
* Use [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview) to connected to the created database instance.

#### Setup Database

**Deploy DB using Bicep**

Deploy Azure Database for PostgreSQL, which is managed service that you can use to run, manage, and scale in the cloud.


Based in the previous section, the cloudshell enviroment should be available, log to your cloudshell - bash. the next step is to install **bicep**  

```sh
az bicep install
```

![Install Bicep](media/bicep/1-bicep-install.png)

Download the bicep templates for the workshop

```sh
wget https://storageaccounthol.z6.web.core.windows.net/scripts/bicep.zip
```
![Download Bicep Templates](media/bicep/2-download-bicep-zip.png)

Uncompress the the downloaded file

```sh
unzip bicep
```
![Uncompress the downloaded file Templates](media/bicep/3-unzip-bicep.png)



Create a new [azure resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/manage-resource-groups-portal) to deploy the workshop resource in this resource group. Please take note of the resource group name in this below command it will be **PG-Workshop**.

```sh
az group create -l Eastus -n PG-Workshop
```
![Create PG workshop resource group](media/bicep/4-create-resource-group.png)

In this step we will deploy the bicep template to the resource group that we created in the previous step

```sh 
az deployment group create --resource-group Eastus --template-file bicep/main.bicep
```

You will be asked for 4 questions
- Admin username for the Jump-box (DNS)
- Admin password for the Jump-box 
- Admin username for the PostgreSQL database (use your name rather than admin/root)
- Admin password for the PostgreSQL database (Please use strong password)

![Create PG workshop resource group](media/bicep/5-bicep-deploy.png)


After the creation process finished you should be able to see the resource in the resource groups, go to Resource Groups

![Resource Groups](media/bicep/6-resource-groups.png)

Click on the resource group name that we created, PG-Workshop if you didn't change it.

![Resource Groups](media/bicep/7-resources-dns-pg.png)

Visit both DNS VM to get the public IP and the PostgreSQL Flexible Server to get the endpoint

![Resource Groups](media/bicep/8-dns-publicip.png)

![Resource Groups](media/bicep/9-pg-endpoint.png)



Now we move the next section to connect to the DB.
