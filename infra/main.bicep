param location           string = ''westeurope''
param acrName            string = ''jwendtacr''
param planName           string = ''jwendt-asp''
param webName            string = ''jwendt-web''
param linuxSku           object = {
  capacity: 1
  family:   ''B''
  name:     ''B1''
  size:     ''B1''
  tier:     ''Basic''
}
module acr ''./modules/container-registry/main.bicep'' = {
  name: ''acr''
  params: {
    name:      acrName
    location:  location
    adminUserEnabled: true
  }
}
module plan ''./modules/app-service/hostingPlan/main.bicep'' = {
  name: ''plan''
  params: {
    name:     planName
    location: location
    sku:      linuxSku
    kind:     ''Linux''
    reserved: true
  }
}
module web ''./modules/web/site/main.bicep'' = {
  name: ''web''
  params: {
    name:                 webName
    location:             location
    kind:                 ''app''
    serverFarmResourceId: plan.outputs.resourceId
    siteConfig: {
      linuxFxVersion:  ''DOCKER|${acrName}.azurecr.io/placeholder:latest''
      appCommandLine:  ''''
    }
    appSettingsKeyValuePairs: {
      WEBSITES_ENABLE_APP_SERVICE_STORAGE: false
      DOCKER_REGISTRY_SERVER_URL:  ''https://${acrName}.azurecr.io''
      DOCKER_REGISTRY_SERVER_USERNAME: acr.outputs.adminUsername
      DOCKER_REGISTRY_SERVER_PASSWORD: acr.outputs.adminPassword
    }
  }
  dependsOn: [acr]
}
