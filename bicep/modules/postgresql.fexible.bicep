param administratorLogin string
@secure()
param administratorLoginPassword string

param location string
param serverName string
param skuName string
param tier string
param storageSizeGB int
param haEnabled string 
param availabilityZone string
param version string
param backupRetentionDays int
param geoRedundantBackup string
param privateDnsZoneName string
param virtualNetworkName string
param delegatedSubnetName string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: virtualNetworkName
}

resource delegatedSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-05-01' existing = {
  parent: vnet
  name: delegatedSubnetName
}

resource postgres 'Microsoft.DBforPostgreSQL/flexibleServers@2021-06-01' = {
  location: location
  name: serverName
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    availabilityZone: availabilityZone
    backup: {
      backupRetentionDays: backupRetentionDays
      geoRedundantBackup: geoRedundantBackup
    }
    highAvailability: {
      mode: haEnabled
    }
    network: {
      delegatedSubnetResourceId: delegatedSubnet.id
      privateDnsZoneArmResourceId: privateDnsZone.id
    }
    storage: {
      storageSizeGB: storageSizeGB
    }
    version: version
  }
  sku: {
    name: skuName
    tier: tier
  }
}

output fqdn string = postgres.properties.fullyQualifiedDomainName
