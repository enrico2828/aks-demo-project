// =============================================================================
// Terraform State Storage Account
// =============================================================================

@description('Azure region')
param location string

@description('Storage account name')
@minLength(3)
@maxLength(24)
param storageAccountName string

@description('Blob container name')
param containerName string

@description('Resource tags')
param tags object

// -----------------------------------------------------------------------------
// Storage Account
// -----------------------------------------------------------------------------

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    encryption: {
      services: {
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }

  resource blobService 'blobServices' = {
    name: 'default'

    resource container 'containers' = {
      name: containerName
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

// -----------------------------------------------------------------------------
// Outputs
// -----------------------------------------------------------------------------

@description('Storage account name')
output storageAccountName string = storageAccount.name

@description('Blob container name')
output containerName string = storageAccount::blobService::container.name
