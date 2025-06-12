
# Azure DevOps VMSS Template with Microsoft Prebuilt Images

A comprehensive Infrastructure-as-Code solution for deploying scalable Azure DevOps build agents using Microsoft's prebuilt runner images with enhanced security and vWAN integration.

## 🚀 Overview

This template provides a complete, enterprise-ready solution for creating scalable Azure DevOps build infrastructure using:

- **Microsoft Prebuilt Runner Images**: Visual Studio 2022/2019, Build Tools, or Windows Server 2022
- **Enhanced Security**: Private IP addresses only with vWAN/Azure Firewall integration
- **Bicep Infrastructure Template**: Modern ARM template for Azure resources
- **Chocolatey Integration**: Custom package installation capabilities
- **Auto-scaling**: Automatic scaling based on CPU utilization
- **Zero Public IP**: Complete private network architecture

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           vWAN + Azure Firewall                            │
│                        (Existing Infrastructure)                           │
└─────────────────────────┬───────────────────────────────────────────────────┘
                          │ Secure Outbound Connectivity
                          │
┌─────────────────────────▼───────────────────────────────────────────────────┐
│                    Azure Resource Group                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────────────────────┐ │
│  │   Virtual       │  │   Network       │  │      VM Scale Set            │ │
│  │   Network       │  │   Security      │  │   (Private IPs Only)        │ │
│  │   (Private)     │  │   Group         │  │                              │ │
│  └─────────────────┘  └─────────────────┘  │  ┌─────────────────────────┐ │ │
│                                             │  │ Microsoft Prebuilt      │ │ │
│  ┌─────────────────┐  ┌─────────────────┐  │  │ Runner Images:          │ │ │
│  │   Auto Scale    │  │   Load          │  │  │ • VS 2022 Enterprise    │ │ │
│  │   Settings      │  │   Balancer      │  │  │ • VS 2022 Build Tools   │ │ │
│  │   (CPU-based)   │  │   (Internal)    │  │  │ • VS 2019 Enterprise    │ │ │
│  └─────────────────┘  └─────────────────┘  │  │ • Windows Server 2022   │ │ │
│                                             │  └─────────────────────────┘ │ │
│                                             │  + Azure DevOps Agents       │ │
│                                             │  + Chocolatey Integration     │ │
│                                             └──────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

## ✨ Key Features

### 🔒 Enhanced Security Architecture
- **Private IP Only**: No public IP addresses assigned to VMs
- **vWAN Integration**: Designed for existing vWAN with Azure Firewall
- **Network Security Groups**: Restricted to VirtualNetwork scope only
- **Zero Internet Exposure**: VMs completely isolated from inbound internet traffic

### 🖥️ Microsoft Prebuilt Images
- **Visual Studio 2022 Enterprise**: Full development environment with VS 2022, .NET SDKs, Azure CLI
- **Visual Studio 2022 Build Tools**: Minimal build environment with MSBuild and .NET SDKs
- **Visual Studio 2019 Enterprise**: Legacy development environment for older projects
- **Windows Server 2022**: Base server for custom tooling scenarios

### 🍫 Chocolatey Integration
- **Package Manager**: Automated installation of additional tools
- **Custom Packages**: Support for Node.js, Python, Docker, Terraform, and more
- **Version Control**: Specify exact package versions
- **Flexible Configuration**: Enable/disable based on requirements

### 📈 Auto-scaling & Performance
- **CPU-based Scaling**: Scale out at 75%, scale in at 25%
- **Instance Range**: 1-100 instances supported
- **Fast Deployment**: 5-10 minutes vs 30-45 minutes with custom installations
- **Premium Storage**: High-performance SSD storage

## 🚀 Quick Start

### Prerequisites

- Azure subscription with Contributor access
- Azure DevOps organization with agent pool access
- Existing vWAN with Azure Firewall (or compatible network infrastructure)
- Personal Access Token with Agent Pools (read, manage) permissions

### 1. Accept Marketplace Terms

**Required for Visual Studio images:**

```bash
# Visual Studio 2022 Enterprise
az vm image terms accept --publisher MicrosoftVisualStudio --offer visualstudio2022 --plan vs-2022-ent-latest-ws2022

# Visual Studio 2022 Build Tools
az vm image terms accept --publisher MicrosoftVisualStudio --offer visualstudio2022 --plan vs-2022-buildtools-latest-ws2022

# Visual Studio 2019 Enterprise
az vm image terms accept --publisher MicrosoftVisualStudio --offer visualstudio2019 --plan vs-2019-ent-latest-ws2019
```

### 2. Deploy Infrastructure

```bash
# Clone repository
git clone <your-repo-url>
cd azure-devops-vmss-template

# Update parameters
cp bicep/parameters.json bicep/parameters-prod.json
# Edit parameters-prod.json with your values

# Deploy
az deployment group create \
  --resource-group rg-devops \
  --template-file bicep/vmss-infrastructure.bicep \
  --parameters @bicep/parameters-prod.json \
  --parameters adminPassword='YourSecurePassword123!' \
  --parameters azureDevOpsUrl='https://dev.azure.com/yourorg' \
  --parameters azureDevOpsPat='your-pat-token'
```

### 3. Verify Deployment

```bash
# Check VMSS status
az vmss show --resource-group rg-devops --name vmss-devops-agents

# Check agent registration in Azure DevOps
# Go to Organization Settings → Agent pools → Your pool
```

## 🛠️ Configuration Options

### Microsoft Image Types

| Image Type | Description | VM Size | Use Case |
|------------|-------------|---------|----------|
| `vs2022-enterprise` | VS 2022 + full dev tools | `Standard_D4s_v3` | Full development |
| `vs2022-buildtools` | MSBuild + .NET SDKs | `Standard_D2s_v3` | CI/CD builds |
| `vs2019-enterprise` | VS 2019 + legacy tools | `Standard_D4s_v3` | Legacy projects |
| `windowsserver-2022` | Base Windows Server | `Standard_D2s_v3` | Custom tooling |

### Chocolatey Package Examples

```json
{
  "chocoPackages": ["nodejs", "python", "docker-desktop", "terraform"],
  "chocoPackageParams": {
    "nodejs": "--version=18.17.0",
    "python": "--version=3.11.0"
  }
}
```

### Network Configuration

```json
{
  "useExistingVnet": true,
  "existingVnetResourceGroup": "rg-network",
  "existingVnetName": "vnet-hub",
  "existingSubnetName": "subnet-devops"
}
```

## 📋 Deployment Examples

### Example 1: Visual Studio 2022 Enterprise with Custom Packages

```bash
az deployment group create \
  --resource-group rg-devops \
  --template-file bicep/vmss-infrastructure.bicep \
  --parameters microsoftImageType=vs2022-enterprise \
  --parameters vmSize=Standard_D4s_v3 \
  --parameters instanceCount=3 \
  --parameters azureDevOpsUrl=https://dev.azure.com/myorg \
  --parameters azureDevOpsPat=<your-pat> \
  --parameters agentPoolName=VS2022-Pool \
  --parameters adminPassword=<secure-password>
```

### Example 2: Build Tools Only for CI/CD

```bash
az deployment group create \
  --resource-group rg-devops \
  --template-file bicep/vmss-infrastructure.bicep \
  --parameters microsoftImageType=vs2022-buildtools \
  --parameters vmSize=Standard_D2s_v3 \
  --parameters instanceCount=2 \
  --parameters azureDevOpsUrl=https://dev.azure.com/myorg \
  --parameters azureDevOpsPat=<your-pat> \
  --parameters agentPoolName=BuildTools-Pool \
  --parameters adminPassword=<secure-password>
```

### Example 3: Existing vWAN Network Integration

```bash
az deployment group create \
  --resource-group rg-devops \
  --template-file bicep/vmss-infrastructure.bicep \
  --parameters microsoftImageType=vs2022-enterprise \
  --parameters useExistingVnet=true \
  --parameters existingVnetResourceGroup=rg-network \
  --parameters existingVnetName=vnet-hub \
  --parameters existingSubnetName=subnet-devops \
  --parameters azureDevOpsUrl=https://dev.azure.com/myorg \
  --parameters azureDevOpsPat=<your-pat> \
  --parameters adminPassword=<secure-password>
```

## 🔧 Advanced Configuration

### Custom Package Installation

The template supports installing additional packages via Chocolatey:

```powershell
# In the PowerShell script, packages are installed like:
$ChocoPackages = @("nodejs", "python", "terraform", "docker-desktop")
$ChocoPackageParams = @{
    "nodejs" = "--version=18.17.0"
    "python" = "--version=3.11.0"
}
```

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

### Network Security Customization

```bicep
// Add custom NSG rules
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

## 🔍 Troubleshooting

### Common Issues

#### 1. Marketplace Terms Not Accepted
```
Error: The subscription is not registered for the offer
```
**Solution**: Accept marketplace terms using the Azure CLI commands above.

#### 2. Agent Registration Fails
```
Error: Failed to configure agent
```
**Solutions**:
- Verify Azure DevOps URL format
- Check PAT token permissions (Agent Pools: read, manage)
- Ensure agent pool exists
- Check network connectivity through Azure Firewall

#### 3. Custom Package Installation Fails
```
Warning: Failed to install package via Chocolatey
```
**Solutions**:
- Check internet connectivity through Azure Firewall
- Verify Chocolatey installation
- Check package name and version
- Review installation logs at `C:\temp\devops-agent-config.log`

#### 4. Network Connectivity Issues
```
Error: Cannot reach Azure DevOps services
```
**Solutions**:
- Verify Azure Firewall rules allow outbound HTTPS (443) to Azure DevOps
- Check NSG rules allow VirtualNetwork traffic
- Verify subnet routing to Azure Firewall
- Test connectivity: `Test-NetConnection dev.azure.com -Port 443`

### Debugging Commands

```bash
# Check VMSS status
az vmss show --resource-group rg-devops --name vmss-devops-agents

# Check instances
az vmss list-instances --resource-group rg-devops --name vmss-devops-agents

# Check auto-scale settings
az monitor autoscale show --resource-group rg-devops --name vmss-devops-agents-autoscale

# View VM extension logs
az vmss extension show \
  --resource-group rg-devops \
  --vmss-name vmss-devops-agents \
  --name ConfigureDevOpsAgent
```

### Log Files

- **Agent Configuration**: `C:\temp\devops-agent-config.log`
- **Agent Summary**: `C:\temp\agent-config-summary.txt`
- **Agent Service**: `C:\agent\_diag\Agent_*.log`
- **Chocolatey**: `C:\ProgramData\chocolatey\logs\chocolatey.log`

## 🔐 Security Considerations

### Network Security
- All VMs use private IP addresses only
- Network Security Groups restrict traffic to VirtualNetwork scope
- Azure Firewall provides secure outbound connectivity
- No direct internet access to VMs

### Identity and Access
- Use Azure Key Vault for storing PAT tokens
- Implement least-privilege access principles
- Rotate Personal Access Tokens regularly
- Consider using Managed Identity where possible

### Monitoring and Compliance
- Enable Azure Monitor for VM insights
- Set up alerts for security events
- Monitor agent pool usage and performance
- Implement backup strategies for critical data

## 💰 Cost Optimization

### Right-sizing Strategies
- Start with smaller VM sizes (`Standard_D2s_v3`) for build tools
- Use larger sizes (`Standard_D4s_v3`) only for full development environments
- Implement auto-scaling to optimize costs
- Consider Azure Reserved Instances for predictable workloads

### Storage Optimization
- Use Standard SSD for non-critical workloads
- Implement lifecycle policies for temporary files
- Monitor storage usage and clean up regularly

### Scheduling
- Scale down during off-hours using Azure Automation
- Use spot instances for non-critical builds
- Monitor and optimize based on build patterns

## 📚 Documentation

- [Deployment Guide](docs/DEPLOYMENT-GUIDE.md) - Step-by-step deployment instructions
- [Troubleshooting Guide](docs/TROUBLESHOOTING.md) - Common issues and solutions
- [Microsoft Images Guide](README-Microsoft-Images.md) - Detailed image information
- [Architecture Guide](docs/ARCHITECTURE.md) - Detailed architecture documentation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests and documentation
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏷️ Version History

### Version 2.0.0 (Current)
- **Microsoft Prebuilt Images**: Support for VS 2022/2019 and Build Tools
- **Enhanced Security**: Private IP only with vWAN integration
- **Chocolatey Integration**: Custom package installation support
- **Simplified Configuration**: Reduced complexity with prebuilt images
- **Improved Documentation**: Comprehensive guides and examples

### Version 1.0.0
- Initial release with custom image support
- Basic Azure DevOps agent automation
- Windows Server 2022 support
- Auto-scaling configuration

---

**🚀 Ready to deploy scalable, secure Azure DevOps build agents? Start with the [Deployment Guide](docs/DEPLOYMENT-GUIDE.md)!**

