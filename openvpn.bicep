param location string = resourceGroup().location
param vmName string = 'openvpn-vm'
param adminUsername string
@secure()
param adminPassword string
param vmUp bool
param installDependenciesB64 string
param downloadCredentialsB64 string
param setupOpenVPNB64 string
param uploadCredentialsB64 string
param vmInitB64 string

param vmSize string = 'Standard_B1ms'
param vnetName string = 'openvpn-vnet'
param subnetName string = 'default'
param bastionSubnetName string = 'AzureBastionSubnet'
param addressPrefix string = '10.0.0.0/24'
param subnetPrefix string = '10.0.0.0/28'
param bastionSubnetPrefix string = '10.0.0.64/26'
param publicIpName string = 'openvpn-ip'
param bastionPublicIpName string = 'bastion-ip'
param nicName string = 'openvpn-nic'
param storageAccountName string = 'vpnstorage006314d62eef4d'
param containerName string = 'vpn'
param nsgName string = 'openvpn-nsg'
param bastionHostName string = 'openvpn-bastion'

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-OpenVPN'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'UDP'
          sourcePortRange: '*'
          destinationPortRange: '1194'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [addressPrefix]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionSubnetPrefix
        }
      }
    ]
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    deleteOption: 'Detach'
    publicIPAllocationMethod: 'Static'
  }
}

resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: bastionPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = if (vmUp) {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          primary: true
          subnet: {
            id: '${vnet.id}/subnets/${subnetName}'
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = if (vmUp) {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

resource customScript 'Microsoft.Compute/virtualMachines/extensions@2021-03-01' = {
  parent: vm
  dependsOn: [blobContainer]
  name: 'installOpenVPN'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    protectedSettings: {
      commandToExecute: 'echo ${installDependenciesB64} | base64 -d > installDependencies.sh && echo ${downloadCredentialsB64} | base64 -d > downloadCredentials.sh && echo ${setupOpenVPNB64} | base64 -d > setupOpenVPN.sh && echo ${uploadCredentialsB64} | base64 -d > uploadCredentials.sh && echo ${vmInitB64} | base64 -d > vmInit.sh && bash vmInit.sh ${storageAccount.listKeys().keys[0].value}'
    }
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-02-01' = {
  parent: storageAccount
  name: 'default'
  properties: {}
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-02-01' = {
  parent: blobService
  name: containerName
  properties: {
    publicAccess: 'None'
  }
}

// TODO: this should not be left on all the time
resource bastionHost 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: bastionHostName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'bastionHostIpConfig'
        properties: {
          subnet: {
            id: '${vnet.id}/subnets/${bastionSubnetName}'
          }
          publicIPAddress: {
            id: bastionPublicIp.id
          }
        }
      }
    ]
  }
}
