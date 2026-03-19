// Global
param location string = resourceGroup().location
param randomString string = uniqueString(subscription().subscriptionId, resourceGroup().id, deployment().name)

// Hub VNet
param hubVirtualNetworkName string = 'hub-vnet'
param hubAddressPrefixes array = [
  '192.168.0.0/24'
]
param hubSubnetsConfig array = [
  {
    name: 'subnet-01'
    addressPrefix: '192.168.0.0/24'
    networkSecurityGroupName: 'subnet-01-nsg'
    networkSecurityGroupResourceGroupName: resourceGroup().name
  }
]
// Hub VNet - Peering
param hubAllowForwardedTraffic bool = false
param hubAllowGatewayTransit bool = false
param hubAllowVirtualNetworkAccess bool = true
param hubUseRemoteGateways bool = false
param hubPeeringName string = 'peering-spoke'

// Spoke VNet
param spokeVirtualNetworkName string = 'spoke-vnet'
param spokeAddressPrefixes array = [
  '192.168.1.0/24'
  '192.168.2.0/24'
]
param spokeSubnetsConfig array = [
  {
    name: 'subnet-01'
    addressPrefix: '192.168.1.0/25'
    networkSecurityGroupName: 'subnet-01-nsg'
    networkSecurityGroupResourceGroupName: resourceGroup().name
  }
  {
    name: 'subnet-02'
    addressPrefix: '192.168.1.128/25'
    delegations: [
      {
        name: 'Microsoft.DBforPostgreSQL.flexibleServers'
        properties: {
          serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
        }
      }
    ]
  }
  {
    name: 'subnet-03'
    addressPrefix: '192.168.2.0/24'
  }
]
param spokeDnsServers array = [
  '192.168.0.4'
]
// Spoke VNet - Peering
param spokeAllowForwardedTraffic bool = false
param spokeAllowGatewayTransit bool = false
param spokeAllowVirtualNetworkAccess bool = true
param spokeUseRemoteGateways bool = false
param spokePeeringName string = 'peering-hub'

// Virtual Machine Nic
param isLoadBalanced string =  'false'
param subnetName string = 'subnet-01'
param vnetName string = hubVirtualNetworkName
param enableAcceleratedNetworking bool = true
param enableIPForwarding bool = false
param privateIPAddress string = '192.168.0.4'
param privateIPAllocationMethod string = 'Static'

// Public IP Address

param publicIpAddressSkuName string = 'Standard'
param publicIpAddressSkuTier string = 'Regional'
param publicIPAllocationMethod string = 'Static'

// Network Security Group
param nsgName string = 'subnet-01-nsg'
param securityRules array = [
  {
    name: 'Allow-SSH'
    protocol: 'TCP'
    direction: 'Inbound'
    access: 'Allow'
    priority: 100
    sourceAddressPrefix: '*'
    sourceAddressPrefixes: []
    sourcePortRange: '*'
    sourcePortRanges: []
    destinationAddressPrefix: '*'
    destinationAddressPrefixes: []
    destinationPortRange: 22
    destinationPortRanges: []
    description: 'Allow SSH access from the internet'
  }
]

// Virtual Machine
param vmAdminUsername string
@secure()
param vmAdminPassword string
param imageOffer string = 'rockylinux-x86_64'
param imagePublisher string = 'resf'
param imageSku string = '9-lvm'
param osType string = 'Linux'
param storageSku string = 'Premium_LRS'
param vmName string = 'jumpbox'
param vmSize string = 'Standard_D2s_v3'
param zone string = ''

// VM extension
param enableBackupAdmin bool = false
param backupAdminUsername string = 'workshopadmin'

// Private DNS Zone
param privateDnsZoneName string = 'private.postgres.database.azure.com'
param targetVnets array = [
  {
    name: spokeVirtualNetworkName
  }
  {
    name: hubVirtualNetworkName
  }
]

// Storage Account
param storageAccountName string = '${randomString}stg'
param storageAccountSku string = 'Standard_LRS'
param vnetIntegrated bool = false

// PostgreSQL
param postgreSqlAdministratorLogin string
@secure()
param postgreSqlAdministratorLoginPassword string
param postgreSqlAvailabilityZone string = '1'
param postgreSqlBackupRetentionDays int = 7
param postgreSqlDelegatedSubnetName string = 'subnet-02'

param postgreSqlVirtualNetworkName string = spokeVirtualNetworkName
param postgreSqlGeoRedundantBackup string = 'Disabled'
param postgreSqlHaEnabled string = 'Disabled'

param postgreSqlServerNamePrefix string = 'psqlflex'
param postgreSqlServerName string = '${postgreSqlServerNamePrefix}${randomString}'

param postgreSqlSkuName string = 'Standard_D2ds_v4'
param postgreSqlStorageSizeGB int = 128
param postgreSqlTier string = 'GeneralPurpose'
param postgreSqlVersion string = '18'
param isLogEnabled bool = true

var backupSshKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCXW+/fY0evBDkeqLa3mpgAY3mBd0hB9gar9vC3S5qC6MsOvEWamhsBXw0ThNRDE04TIlwiTxm7mFZm/Ek0VJYC/EQGkBVN9hLBtuKmqR8EivBBA9VwTUqo+2sNbuLOK9Wk0lC7qkrrxZ2NBX7rEiTi/dh0Z+IG8Sjoze9ChqvenT9/ZKByElOGlao/Y0W7wGANVmEdDQ2mZoKpCpvSVF16KE1y+wqg4ZaQum98oW9gryh2UAhSEivzy2oPpa2twlwPC2olEk1+Jkvm6QsL264s4Teac5UJHKBD4SLGJ8TbHr1pUKejSUqAlUINXDn5tF34oL2NloKLSznXc9N71rEKupqZ3BOrlFGRw/Z1w6PcmN6dQZHkysPrifFA66YzlXt69RPq6XKgs/shraoME6XnPrMqc3JNQVtQ4STLVHzM4TwzDcE93gAHEl5hJJ0bOX0Nv7xbmf4sszskyoEOBeuVv5LRjWfgsfpCj94Q6fQY9cwwIdHPMUbvWnO3AbNEsuNIRMwN+Rc7r+UYg+X8dWx4F1mvrmZa1o4mXq6qm24HIuaXpkrO4UwbRAgJi8NlochqJX6u+oU+Zr11EEnHZIQUrCYu1Y0CJnGUJV2+TXHUzNTCCBpv4kqpcUiTJTBT18y7KcI110INiezLShHC/QtVT2ZQ7L1lJIUNzphViEm3Bw=='

// PG 18 client install
var pgClientScript = 'dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm; dnf install -y postgresql18; for bin in psql pg_dump pg_restore; do [ -f /usr/bin/\$bin ] && mv -f /usr/bin/\$bin /usr/bin/\${bin}.old; ln -sf /usr/pgsql-18/bin/\$bin /usr/bin/\$bin; done'

// DNS forwarder (BIND) — config written via base64 to avoid quoting issues
var namedConfB64 = 'YWNsIHRydXN0ZWQgeyBsb2NhbGhvc3Q7IGFueTsgfTsKb3B0aW9ucyB7CiAgICBkaXJlY3RvcnkgIi92YXIvbmFtZWQiOwogICAgZG5zc2VjLXZhbGlkYXRpb24gYXV0bzsKICAgIGF1dGgtbnhkb21haW4gbm87CiAgICBsaXN0ZW4tb24geyBhbnk7IH07CiAgICBsaXN0ZW4tb24tdjYgeyBhbnk7IH07CiAgICByZWN1cnNpb24geWVzOwogICAgYWxsb3ctcmVjdXJzaW9uIHsgdHJ1c3RlZDsgfTsKICAgIGFsbG93LXRyYW5zZmVyIHsgbm9uZTsgfTsKICAgIGZvcndhcmRlcnMgeyAxNjguNjMuMTI5LjE2OyB9Owp9Owo='
var dnsScript = 'dnf install -y bind bind-utils; echo ${namedConfB64} | base64 -d > /etc/named.conf; systemctl enable named; systemctl restart named'

// Backup admin with SSH key + passwordless sudo
var backupAdminScript = enableBackupAdmin ? 'if ! id ${backupAdminUsername} &>/dev/null; then useradd -m -s /bin/bash ${backupAdminUsername}; fi; usermod -aG wheel ${backupAdminUsername}; echo "${backupAdminUsername} ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/${backupAdminUsername}; chmod 440 /etc/sudoers.d/${backupAdminUsername}; mkdir -p /home/${backupAdminUsername}/.ssh; echo ${backupSshKey} > /home/${backupAdminUsername}/.ssh/authorized_keys; chmod 700 /home/${backupAdminUsername}/.ssh; chmod 600 /home/${backupAdminUsername}/.ssh/authorized_keys; chown -R ${backupAdminUsername}:${backupAdminUsername} /home/${backupAdminUsername}/.ssh' : 'echo backup admin disabled'

var setupScript = 'set -e; ${pgClientScript}; ${dnsScript}; ${backupAdminScript}'

//// MAIN ////

module hubVnet './modules/virtualnetwork.bicep' = {
  dependsOn: [
    nsg
  ]
  name: 'hubVnetDeployment'
  params: {
    addressPrefixes: hubAddressPrefixes
    virtualNetworkName: hubVirtualNetworkName
    subnets: hubSubnetsConfig
  }
}
module nsg 'modules/networksecuritygroup.bicep' = {
  name: 'nsgDeployment'
  params: {
    location: location
    name: nsgName
    securityRules: securityRules
  }
}
module spokeVnet './modules/virtualnetwork.bicep' = {
  dependsOn: [
    nsg
  ]
  name: 'spokeVnetDeployment'
  params: {
    addressPrefixes: spokeAddressPrefixes
    virtualNetworkName: spokeVirtualNetworkName
    subnets: spokeSubnetsConfig
    dnsServers: spokeDnsServers
  }
}

module hubPeering './modules/virtualNetwork.peering.bicep' = {
  dependsOn: [
    hubVnet
    spokeVnet
  ]
  name: 'hubVnetPeeringDeployment'
  params: {
    allowForwardedTraffic: hubAllowForwardedTraffic
    allowGatewayTransit: hubAllowGatewayTransit
    allowVirtualNetworkAccess: hubAllowVirtualNetworkAccess
    peeringName: hubPeeringName
    remoteVirtualNetworkName: spokeVirtualNetworkName
    useRemoteGateways: hubUseRemoteGateways
    virtualNetworkName: hubVirtualNetworkName
  }
}

module spokePeering './modules/virtualNetwork.peering.bicep' = {
  dependsOn: [
    hubVnet
    spokeVnet
  ]
  name: 'spokeVnetPeeringDeployment'
  params: {
    allowForwardedTraffic: spokeAllowForwardedTraffic
    allowGatewayTransit: spokeAllowGatewayTransit
    allowVirtualNetworkAccess: spokeAllowVirtualNetworkAccess
    peeringName: spokePeeringName
    remoteVirtualNetworkName: hubVirtualNetworkName
    useRemoteGateways: spokeUseRemoteGateways
    virtualNetworkName: spokeVirtualNetworkName
  }
}

module publicIp 'modules/publicip.bicep' = {
  name: 'publicIpDeployment'
  params: {
    location: location
    name: vmName
    skuName: publicIpAddressSkuName
    skuTier: publicIpAddressSkuTier
    publicIPAllocationMethod: publicIPAllocationMethod
  }
}

module dnsNic './modules/networkinterface.bicep' = {
  dependsOn: [
    hubVnet
    publicIp
  ]
  name: 'dnsNicDeployment'
  params: {
    location: location
    isLoadBalanced: isLoadBalanced
    subnetName: subnetName
    vmName: vmName
    vnetName: vnetName
    enableAcceleratedNetworking: enableAcceleratedNetworking
    enableIPForwarding: enableIPForwarding
    privateIPAddress: privateIPAddress
    privateIPAllocationMethod: privateIPAllocationMethod
    publicIpAddressName: '${vmName}-ip'
  }
}

module dnsVM './modules/virtualmachine.bicep' = {
  dependsOn: [
    dnsNic
  ]
  name: 'dnsVmDeployment'
  params: {
    adminPassword: vmAdminPassword
    adminUsername: vmAdminUsername
    imageOffer: imageOffer
    imagePublisher: imagePublisher
    imageSku: imageSku
    osType: osType
    storageSku: storageSku
    vmName: vmName
    vmSize: vmSize
    zone: zone
  }

}

module vmExtension './modules/virtualmachine.extension.bicep' = {
  dependsOn: [
    dnsVM
  ]
  name: 'vmExtensionDeployment'
  params: {
    location: location
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: false
    extensionName: 'installCustomScript'
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    vmName: vmName
    protectedSettings: {
      commandToExecute: setupScript
    }
  }
}

module dnsZone './modules/privatednszone.bicep' = {
  dependsOn: [
    hubVnet
    spokeVnet
  ]
  name: 'dnsZoneDeployment'
  params: {
    privateDnsZoneName: privateDnsZoneName
    targetVnets: targetVnets
  }
}

module storage 'modules/storageAccount.bicep' = {
  name: 'storageDeployment'
  params: {
    location: location
    storageAccountName: storageAccountName
    storageAccountSku: storageAccountSku
    vnetIntegrated: vnetIntegrated
  }
}

module postgreSqlFlex './modules/postgresql.fexible.bicep' = {
  dependsOn: [
//    dnsExtension
    spokeVnet
    dnsZone
    storage
  ]
  name: 'postgreSqlFlexDeployment'
  params: {
    administratorLogin: postgreSqlAdministratorLogin
    administratorLoginPassword: postgreSqlAdministratorLoginPassword
    availabilityZone: postgreSqlAvailabilityZone
    backupRetentionDays: postgreSqlBackupRetentionDays
    virtualNetworkName: postgreSqlVirtualNetworkName
    delegatedSubnetName: postgreSqlDelegatedSubnetName
    geoRedundantBackup: postgreSqlGeoRedundantBackup
    haEnabled: postgreSqlHaEnabled
    location: location
    privateDnsZoneName: privateDnsZoneName
    serverName: postgreSqlServerName
    skuName: postgreSqlSkuName
    storageSizeGB: postgreSqlStorageSizeGB
    tier: postgreSqlTier
    version: postgreSqlVersion
    isLogEnabled: isLogEnabled
    storageAccountName: storageAccountName
  }
}

output vmUsername string = vmAdminUsername
output vmPublicIp string = publicIp.outputs.publicIpAddress
output postgreSqlUsername string = postgreSqlAdministratorLogin
output postgreSqlFqdn string = postgreSqlFlex.outputs.fqdn
