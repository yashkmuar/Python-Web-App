@description('The name of the App Service Plan')
param name string

@description('The location of the App Service Plan')
param location string

@description('The SKU of the App Service Plan')
param sku object = {
  capacity: 1
  family: 'B'
  name: 'B1'
  size: 'B1'
  tier: 'Basic'
}

@description('The kind of the App Service Plan')
param kind string = 'Linux'

@description('Whether to reserve the App Service Plan')
param reserved bool = true

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: name
  location: location
  sku: sku
  kind: kind
  properties: {
    reserved: reserved
  }
}

output id string = appServicePlan.id 
