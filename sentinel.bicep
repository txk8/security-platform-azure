@description('Location for all resources.')
param location string = 'uksouth'

@description('Resource group name.')
param resourceGroupName string = 'rg-azsec-platform-dev'

@description('Log Analytics workspace name.')
param workspaceName string = 'la-azsec-platform-dev'

@description('Log Analytics SKU.')
param workspaceSku string = 'PerGB2018'

@description('Retention period in days for the Log Analytics workspace.')
param retentionInDays int = 30

@description('Enable Azure Sentinel on the Log Analytics workspace.')
param enableSentinel bool = true

@description('Tags for all resources.')
param tags object = {
  environment: 'dev'
  managedBy: 'bicep'
  workload: 'security-platform'
}

// Create resource group
resource rg 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// Create Log Analytics workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: location
  tags: union(tags, {
    'log-analytics-workspace': 'security'
  })
  properties: {
    sku: {
      name: workspaceSku
    }
    retentionInDays: retentionInDays
    features: {
      searchVersion: 1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
  dependsOn: [
    rg
  ]
}

// Enable Azure Sentinel (Microsoft Sentinel)
resource sentinel 'Microsoft.SecurityInsights/onboardingStates@2024-01-01-preview' = if (enableSentinel) {
  name: 'default'
  scope: logAnalytics
  properties: {
    customerManagedKey: false
  }
  dependsOn: [
    logAnalytics
  ]
}

// Output useful information
output resourceGroupName string = rg.name
output logAnalyticsWorkspaceId string = logAnalytics.id
output logAnalyticsWorkspaceName string = logAnalytics.name
output workspacePrimarySharedKey string = listKeys(logAnalytics.id, logAnalytics.apiVersion).primarySharedKey
output workspaceCustomerId string = logAnalytics.properties.customerId
output sentinelEnabled bool = enableSentinel
output deploymentRegion string = location
