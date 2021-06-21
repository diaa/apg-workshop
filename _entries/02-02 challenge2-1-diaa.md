---

sectionid: db
sectionclass: h2
parent-id: upandrunning
title: connect and create

---

This section describes the behavior of the PostgreSQL database system when two or more sessions try to access the same data at the same time. The goals in that situation are to allow efficient access for all sessions while maintaining strict data integrity. Every developer of database applications and DBA should be familiar with the topics covered in this chapter.


**Task Hints**
* Use [Azure Resource Manager](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/overview) to deploy Azure Database for PostgreSQL - single server.
* Use [Azure Cloud Shell](https://docs.microsoft.com/en-us/azure/cloud-shell/overview) to connected to the created database instance.


### Tasks

#### Setup Database

Azure Database for PostgreSQL is a managed service that you use to run, manage, and scale highly available PostgreSQL databases in the cloud. In this quickstart, you use an Azure Resource Manager template (ARM template) to create an Azure Database for PostgreSQL - single server in the Azure portal, PowerShell, or Azure CLI.

**Deploy DB using ARM**
{% collapsible %}

* If your environment meets the prerequisites and you're familiar with using ARM templates, [follow this link and a template will open in the Azure portal](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2Fquickstarts%2Fmicrosoft.dbforpostgresql%2Fmanaged-postgresql-with-vnet%2Fazuredeploy.json).

![Create Azure DB](media/create-azure-db-pg.png)

* Continue to the next page by clicking **Review + create**
* The review page should look like the following:

![Review Azure DB](media/review-pg-create.png)


{% endcollapsible %}



#### Connect to the database using Azure Cloud Shell (Bash)

Azure Cloud Shell is an interactive, authenticated, browser-accessible shell for managing Azure resources. It provides the flexibility of choosing the shell experience that best suits the way you work, either Bash or PowerShell.

If you have Azure Cloud Shell (Bash) configured you can skip the

A standard repository of Helm charts is available for many different software packages, and it has one for [MongoDB](https://github.com/helm/charts/tree/master/stable/mongodb) that is easily replicated and horizontally scalable. 

**Task Hints**
* When installing a chart, Helm uses a concept called a "release" and each release needs a name. We recommend you name your release `orders-mongo` to make it easier to follow later steps in this workshop
* When deploying a chart you provide parameters with the `--set` switch and a comma separated list of `key=value` pairs. There are MANY parameters you can provide to the MongoDB chart, but pay attention to the `mongodbUsername`, `mongodbPassword` and `mongodbDatabase` parameters 

> **Note** The application expects a database named `akschallenge`. Using a different database name will cause the application to fail!

{% collapsible %}
The recommended way to deploy MongoDB would be to use a Helm Chart. 

```sh
helm install orders-mongo stable/mongodb --set mongodbUsername=orders-user,mongodbPassword=orders-password,mongodbDatabase=akschallenge
```

> **Hint** Using this command, the Helm Chart will expose the MongoDB instance as a Kubernetes Service accessible at ``orders-mongo-mongodb.default.svc.cluster.local``

Remember to use the username and password from the command above when creating the Kubernetes secrets in the next step.

{% endcollapsible %}

#### Create a Kubernetes secret to hold the MongoDB details

In the previous step, you installed MongoDB using Helm, with a specified username, password and a hostname where the database is accessible. You'll now create a Kubernetes secret called `mongodb` to hold those details, so that you don't need to hard-code them in the YAML files.

**Task Hints**
* A Kubernetes secret can hold several items, indexed by key. The name of the secret isn't critical, but you'll need three keys to store your secret data:
  * `mongoHost`
  * `mongoUser`
  * `mongoPassword`
* The values for the username & password will be those you used with the `helm install` command when deploying MongoDB.
* Run `kubectl create secret generic -h` for help on how to create a secret, clue: use the `--from-literal` parameter to allow you to provide the secret values directly on the command in plain text.
* The value of `mongoHost`, will be dependent on the name of the MongoDB service. The service was created by the Helm chart and will start with the release name you gave. Run `kubectl get service` and you should see it listed, e.g. `orders-mongo-mongodb`
* All services in Kubernetes get DNS names, this is assigned automatically by Kubernetes, there's no need for you to configure it. You can use the short form which is simply the service name, e.g. `orders-mongo-mongodb` or better to use the "fully qualified" form `orders-mongo-mongodb.default.svc.cluster.local`
  
{% collapsible %}

```sh
kubectl create secret generic mongodb --from-literal=mongoHost="orders-mongo-mongodb.default.svc.cluster.local" --from-literal=mongoUser="orders-user" --from-literal=mongoPassword="orders-password"
```

You'll need to reference this secret when configuring the Order Capture application later on.

{% endcollapsible %}

> **Resources**
> * <https://helm.sh/docs/intro/using_helm/>
> * <https://github.com/helm/charts/tree/master/stable/mongodb>
> * <https://kubernetes.io/docs/concepts/configuration/secret/>

### Architecture Diagram
Here's a high level diagram of the components you will have deployed when you've finished this section (click the picture to enlarge)

<a href="media/architecture/mongo.png" target="_blank"><img src="media/architecture/mongo.png" style="width:500px"></a>

* The **pod** holds the containers that run MongoDB
* The **deployment** manages the pod
* The **service** exposes the pod to the Internet using a public IP address and a specified port
