---
sectionid: monitoring-easy
sectionclass: h2
parent-id: day2
title: Monitoring and Troubleshooting - Automated
published: false

---
There are several ways to monitor PostgreSQL Server. In this workshop we will study on both monitoring Azure Flexible PostgreSQL Server with opensource tools such as prometheus, grafana and also integrate opensource tools with Azure Monitor.

Sometimes kubernetes clusters can be used to as a monitoring solution. In this section we will install Azure Kubernetes Services (AKS) and install prometheus and grafana to monitor Azure PostgreSQL Server solutions from the easy way.

#### AKS Installation

Before the installation, have the resource group that we've created in the previous sections.
The resource group name was created using the following command unless you changed the name:

```sh
az group create -l Eastus -n PG-Workshop
```
Resource group name **PG-Workshop**


On the  CloudShell run the following

In this step we will deploy additional resources in the resource group that we created in the previous sections


```sh 
rm bicep.zip
```

Download the bicep templates for the workshop

```sh
wget https://storageaccounthol.z6.web.core.windows.net/scripts/bicep.zip
```
az deployment group create --resource-group PG-Workshop --template-file bicep/main.bicep
```

```bash
export SUBSCRIPTION_ID=$(az account show --query id --output tsv)
export RESOURCE_GROUP="<YourResourceGroup>" 

bash 02-aks-create.sh
```

```bash
kubectl get svc -n monitoring
```
#### Expected output
```
alertmanager-operated                             ClusterIP   None            <none>        9093/TCP,9094/TCP,9094/UDP   26d
prometheus-grafana                                ClusterIP   10.41.33.228    x.x.x.x       30080:30757/TCP              26d
prometheus-kube-prometheus-alertmanager           ClusterIP   10.41.23.115    <none>        9093/TCP                     26d
prometheus-kube-prometheus-operator               ClusterIP   10.41.55.172    <none>        443/TCP                      26d
prometheus-kube-prometheus-prometheus             ClusterIP   10.41.125.188   <none>        9090/TCP                     26d
prometheus-kube-state-metrics                     ClusterIP   10.41.102.217   <none>        8080/TCP                     26d
prometheus-operated                               ClusterIP   None            <none>        9090/TCP                     26d
prometheus-prometheus-node-exporter               ClusterIP   10.41.235.18    <none>        9100/TCP                     26d
```
Copy the IP address that you found on the line **prometheus-grafana** 4th column.

#### Grafana Dashboard
Open grafana from browser and search for postgresql dashboard for postgresql

![Grafana](../media/postgresql-monitoring-grafana2.png)



