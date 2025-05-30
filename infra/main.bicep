targetScope = 'subscription'

// The main bicep module to provision Azure resources.
// For a more complete walkthrough to understand how this file works with azd,
// see https://learn.microsoft.com/en-us/azure/developer/azure-developer-cli/make-azd-compatible?pivots=azd-create

@minLength(1)
@maxLength(64)
@description('Name of the the environment which is used to generate a short unique hash used in all resources.')
param environmentName string

@description('The location for all resources')
param location string = resourceGroup().location

// Optional parameters to override the default azd resource naming conventions.
// Add the following to main.parameters.json to provide values:
// "resourceGroupName": {
//      "value": "myGroupName"
// }
param resourceGroupName string = ''
param appServiceName string = ''
@description('The name of the container registry')
param acrName string
@description('The name of the app service plan')
param appServicePlanName string
@description('The name of the web app')
param webAppName string
@description('The name of the container image')
param containerImageName string
@description('The version/tag of the container image')
param containerImageVersion string

var abbrs = loadJsonContent('./abbreviations.json')

// tags that should be applied to all resources.
var tags = {
  // Tag all resources with the environment name.
  'azd-env-name': environmentName
}

// Generate a unique token to be used in naming resources.
// Remove linter suppression after using.
#disable-next-line no-unused-vars
var resourceToken = toLower(uniqueString(subscription().id, environmentName, location))

// Name of the service defined in azure.yaml
// A tag named azd-service-name with this value should be applied to the service host resource, such as:
//   Microsoft.Web/sites for appservice, function
// Example usage:
//   tags: union(tags, { 'azd-service-name': apiServiceName })

// Organize resources in a resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: !empty(resourceGroupName) ? resourceGroupName : '${abbrs.resourcesResourceGroups}${environmentName}'
  location: location
  tags: tags
}

// Add resources to be provisioned below.

// Deploy Azure Container Registry
module acr 'modules/acr.bicep' = {
  name: 'acr-deployment'
  scope: resourceGroup()
  params: {
    name: acrName
    location: location
    acrAdminUserEnabled: true
  }
}

// Deploy App Service Plan
module appServicePlan 'modules/app-service-plan.bicep' = {
  name: 'app-service-plan-deployment'
  scope: resourceGroup()
  params: {
    name: appServicePlanName
    location: location
    sku: {
      capacity: 1
      family: 'B'
      name: 'B1'
      size: 'B1'
      tier: 'Basic'
    }
    kind: 'Linux'
    reserved: true
  }
}

// Deploy Web App
module webApp 'modules/web-app.bicep' = {
  name: 'web-app-deployment'
  scope: resourceGroup()
  params: {
    name: webAppName
    location: location
    kind: 'app'
    serverFarmResourceId: appServicePlan.outputs.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acr.outputs.loginServer}/${containerImageName}:${containerImageVersion}'
      appCommandLine: ''
    }
    appSettingsKeyValuePairs: {
      WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
      DOCKER_REGISTRY_SERVER_URL: 'https://${acr.outputs.loginServer}'
      DOCKER_REGISTRY_SERVER_USERNAME: acr.outputs.adminUsername
      DOCKER_REGISTRY_SERVER_PASSWORD: acr.outputs.adminPassword
    }
  }
}

// Add outputs from the deployment here, if needed.
//
// This allows the outputs to be referenced by other bicep deployments in the deployment pipeline,
// or by the local machine as a way to reference created resources in Azure for local development.
// Secrets should not be added here.
//
// Outputs are automatically saved in the local azd environment .env file.
// To see these outputs, run `azd env get-values`,  or `azd env get-values --output json` for json output.
output AZURE_LOCATION string = location
output AZURE_TENANT_ID string = tenant().tenantId
output webAppHostName string = webApp.outputs.defaultHostName

