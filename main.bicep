targetScope = 'subscription'

param runnerConfigurations array
param vnetConfiguration object
param resoucegroupname string
param location string = 'westeurope'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resoucegroupname
  location: location
}

resource vaultUtilities 'Microsoft.KeyVault/vaults@2019-09-01' existing = [for runnerConfiguration in runnerConfigurations : {
  name: runnerConfiguration.secretConfiguration.keyvaultName
  scope: resourceGroup(runnerConfiguration.secretConfiguration.resourceGroup)
}]

module selfHostedRunners 'modules/virtualMachine.bicep'= [for (runnerConfiguration,i) in runnerConfigurations :{
  name: 'deployRunners-${i}'
  scope: rg
  params: {
    adminUsername: runnerConfiguration.adminUserName
    addressPrefix: vnetConfiguration.addressPrefix
    subnetAddressPrefix: vnetConfiguration.subnetAddressPrefix
    adminPasswordOrKey: vaultUtilities[i].getSecret(runnerConfiguration.secretConfiguration.vmPasswordSecretName)
    authenticationType: 'password'
    vmSize: runnerConfiguration.vmSize
    numberOfRunner: runnerConfiguration.numberOfRunners
    ubuntuOSVersion: runnerConfiguration.ubuntuOSVersion
    location: rg.location
    githubToken: vaultUtilities[i].getSecret(runnerConfiguration.secretConfiguration.tokenSecretName)
    organizationName: runnerConfiguration.githubRepo.organizationName
    runnerVersion: runnerConfiguration.githubRepo.runnerVersion
  }
}]
