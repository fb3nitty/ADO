
# Azure DevOps VMSS Template

A comprehensive Infrastructure-as-Code solution for deploying Windows Server 2022 Virtual Machine Scale Sets with Azure DevOps build agents and .NET Core SDK.

## Overview

This template provides a complete, reusable solution for creating scalable Azure DevOps build infrastructure using:

- **Azure DevOps YAML Pipeline**: Automated deployment and configuration
- **Bicep Infrastructure Template**: Modern ARM template for Azure resources
- **PowerShell Installation Script**: Automated agent and SDK installation
- **Auto-scaling**: Automatic scaling based on CPU utilization
- **Security**: Network security groups and proper access controls

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Azure Resource Group                     │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   Virtual       │  │   Load          │  │   Public     │ │
│  │   Network       │  │   Balancer      │  │   IP         │ │
│  │                 │  │                 │  │              │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              VM Scale Set                               │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │  │   VM 1      │  │   VM 2      │  │   VM N      │     │ │
│  │  │ Win Srv 2022│  │ Win Srv 2022│  │ Win Srv 2022│     │ │
│  │  │ DevOps Agent│  │ DevOps Agent│  │ DevOps Agent│     │ │
│  │  │ .NET SDK    │  │ .NET SDK    │  │ .NET SDK    │     │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐                  │
│  │   Auto Scale    │  │   Network       │                  │
│  │   Settings      │  │   Security      │                  │
│  │                 │  │   Group         │                  │
│  └─────────────────┘  └─────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

## Features

### Infrastructure
- **Windows Server 2022 Azure Edition**: Latest OS with Azure optimizations
- **VM Scale Set**: Scalable compute with 1-100 instances
- **Auto-scaling**: CPU-based scaling (scale out at 75%, scale in at 25%)
- **Load Balancer**: Standard SKU with health probes
- **Virtual Network**: Isolated network with security groups
- **Premium SSD**: High-performance storage

### Software Stack
- **Azure DevOps Build Agent**: Latest version with unattended installation
- **.NET Core SDK**: Latest LTS version
- **Development Tools**: Git, Node.js, Azure CLI
- **IIS Features**: Web server capabilities for .NET applications
- **Chocolatey**: Package manager for additional tools

### Security
- **Network Security Groups**: Controlled access (RDP, HTTP, HTTPS)
- **Managed Identity**: Secure Azure resource access
- **Key Vault Integration**: Secure secret management
- **Encrypted Storage**: Premium SSD with encryption

## Quick Start

### Prerequisites

1. **Azure Subscription** with appropriate permissions
2. **Azure DevOps Organization** with agent pool access
3. **Service Principal** or **Managed Identity** for Azure authentication
4. **Personal Access Token** with Agent Pools (read, manage) permissions

### Step 1: Clone and Configure

```bash
# Clone the repository
git clone <your-repo-url>
cd azure-devops-vmss-template

# Update variables in variables/pipeline-vars.yml
# Update parameters in bicep/parameters.json
```

### Step 2: Set Up Azure DevOps

1. **Create Service Connection**:
   - Go to Project Settings → Service connections
   - Create new Azure Resource Manager connection
   - Use Service Principal or Managed Identity authentication

2. **Create Variable Group**:
   - Go to Pipelines → Library
   - Create new Variable group named `vmss-secrets`
   - Add variables:
     - `admin-password`: VM administrator password
     - `devops-pat`: Personal Access Token for agent registration

3. **Create Environment**:
   - Go to Pipelines → Environments
   - Create new environment (e.g., `production`)

### Step 3: Update Configuration

#### Update Pipeline Variables (`variables/pipeline-vars.yml`):

```yaml
variables:
  # Azure Configuration
  azureServiceConnection: 'your-service-connection-name'
  resourceGroupName: 'rg-your-devops-vmss'
  location: 'East US'
  environmentName: 'your-environment-name'

  # Azure DevOps Configuration
  azureDevOpsUrl: 'https://dev.azure.com/your-organization'
  agentPoolName: 'your-agent-pool'
  
  # VMSS Configuration
  vmssName: 'vmss-your-agents'
  vmSize: 'Standard_D2s_v3'
  instanceCount: 2
```

#### Update Bicep Parameters (`bicep/parameters.json`):

```json
{
  "parameters": {
    "vmssName": {
      "value": "vmss-your-agents"
    },
    "agentPoolName": {
      "value": "your-agent-pool"
    }
  }
}
```

### Step 4: Deploy

1. **Create Azure DevOps Pipeline**:
   - Go to Pipelines → Create Pipeline
   - Choose your repository
   - Select existing Azure Pipelines YAML file
   - Point to `azure-pipelines.yml`

2. **Run Pipeline**:
   - The pipeline will validate, deploy, and configure the infrastructure
   - Monitor the deployment progress in Azure DevOps

3. **Verify Deployment**:
   - Check Azure portal for created resources
   - Verify agents appear in Azure DevOps agent pool
   - Test a simple build to confirm functionality

## Configuration Reference

### Pipeline Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `azureServiceConnection` | Azure service connection name | - | Yes |
| `resourceGroupName` | Target resource group | `rg-devops-vmss` | Yes |
| `location` | Azure region | `East US` | Yes |
| `environmentName` | Azure DevOps environment | `production` | Yes |
| `vmssName` | VM Scale Set name | `vmss-devops-agents` | Yes |
| `vmSize` | VM size | `Standard_D2s_v3` | Yes |
| `instanceCount` | Initial instance count | `2` | Yes |
| `adminUsername` | VM admin username | `azureuser` | Yes |
| `azureDevOpsUrl` | Organization URL | - | Yes |
| `agentPoolName` | Agent pool name | `Default` | Yes |

### Secure Variables (Variable Group)

| Variable | Description | Required |
|----------|-------------|----------|
| `admin-password` | VM administrator password | Yes |
| `devops-pat` | Personal Access Token | Yes |

### Bicep Parameters

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `location` | string | Azure region | Resource group location |
| `vmssName` | string | VM Scale Set name | `vmss-devops-agents` |
| `vmSize` | string | VM size | `Standard_D2s_v3` |
| `instanceCount` | int | Number of instances | `2` |
| `adminUsername` | string | Admin username | `azureuser` |
| `adminPassword` | securestring | Admin password | - |
| `azureDevOpsUrl` | string | DevOps organization URL | - |
| `azureDevOpsPat` | securestring | Personal Access Token | - |
| `agentPoolName` | string | Agent pool name | `Default` |

## Customization

### VM Sizes

Recommended VM sizes for different workloads:

| Workload | VM Size | vCPUs | RAM | Description |
|----------|---------|-------|-----|-------------|
| Light | `Standard_B2s` | 2 | 4 GB | Basic builds, small projects |
| Standard | `Standard_D2s_v3` | 2 | 8 GB | Most .NET applications |
| Heavy | `Standard_D4s_v3` | 4 | 16 GB | Large solutions, parallel builds |
| Intensive | `Standard_D8s_v3` | 8 | 32 GB | Enterprise applications |

### Auto-scaling Configuration

Modify auto-scaling rules in the Bicep template:

```bicep
// Scale out when CPU > 75% for 5 minutes
{
  metricTrigger: {
    metricName: 'Percentage CPU'
    operator: 'GreaterThan'
    threshold: 75
    timeWindow: 'PT5M'
  }
  scaleAction: {
    direction: 'Increase'
    value: '1'
    cooldown: 'PT5M'
  }
}
```

### Additional Software

Add software installation to the PowerShell script:

```powershell
# Install additional tools via Chocolatey
choco install docker-desktop -y
choco install kubernetes-cli -y
choco install terraform -y
```

### Network Security

Modify NSG rules in the Bicep template:

```bicep
{
  name: 'AllowCustomPort'
  properties: {
    priority: 1003
    protocol: 'Tcp'
    access: 'Allow'
    direction: 'Inbound'
    sourceAddressPrefix: 'VirtualNetwork'
    destinationPortRange: '8080'
  }
}
```

## Troubleshooting

### Common Issues

#### 1. Agent Registration Fails

**Symptoms**: Agents don't appear in Azure DevOps
**Solutions**:
- Verify Personal Access Token has correct permissions
- Check Azure DevOps URL format
- Ensure agent pool exists
- Review installation logs at `C:\temp\devops-agent-install.log`

#### 2. .NET SDK Not Found

**Symptoms**: Build fails with .NET not found
**Solutions**:
- Verify PATH environment variable includes .NET
- Check installation logs
- Manually verify: `C:\Program Files\dotnet\dotnet.exe --version`

#### 3. VM Scale Set Deployment Fails

**Symptoms**: Bicep deployment errors
**Solutions**:
- Check resource group permissions
- Verify subscription quotas
- Review Azure Activity Log
- Validate Bicep template: `az deployment group validate`

#### 4. Auto-scaling Not Working

**Symptoms**: Scale set doesn't scale automatically
**Solutions**:
- Check auto-scale settings in Azure portal
- Verify metrics are being collected
- Review scale set activity history
- Ensure sufficient quota for scaling

### Debugging

#### View Agent Logs

```powershell
# On the VM
Get-Content "C:\agent\_diag\Agent_*.log" -Tail 50
```

#### Check Service Status

```powershell
# Check agent service
Get-Service "vstsagent*"

# View service logs
Get-EventLog -LogName Application -Source "VSTSAgent*" -Newest 10
```

#### Azure CLI Debugging

```bash
# Check VMSS status
az vmss show --resource-group rg-devops-vmss --name vmss-devops-agents

# Check instances
az vmss list-instances --resource-group rg-devops-vmss --name vmss-devops-agents

# Check auto-scale settings
az monitor autoscale show --resource-group rg-devops-vmss --name vmss-devops-agents-autoscale
```

## Security Considerations

### Network Security
- NSG rules restrict access to necessary ports only
- Consider using Azure Bastion for secure RDP access
- Implement Just-In-Time (JIT) access for VMs

### Identity and Access
- Use Managed Identity where possible
- Rotate Personal Access Tokens regularly
- Implement least-privilege access principles

### Data Protection
- Enable disk encryption for sensitive workloads
- Use Azure Key Vault for secret management
- Implement backup strategies for critical data

### Monitoring
- Enable Azure Monitor for VM insights
- Set up alerts for security events
- Monitor agent pool usage and performance

## Cost Optimization

### Right-sizing
- Start with smaller VM sizes and scale as needed
- Use auto-scaling to optimize costs
- Consider Azure Reserved Instances for predictable workloads

### Storage
- Use Standard SSD for non-critical workloads
- Implement lifecycle policies for temporary files
- Monitor storage usage and clean up regularly

### Scheduling
- Scale down during off-hours if possible
- Use Azure Automation for scheduled scaling
- Consider spot instances for non-critical builds

## Support and Contributing

### Getting Help
- Check Azure DevOps documentation
- Review Azure Bicep documentation
- Open issues in the repository

### Contributing
- Fork the repository
- Create feature branches
- Submit pull requests with clear descriptions
- Follow coding standards and best practices

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Changelog

### Version 1.0.0
- Initial release
- Windows Server 2022 support
- Azure DevOps agent automation
- .NET Core SDK installation
- Auto-scaling configuration
- Comprehensive documentation
