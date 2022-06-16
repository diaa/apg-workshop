# VARIABLES
LOCATION="eastus"
CLUSTER_NAME="aks-monitoring"
VNET_NAME="spoke-vnet"
VNET_SUBNET_NAME="subnet-03"
VNET_SUBNET_ADDRESS_SPACE="192.168.2.0/24"
LOGANALYTICS_NAME="log-"$CLUSTER_NAME
LOGANALYTICS_RETENTION_DAYS=30 #30-730
SYSTEM_NODE_VM_SIZE="Standard_D4ds_v4"
SYSTEM_NODE_OS_DISK_SIZE=100

# LOGIN TO THE SUBSCRIPTION
az login 
az account set --subscription $SUBSCRIPTION_ID

# REGISTER THE AZURE POLICY PROVIDER
az provider register --namespace Microsoft.PolicyInsights

# REGISTER PROVIDERS FOR CONTAINER INSIGHTS
az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.OperationalInsights


# CREATE THE RESOURCE GROUP
resourceGroupExists=$(az group exists --name "$RESOURCE_GROUP")
if [ "$resourceGroupExists" == "false" ]; then 
    echo "Creating resource group: "$RESOURCE_GROUP" in location: ""$LOCATION"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION"
fi

# CREATE THE VNET
vnetExists=$(az network vnet list -g "$RESOURCE_GROUP" --query "[?name=='$VNET_NAME'].name" -o tsv)
if [ "$vnetExists" != "$VNET_NAME" ]; then
    az network vnet create --resource-group $RESOURCE_GROUP --name $VNET_NAME \
    --address-prefix $VNET_ADDRESS_SPACE
fi

# CREATE SUBNET FOR THE CLUSTER 
subnetExists=$(az network vnet subnet list -g "$RESOURCE_GROUP" --vnet-name $VNET_NAME --query "[?name=='$VNET_SUBNET_NAME'].name" -o tsv)
if [ "$subnetExists" != "$VNET_SUBNET_NAME" ]; then
    VNET_SUBNET_ID=$(az network vnet subnet create --resource-group $RESOURCE_GROUP --name $VNET_SUBNET_NAME \
    --address-prefixes $VNET_SUBNET_ADDRESS_SPACE --vnet-name $VNET_NAME --query id -o tsv)
else
    VNET_SUBNET_ID=$(az network vnet subnet list -g "$RESOURCE_GROUP" --vnet-name $VNET_NAME --query "[?name=='$VNET_SUBNET_NAME'].id" -o tsv)
fi

logAnalyticsExists=$(az monitor log-analytics workspace list --resource-group $RESOURCE_GROUP --query "[?name=='$LOGANALYTICS_NAME'].name" -o tsv)
if [ "$logAnalyticsExists" != "$LOGANALYTICS_NAME" ]; then
    az monitor log-analytics workspace create --resource-group $RESOURCE_GROUP \
    --workspace-name $LOGANALYTICS_NAME --location $LOCATION --retention-time $LOGANALYTICS_RETENTION_DAYS
fi

# CREATE THE CLUSTER
aksClusterExists=$(az aks list -g $RESOURCE_GROUP --query "[?name=='$CLUSTER_NAME'].name" -o tsv)
if [ "$aksClusterExists" != "$CLUSTER_NAME" ]; then
    AKS_RESOURCE_ID=$(az aks create -g $RESOURCE_GROUP -n $CLUSTER_NAME \
    --generate-ssh-keys --location $LOCATION --node-vm-size $SYSTEM_NODE_VM_SIZE --nodepool-name systemtemp --node-count 2 \
    --node-osdisk-type Ephemeral --node-osdisk-size $SYSTEM_NODE_OS_DISK_SIZE --zones {1,2,3} \
    --network-policy calico --network-plugin azure --vnet-subnet-id $VNET_SUBNET_ID   \
    --enable-managed-identity   --enable-addons monitoring,azure-policy \
    --workspace-resource-id "/subscriptions/$SUBSCRIPTION_ID/resourcegroups/$RESOURCE_GROUP/providers/microsoft.operationalinsights/workspaces/$LOGANALYTICS_NAME" \
    --yes --query id -o tsv --only-show-errors )  
else
    AKS_RESOURCE_ID=$(az aks show -g $RESOURCE_GROUP -n $CLUSTER_NAME --query id -o tsv --only-show-errors)
fi

az aks get-credentials --resource-group $RESOURCE_GROUP --name aks-monitoring

#Except Azure Cloud Shell 
# Download and Install kubectl and helm
KERNEL_VERSION=$(uname -r)
SUB='azure'
if [[ "$KERNEL_VERSION" != *"$SUB"* ]]; then
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh
fi



helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
kubectl create ns monitoring
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --set grafana.service.type=LoadBalancer

#Extract PostgreSQL IP Address
export POSTGRESQL_IP=$(az network private-dns record-set a list -g $RESOURCE_GROUP --zone-name private.postgres.database.azure.com -o json | jq -r '.[].aRecords[0].ipv4Address')
rm -f *.yaml
wget https://raw.githubusercontent.com/msdevengers/kubernetes-essentials/master/10-monitoring/postgresql/01-postgresql-exporter.yaml
wget https://raw.githubusercontent.com/msdevengers/kubernetes-essentials/master/10-monitoring/postgresql/02-postgresql-exporter-svc.yaml
wget https://raw.githubusercontent.com/msdevengers/kubernetes-essentials/master/10-monitoring/postgresql/03-postgresql-exporter-svc-monitor.yaml
wget https://raw.githubusercontent.com/msdevengers/kubernetes-essentials/master/10-monitoring/postgresql/04-postgresql-dashboard.yaml


read -p 'PostgreSQL Username: ' POSTGRESQL_USER
read -p 'PostgreSQL Username: ' POSTGRESQL_PASSWORD
sed -i "s/#POSTGRESQL_SERVER_URI#/$POSTGRESQL_IP/g" 01-postgresql-exporter.yaml
sed -i "s/#USER_NAME#/$POSTGRESQL_USER/g" 01-postgresql-exporter.yaml
sed -i "s/#PASSWORD#/$POSTGRESQL_PASSWORD/g" 01-postgresql-exporter.yaml

kubectl apply -f 01-postgresql-exporter.yaml -n monitoring
kubectl apply -f 02-postgresql-exporter-svc.yaml -n monitoring
kubectl apply -f 03-postgresql-exporter-svc-monitor.yaml -n monitoring
kubectl apply -f 04-postgresql-dashboard.yaml -n monitoring




