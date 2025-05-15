@description('NSG名')
param nsgName string = 'nsg-apim-integration'

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: nsgName
  location: resourceGroup().location
  properties: {
    securityRules: []
  }
}

@description('VNet名')
param vNetName string = 'vnet-bicep-test'

@description('VNetのアドレス空間')
param vNetAddressPrefix string = '10.10.0.0/16'

@description('privateEndpointのサブネット')
param vNetSubnetAddressPrefixPrivateEndpoints string = '10.10.2.0/24'

@description('API ManagementのVNet統合用サブネット')
param vNetSubnetAddressPrefixAPIMIntegration string = '10.10.1.0/24'

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vNetName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-apim-integration'
        properties: {
          addressPrefix: vNetSubnetAddressPrefixAPIMIntegration
          delegations: [
            {
              name: 'Microsoft.Web.serverFarms'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
      {
        name: 'snet-apim-pep'
        properties: {
          addressPrefix: vNetSubnetAddressPrefixPrivateEndpoints
        }
      }
    ]
  }
}

@description('API Management名')
param apimName string = 'apim-vnet-test-001'

resource apim 'Microsoft.ApiManagement/service@2024-05-01' = {
  name: apimName
  location: resourceGroup().location
  sku: {
    name: 'Standardv2'
    capacity: 1
  }
  properties: {
    publisherEmail: 'admin@example.com'
    publisherName: 'Admin'
    publicNetworkAccess: 'Disabled' // 作成時には無効化できないため、作成後に無効化する
    virtualNetworkType: 'External'
    virtualNetworkConfiguration: {
      subnetResourceId: vnet.properties.subnets[0].id
    }
  }
}

@description('Private DNS Zone名')
param privateDnsZoneName string = 'privatelink.azure-api.net'

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: privateDnsZoneName
  location: 'global'

  resource virtualNetworkLink 'virtualNetworkLinks@2024-06-01' = {
    name: privateDnsZoneName
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnet.id
      }
    }
  }
}

@description('Private Endpoint名')
param privateEndpointName string = 'pep-apim-bicep-test'

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: privateEndpointName
  location: resourceGroup().location
  properties: {
    subnet: {
      id: vnet.properties.subnets[1].id
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: apim.id
          groupIds: [
            'Gateway'
          ]
        }
      }
    ]
  }

  resource privateDnsZoneGroup 'privateDnsZoneGroups@2024-05-01' = {
    name: 'default'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: privateDnsZoneName
          properties: {
            privateDnsZoneId: privateDnsZone.id
          }
        }
      ]
    }
  }
}
