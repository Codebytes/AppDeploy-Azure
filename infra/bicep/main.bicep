param rgName string = 'rg001'
param location string = resourceGroup().location
param webAppName string = 'site001'

param dockerRegistryHost string = 'myAcr'
param dockerRegistryServerUsername string = 'adminUser'
param dockerImage string = 'app/frontend:latest'
param acrResourceGroup string = resourceGroup().name
param acrSubscription string = subscription().subscriptionId

// external ACR info
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2019-05-01' existing = {
  scope: resourceGroup(acrSubscription, acrResourceGroup)
  name: dockerRegistryHost
}

resource site 'microsoft.web/sites@2020-06-01' = {
  name: webAppName
  location: location
  properties: {
    siteConfig: {
      appSettings: [
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${dockerRegistryHost}.azurecr.io'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_USERNAME'
          value: dockerRegistryServerUsername
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: containerRegistry.listCredentials().passwords[0].value
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
      ]
      linuxFxVersion: 'DOCKER|${dockerRegistryHost}.azurecr.io/${dockerImage}'
    }
    serverFarmId: farm.id
  }
}

var farmName = '${webAppName}-farm'

resource farm 'microsoft.web/serverFarms@2020-06-01' = {
  name: farmName
  location: location
  sku: {
    name: 'B1'
    tier: 'Basic'
  }
  kind: 'linux'
  properties: {
    targetWorkerSizeId: 0
    targetWorkerCount: 1
    reserved: true
  }
}

output publicUrl string = site.properties.defaultHostName
