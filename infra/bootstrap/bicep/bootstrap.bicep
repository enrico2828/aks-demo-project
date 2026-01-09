// =============================================================================
// Bootstrap: Resource Groups + Terraform State Storage
// =============================================================================
// Subscription-level deployment that creates:
// 1. Terraform state resource group + storage account
// 2. Infrastructure resource group (empty, for Terraform to populate)
//
// Deploy with:
//   az deployment sub create --location westeurope \
//     --template-file bootstrap.bicep \
//     --parameters bootstrap.bicepparam
// =============================================================================

targetScope = 'subscription'

// -----------------------------------------------------------------------------
// Parameters
// -----------------------------------------------------------------------------

@description('Azure region for all resources')
param location string = 'westeurope'

@description('Short location code (weu, neu, etc.)')
param locationCode string = 'weu'

@description('Resource naming prefix')
param prefix string = 'aks-demo01'

@description('Environment name (dev, test, prod)')
param environment string = 'dev'

@description('Globally unique storage account name for Terraform remote state')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Blob container name for Terraform state')
param terraformStateContainerName string = 'tfstate'

// -----------------------------------------------------------------------------
// Variables
// -----------------------------------------------------------------------------

var tfstateRgName = '${prefix}-${locationCode}-tfstate-rg'
var infraRgName = '${prefix}-${environment}-${locationCode}-rg'

var commonTags = {
  project: prefix
  managed_by: 'bicep-bootstrap'
}

// -----------------------------------------------------------------------------
// Resource Groups
// -----------------------------------------------------------------------------

resource tfstateRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: tfstateRgName
  location: location
  tags: union(commonTags, { purpose: 'terraform-state' })
}

resource infraRg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: infraRgName
  location: location
  tags: union(commonTags, { environment: environment })
}

// -----------------------------------------------------------------------------
// Storage Account (deployed into tfstate RG)
// -----------------------------------------------------------------------------

module storage 'modules/storage.bicep' = {
  name: 'tfstate-storage'
  scope: tfstateRg
  params: {
    location: location
    storageAccountName: storageAccountName
    containerName: terraformStateContainerName
    tags: union(commonTags, { purpose: 'terraform-state' })
  }
}

// -----------------------------------------------------------------------------
// Outputs
// -----------------------------------------------------------------------------

@description('Terraform state resource group name')
output tfstateResourceGroupName string = tfstateRg.name

@description('Infrastructure resource group name')
output infraResourceGroupName string = infraRg.name

@description('Storage account name for Terraform state')
output storageAccountName string = storage.outputs.storageAccountName

@description('Blob container name for Terraform state')
output containerName string = storage.outputs.containerName
