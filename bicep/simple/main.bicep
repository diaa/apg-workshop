@description('Location for all resources.')
param location string = resourceGroup().location

@description('Base name for resources (3-10 chars, lowercase recommended).')
param randomString string = uniqueString(subscription().subscriptionId, resourceGroup().id, deployment().name)

param baseName string = 'psqlf${randomString}'

@description('PostgreSQL admin username (must start with a letter).')
@minLength(1)
param administratorLogin string

@description('PostgreSQL admin password (min 12 chars, 1 upper, 1 lower, 1 number, 1 special).')
@secure()
param administratorPassword string

@description('Your public IP for firewall access (e.g., 123.45.67.89).')
param clientIPAddress string

@description('Enable zone redundant high availability.')
param enableHighAvailability bool = false

@description('Enable read replica in secondary zone.')
param enableReadReplica bool = false

@description('SKU name for flexible server (must be available in your region).')
param skuName string = 'Standard_D2ds_v4'

@description('SKU tier.')
@allowed([
  'Burstable'
  'GeneralPurpose'
  'MemoryOptimized'
])
param skuTier string = 'GeneralPurpose'

@description('PostgreSQL major version (ensure it is supported in your region).')
param postgresVersion string = '17'

@description('Provisioned storage size in GB.')
param storageSizeGB int = 128

@description('Name of the virtual network.')
param vnetName string = '${baseName}-vnet'

@description('Name of the subnet.')
param subnetName string = 'db-subnet'

@description('Name of the private DNS zone for PostgreSQL Flexible Server.')
param privateDnsZoneName string = 'privatelink.postgres.database.azure.com'


var normalizedBase = toLower(baseName)
var serverName = '${normalizedBase}-primary'
var replicaName = '${normalizedBase}-replica'

var privateDnsZoneId = resourceId('Microsoft.Network/privateDnsZones', privateDnsZoneName)

resource vnet 'Microsoft.Network/virtualNetworks@2023-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-02-01' = {
  name: subnetName
  parent: vnet
  properties: {
    addressPrefix: '10.0.0.0/24'
    delegations: [
      {
        name: 'postgresDelegation'
        properties: {
          serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
        }
      }
    ]
  }
}

resource primaryServer 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: serverName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    version: postgresVersion
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorPassword
    storage: {
      storageSizeGB: storageSizeGB
      autoGrow: 'Enabled'
    }
    backup: {
      backupRetentionDays: 35
      geoRedundantBackup: 'Disabled'
    }
    network: {
//      delegatedSubnetResourceId: subnet.id
//      privateDnsZoneArmResourceId: privateDnsZoneId  
      publicNetworkAccess: 'Enabled'

    }
    highAvailability: {
      mode: enableHighAvailability ? 'ZoneRedundant' : 'Disabled'
    }
    maintenanceWindow: {
      customWindow: 'Enabled'
      dayOfWeek: 6
      startHour: 2
    }
  }
}

resource firewallRule 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2024-08-01' = {
  parent: primaryServer
  name: 'allow-client-ip'
  properties: {
    startIpAddress: clientIPAddress
    endIpAddress: clientIPAddress
  }
}

resource readReplica 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = if (enableReadReplica) {
  name: replicaName
  location: location
  sku: {
    name: skuName
    tier: skuTier
  }
  properties: {
    createMode: 'Replica'
    sourceServerResourceId: primaryServer.id
    network: {
      delegatedSubnetResourceId: subnet.id
    }
  }
}

output primaryServerName string = primaryServer.name
output primaryEndpoint string = primaryServer.properties!.fullyQualifiedDomainName
output replicaEndpoint string = (enableReadReplica ? readReplica.properties!.fullyQualifiedDomainName : '')
output psqlCommand string = 'psql "host=${primaryServer.properties!.fullyQualifiedDomainName} user=${administratorLogin} dbname=postgres sslmode=require"'
output managementPortal string = 'https://portal.azure.com/#resource${primaryServer.id}/overview'
output connectionInstructions string = '''
# Production Connection String:
Host=${primaryServer.properties!.fullyQualifiedDomainName};Username=${administratorLogin};Password=******;Database=postgres;SSL Mode=Require;

# Read Replica Connection (for read-only queries):
${enableReadReplica ? 'Host=' + readReplica.properties!.fullyQualifiedDomainName + ';Username=' + administratorLogin + ';Password=******;Database=postgres;SSL Mode=Require;' : 'Replica not enabled'}
'''

