// Azure DevOps VMSS Infrastructure Template
// Creates a Windows Server 2022 VM Scale Set with Azure DevOps build agents
//
// SECURITY CONFIGURATION: PRIVATE IP ONLY WITH vWAN/AZURE FIREWALL
// ================================================================
// This template is configured for enhanced security with private IP addresses only:
// 
// 1. VM Scale Set instances use PRIVATE IPs only - no public IP addresses assigned
// 2. Outbound internet connectivity provided via existing vWAN with Azure Firewall
// 3. Network Security Group rules restricted to VirtualNetwork scope only

// ASSUMPTIONS:
// - You have an existing vWAN (Virtual WAN) infrastructure with Azure Firewall configured
// - Azure Firewall is configured to allow outbound connectivity 
// - The virtual network is either connected to vWAN or you're using an existing vWAN-connected VNet
// - Azure DevOps agents can reach Azure DevOps services through the Azure Firewall
// while remaining completely private and secure from inbound internet traffic.

@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the VM Scale Set')
param vmssName string = 'vmss-devops-agents'

@description('Size of the VM instances')
param vmSize string = 'Standard_D2s_v3'

@description('Number of VM instances')
@minValue(1)
@maxValue(100)
param instanceCount int = 2

@description('Admin username for the VMs')
param adminUsername string = 'azureuser'

@description('Admin password for the VMs')
@secure()
param adminPassword string

@description('Azure DevOps organization URL')
param azureDevOpsUrl string

@description('Azure DevOps Personal Access Token')
@secure()
param azureDevOpsPat string

@description('Azure DevOps agent pool name')
param agentPoolName string = 'Default'

@description('Virtual network name (will be created if using new VNet, or referenced if using existing)')
param vnetName string = 'vnet-devops'

@description('Subnet name (will be created if using new VNet, or referenced if using existing)')
param subnetName string = 'subnet-agents'

@description('Virtual network address prefix (only used when creating new VNet)')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Subnet address prefix (only used when creating new VNet)')
param subnetAddressPrefix string = '10.0.1.0/24'

@description('Network security group name')
param nsgName string = 'nsg-devops-agents'

@description('Use existing virtual network (true) or create new one (false). If true, specify existingVnetResourceGroup, existingVnetName, and existingSubnetName.')
param useExistingVnet bool = false

@description('Resource group name of the existing virtual network (required if useExistingVnet is true)')
param existingVnetResourceGroup string = ''

@description('Name of the existing virtual network (required if useExistingVnet is true)')
param existingVnetName string = ''

@description('Name of the existing subnet (required if useExistingVnet is true)')
param existingSubnetName string = ''

@description('Project tag')
param projectTag string = 'DevOps-Infrastructure'

@description('Environment tag')
param environmentTag string = 'Production'

@description('Owner tag')
param ownerTag string = 'DevOps-Team'

@description('Creation date for resources')
param createdDate string = utcNow('yyyy-MM-dd')

// Variables
var imageReference = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2022-datacenter-azure-edition'
  version: 'latest'
}

// Determine VNet and subnet names based on whether using existing or new
var actualVnetName = useExistingVnet ? existingVnetName : vnetName
var actualSubnetName = useExistingVnet ? existingSubnetName : subnetName
var actualVnetResourceGroup = useExistingVnet ? existingVnetResourceGroup : resourceGroup().name

// Network Security Group Rules - Configured for private IP only access
// RDP access is restricted to VNet only since VMs have no public IPs
var networkSecurityGroupRules = [
  {
    name: 'AllowRDPFromVNet'
    properties: {
      priority: 1000
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '3389'
    }
  }
  {
    name: 'AllowHTTPSFromVNet'
    properties: {
      priority: 1001
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '443'
    }
  }
  {
    name: 'AllowHTTPFromVNet'
    properties: {
      priority: 1002
      protocol: 'Tcp'
      access: 'Allow'
      direction: 'Inbound'
      sourceAddressPrefix: 'VirtualNetwork'
      sourcePortRange: '*'
      destinationAddressPrefix: '*'
      destinationPortRange: '80'
    }
  }
]

var commonTags = {
  Project: projectTag
  Environment: environmentTag
  Owner: ownerTag
  CreatedBy: 'Bicep-Template'
  CreatedDate: createdDate
}

// Network Security Group
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: nsgName
  location: location
  tags: commonTags
  properties: {
    securityRules: networkSecurityGroupRules
  }
}

// Virtual Network - Only created if not using existing VNet
// For vWAN scenarios, you may want to use an existing VNet that's connected to vWAN
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-09-01' = if (!useExistingVnet) {
  name: vnetName
  location: location
  tags: commonTags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          // No NAT Gateway association - outbound connectivity via vWAN Azure Firewall
        }
      }
    ]
  }
}

// VM Scale Set
resource vmScaleSet 'Microsoft.Compute/virtualMachineScaleSets@2023-09-01' = {
  name: vmssName
  location: location
  tags: commonTags
  sku: {
    name: vmSize
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    overprovision: false
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
        }
        imageReference: imageReference
      }
      osProfile: {
        computerNamePrefix: substring(vmssName, 0, min(length(vmssName), 9))
        adminUsername: adminUsername
        adminPassword: adminPassword
        windowsConfiguration: {
          enableAutomaticUpdates: true
          provisionVMAgent: true
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: '${vmssName}-nic'
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: '${vmssName}-ipconfig'
                  properties: {
                    // Private IP configuration only - no public IP addresses assigned
                    privateIPAddressVersion: 'IPv4'
                    subnet: {
                      id: resourceId(actualVnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', actualVnetName, actualSubnetName)
                    }
                    // Note: publicIPAddressConfiguration is omitted for private-only setup
                    // Note: loadBalancerBackendAddressPools removed since no load balancer
                  }
                }
              ]
            }
          }
        ]
      }
      extensionProfile: {
        extensions: [
          {
            name: 'InstallDevOpsAgent'
            properties: {
              publisher: 'Microsoft.Compute'
              type: 'CustomScriptExtension'
              typeHandlerVersion: '1.10'
              autoUpgradeMinorVersion: true
              settings: {
                fileUris: [
                  'https://raw.githubusercontent.com/your-repo/azure-devops-vmss-template/main/scripts/install-devops-agent.ps1'
                ]
              }
              protectedSettings: {
                commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File install-devops-agent.ps1 -AzureDevOpsUrl "${azureDevOpsUrl}" -PersonalAccessToken "${azureDevOpsPat}" -AgentPool "${agentPoolName}" -AgentName "${vmssName}-agent"'
              }
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    virtualNetwork // Only depends on VNet if we're creating a new one
  ]
}

// Auto Scale Settings
resource autoScaleSettings 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: '${vmssName}-autoscale'
  location: location
  tags: commonTags
  properties: {
    name: '${vmssName}-autoscale'
    targetResourceUri: vmScaleSet.id
    enabled: true
    profiles: [
      {
        name: 'DefaultProfile'
        capacity: {
          minimum: '1'
          maximum: '10'
          default: string(instanceCount)
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: 'Microsoft.Compute/virtualMachineScaleSets'
              metricResourceUri: vmScaleSet.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 75
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: 'Microsoft.Compute/virtualMachineScaleSets'
              metricResourceUri: vmScaleSet.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 25
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
}

// Outputs
output vmssName string = vmScaleSet.name
output vmssId string = vmScaleSet.id
output virtualNetworkId string = useExistingVnet ? resourceId(actualVnetResourceGroup, 'Microsoft.Network/virtualNetworks', actualVnetName) : virtualNetwork.id
output subnetId string = resourceId(actualVnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', actualVnetName, actualSubnetName)
output networkSecurityGroupId string = networkSecurityGroup.id
// Note: VMs use private IPs only - no public IP addresses assigned to instances
// Note: Outbound connectivity provided by vWAN Azure Firewall - no NAT Gateway outputs
