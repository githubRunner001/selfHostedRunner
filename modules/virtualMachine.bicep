@description('The name of you Virtual Machine.')
param vmPrefixName string = 'githubRunner'

@description('How many runner do you want to deploy')
param numberOfRunner int

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  '16.04.0-LTS'
  '18.04-LTS'
])
param ubuntuOSVersion string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The size of the VM')
param vmSize string

@description('Subnet Prefix')
param subnetAddressPrefix string = '10.1.0.0/24'

@description('Vnet Address prefix')
param addressPrefix string = '10.1.0.0/16'

@description('gitHub Token to create runner')
@secure()
param githubToken string

@description('gitHub organization name')
param organizationName string

@description('GitHub runner Version')
param runnerVersion string

@description('OS Disk Type')
var osDiskType = 'Standard_LRS'

var vmName = '${vmPrefixName}sbx'
var networkInterfaceName = '${vmName}NetInt'
var virtualNetworkName = '${vmPrefixName}vNet'
var subnetName = '${vmPrefixName}Subnet'
var networkSecurityGroupName = '${vmPrefixName}Nsg'
var customData = loadTextContent('../config/cloudInit')
var finalCustomData = format(customData,runnerVersion,organizationName,githubToken)
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = [for i in range(0, numberOfRunner) :{
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}]

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets:[
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = [for i in range(0, numberOfRunner) :{
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: ubuntuOSVersion
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic[i].id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      customData: base64(finalCustomData)
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
    }
  }
}]
