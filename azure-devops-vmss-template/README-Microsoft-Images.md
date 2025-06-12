
# Microsoft Prebuilt Runner Images Guide

This guide provides comprehensive information about using Microsoft's prebuilt runner images with the Azure DevOps VMSS template. These images come with development tools pre-installed, significantly reducing deployment time and complexity while providing enterprise-grade development environments.

## 🖥️ Available Microsoft Prebuilt Images

### 1. Visual Studio 2022 Enterprise (`vs2022-enterprise`)
**Recommended for full development environments**

- **Publisher**: `MicrosoftVisualStudio`
- **Offer**: `visualstudio2022`
- **SKU**: `vs-2022-ent-latest-ws2022`
- **Base OS**: Windows Server 2022 Datacenter Azure Edition
- **Recommended VM Size**: `Standard_D4s_v3` or larger (4 vCPUs, 16 GB RAM)

#### Pre-installed Development Tools
- **Visual Studio 2022 Enterprise** (latest version with all workloads)
- **.NET SDKs**: 6.0, 7.0, 8.0 (latest LTS and current versions)
- **.NET Framework**: 4.8 and earlier versions
- **Azure CLI**: Latest version with Azure PowerShell module
- **Git for Windows**: Latest version with Git LFS support
- **MSBuild**: Latest version with build tools
- **NuGet Package Manager**: Latest version
- **PowerShell Core**: 7.x with Azure modules
- **Windows SDK**: Latest version for Windows development
- **GitHub CLI**: For GitHub integration
- **Docker Desktop**: Container development support
- **Node.js**: Latest LTS version with npm
- **Python**: Latest stable version with pip

#### Development Workloads Included
- ASP.NET and web development
- Azure development
- .NET desktop development
- .NET Multi-platform App UI development
- Game development with Unity
- Mobile development with .NET
- Office/SharePoint development
- Visual Studio extension development

#### Use Cases
- Full-stack web development
- Enterprise application development
- Azure cloud development
- Cross-platform development
- Game development
- Mobile app development

### 2. Visual Studio 2022 Build Tools (`vs2022-buildtools`)
**Recommended for CI/CD build agents**

- **Publisher**: `MicrosoftVisualStudio`
- **Offer**: `visualstudio2022`
- **SKU**: `vs-2022-buildtools-latest-ws2022`
- **Base OS**: Windows Server 2022 Datacenter Azure Edition
- **Recommended VM Size**: `Standard_D2s_v3` or larger (2 vCPUs, 8 GB RAM)

#### Pre-installed Build Tools
- **MSBuild**: Latest version with all build targets
- **.NET SDKs**: 6.0, 7.0, 8.0 (build-focused installation)
- **C++ Build Tools**: MSVC compiler and libraries
- **Windows SDK**: For Windows application builds
- **NuGet Package Manager**: Package restoration and management
- **Git**: Minimal installation for source control
- **PowerShell**: Core and Windows PowerShell
- **Azure CLI**: For Azure resource management
- **Test Agent**: For automated testing

#### Build Capabilities
- .NET applications (all versions)
- C++ applications and libraries
- Universal Windows Platform (UWP) apps
- Windows desktop applications
- Web applications and APIs
- NuGet package creation
- Automated testing execution

#### Use Cases
- Continuous Integration (CI) builds
- Automated testing
- Package creation and publishing
- Lightweight build environments
- Cost-optimized build agents

### 3. Visual Studio 2019 Enterprise (`vs2019-enterprise`)
**For legacy applications requiring VS2019**

- **Publisher**: `MicrosoftVisualStudio`
- **Offer**: `visualstudio2019`
- **SKU**: `vs-2019-ent-latest-ws2019`
- **Base OS**: Windows Server 2019 Datacenter
- **Recommended VM Size**: `Standard_D4s_v3` or larger (4 vCPUs, 16 GB RAM)

#### Pre-installed Development Tools
- **Visual Studio 2019 Enterprise** (latest update)
- **.NET Framework**: 4.8 and earlier versions
- **.NET Core**: 3.1 LTS and earlier versions
- **Azure CLI**: Compatible version
- **Git for Windows**: Latest compatible version
- **MSBuild**: VS2019 compatible version
- **PowerShell**: Windows PowerShell 5.1
- **SQL Server Data Tools**: Database development
- **Team Foundation Server**: On-premises DevOps tools

#### Legacy Support Features
- .NET Framework applications
- Legacy web applications (Web Forms, MVC 5)
- Windows Forms applications
- WPF applications
- Silverlight applications (limited support)
- SharePoint 2019 development
- SQL Server 2019 development

#### Use Cases
- Legacy application maintenance
- .NET Framework applications
- SharePoint 2019 development
- SQL Server 2019 projects
- Migration projects from older versions

### 4. Windows Server 2022 (`windowsserver-2022`)
**For custom tooling scenarios**

- **Publisher**: `MicrosoftWindowsServer`
- **Offer**: `WindowsServer`
- **SKU**: `2022-datacenter-azure-edition`
- **Base OS**: Windows Server 2022 Datacenter Azure Edition
- **Recommended VM Size**: `Standard_D2s_v3` or larger (2 vCPUs, 8 GB RAM)

#### Pre-installed Base Components
- **Windows Server 2022**: Latest updates and security patches
- **PowerShell 5.1**: Windows PowerShell
- **Internet Information Services (IIS)**: Web server (can be enabled)
- **Windows Features**: Available for installation as needed
- **.NET Framework 4.8**: Pre-installed
- **Windows Defender**: Antivirus and security

#### Customization Capabilities
- Install any development tools via Chocolatey
- Configure custom build environments
- Install specific versions of tools
- Create specialized build agents
- Support for non-Microsoft development stacks

#### Use Cases
- Custom development environments
- Non-Microsoft technology stacks
- Specialized build requirements
- Legacy tool support
- Highly customized configurations

## 🚀 Deployment Configuration

### Marketplace Terms Acceptance

**CRITICAL**: Visual Studio images require accepting marketplace terms before deployment.

#### Azure CLI Commands
```bash
# Visual Studio 2022 Enterprise
az vm image terms accept \
  --publisher MicrosoftVisualStudio \
  --offer visualstudio2022 \
  --plan vs-2022-ent-latest-ws2022

# Visual Studio 2022 Build Tools
az vm image terms accept \
  --publisher MicrosoftVisualStudio \
  --offer visualstudio2022 \
  --plan vs-2022-buildtools-latest-ws2022

# Visual Studio 2019 Enterprise
az vm image terms accept \
  --publisher MicrosoftVisualStudio \
  --offer visualstudio2019 \
  --plan vs-2019-ent-latest-ws2019

# Verify terms acceptance
az vm image terms show \
  --publisher MicrosoftVisualStudio \
  --offer visualstudio2022 \
  --plan vs-2022-ent-latest-ws2022
```

#### Azure PowerShell Commands
```powershell
# Visual Studio 2022 Enterprise
Set-AzMarketplaceTerms \
  -Publisher "MicrosoftVisualStudio" \
  -Product "visualstudio2022" \
  -Name "vs-2022-ent-latest-ws2022" \
  -Accept

# Visual Studio 2022 Build Tools
Set-AzMarketplaceTerms \
  -Publisher "MicrosoftVisualStudio" \
  -Product "visualstudio2022" \
  -Name "vs-2022-buildtools-latest-ws2022" \
  -Accept

# Visual Studio 2019 Enterprise
Set-AzMarketplaceTerms \
  -Publisher "MicrosoftVisualStudio" \
  -Product "visualstudio2019" \
  -Name "vs-2019-ent-latest-ws2019" \
  -Accept
```

### Template Configuration

#### Basic Configuration
```json
{
  "microsoftImageType": {
    "value": "vs2022-enterprise"
  },
  "vmSize": {
    "value": "Standard_D4s_v3"
  },
  "instanceCount": {
    "value": 3
  },
  "configureDevOpsAgent": {
    "value": true
  }
}
```

#### Advanced Configuration with Chocolatey
```json
{
  "microsoftImageType": {
    "value": "vs2022-buildtools"
  },
  "vmSize": {
    "value": "Standard_D2s_v3"
  },
  "configureDevOpsAgent": {
    "value": true
  },
  "chocoPackages": {
    "value": ["nodejs", "python", "terraform"]
  },
  "chocoPackageParams": {
    "value": {
      "nodejs": "--version=18.17.0",
      "python": "--version=3.11.0"
    }
  }
}
```

## 📋 Deployment Examples

### Example 1: Full Development Environment
**Scenario**: Complete development environment for enterprise applications

```bash
az deployment group create \
  --resource-group rg-devops-development \
  --template-file bicep/vmss-infrastructure.bicep \
  --parameters microsoftImageType=vs2022-enterprise \
  --parameters vmSize=Standard_D4s_v3 \
  --parameters instanceCount=2 \
  --parameters azureDevOpsUrl=https://dev.azure.com/myorg \
  --parameters azureDevOpsPat=<your-pat> \
  --parameters agentPoolName=Development-Pool \
  --parameters adminPassword=<secure-password>
```

**Result**: 2 instances with Visual Studio 2022 Enterprise, suitable for full development work.

### Example 2: CI/CD Build Farm
**Scenario**: High-throughput build environment for continuous integration

```bash
az deployment group create \
  --resource-group rg-devops-cicd \
  --template-file bicep/vmss-infrastructure.bicep \
  --parameters microsoftImageType=vs2022-buildtools \
  --parameters vmSize=Standard_D2s_v3 \
  --parameters instanceCount=5 \
  --parameters azureDevOpsUrl=https://dev.azure.com/myorg \
  --parameters azureDevOpsPat=<your-pat> \
  --parameters agentPoolName=BuildTools-Pool \
  --parameters adminPassword=<secure-password>
```

**Result**: 5 lightweight build agents optimized for CI/CD pipelines.

### Example 3: Legacy Application Support
**Scenario**: Support for .NET Framework and legacy applications

```bash
az deployment group create \
  --resource-group rg-devops-legacy \
  --template-file bicep/vmss-infrastructure.bicep \
  --parameters microsoftImageType=vs2019-enterprise \
  --parameters vmSize=Standard_D4s_v3 \
  --parameters instanceCount=2 \
  --parameters azureDevOpsUrl=https://dev.azure.com/myorg \
  --parameters azureDevOpsPat=<your-pat> \
  --parameters agentPoolName=Legacy-Pool \
  --parameters adminPassword=<secure-password>
```

**Result**: 2 instances with Visual Studio 2019 for legacy application development.

### Example 4: Custom Tooling Environment
**Scenario**: Specialized environment with custom tools via Chocolatey

```bash
az deployment group create \
  --resource-group rg-devops-custom \
  --template-file bicep/vmss-infrastructure.bicep \
  --parameters microsoftImageType=windowsserver-2022 \
  --parameters vmSize=Standard_D2s_v3 \
  --parameters instanceCount=3 \
  --parameters azureDevOpsUrl=https://dev.azure.com/myorg \
  --parameters azureDevOpsPat=<your-pat> \
  --parameters agentPoolName=Custom-Pool \
  --parameters adminPassword=<secure-password>
```

**PowerShell Configuration** (in the script):
```powershell
$ChocoPackages = @(
    "nodejs",
    "python",
    "docker-desktop",
    "terraform",
    "kubernetes-cli",
    "golang",
    "rust"
)
```

**Result**: 3 instances with Windows Server 2022 and custom development tools.

## 🍫 Chocolatey Integration

### Supported Packages

#### Development Languages
```powershell
$LanguagePackages = @(
    "nodejs",           # Node.js runtime and npm
    "python",           # Python interpreter and pip
    "golang",           # Go programming language
    "rust",             # Rust programming language
    "openjdk",          # OpenJDK Java runtime
    "ruby",             # Ruby programming language
    "php",              # PHP runtime
    "kotlin"            # Kotlin programming language
)
```

#### Development Tools
```powershell
$DevelopmentTools = @(
    "vscode",           # Visual Studio Code
    "notepadplusplus",  # Notepad++ text editor
    "postman",          # API testing tool
    "fiddler",          # HTTP debugging proxy
    "wireshark",        # Network protocol analyzer
    "sysinternals",     # Windows Sysinternals suite
    "7zip",             # File archiver
    "curl",             # Command-line HTTP client
    "wget"              # File downloader
)
```

#### Cloud and DevOps Tools
```powershell
$CloudDevOpsTools = @(
    "azure-cli",        # Azure Command Line Interface
    "awscli",           # AWS Command Line Interface
    "terraform",        # Infrastructure as Code
    "packer",           # Machine image builder
    "vault",            # HashiCorp Vault
    "consul",           # Service mesh solution
    "kubernetes-cli",   # kubectl for Kubernetes
    "helm",             # Kubernetes package manager
    "docker-desktop",   # Docker containerization
    "docker-compose"    # Docker multi-container apps
)
```

#### Database Tools
```powershell
$DatabaseTools = @(
    "sql-server-management-studio",  # SQL Server Management Studio
    "azure-data-studio",             # Azure Data Studio
    "mysql.workbench",               # MySQL Workbench
    "postgresql",                    # PostgreSQL database
    "mongodb",                       # MongoDB database
    "redis-64",                      # Redis cache
    "sqlite"                         # SQLite database
)
```

### Package Configuration Examples

#### Version-Specific Installation
```powershell
$ChocoPackageParams = @{
    "nodejs" = "--version=18.17.0"
    "python" = "--version=3.11.0"
    "terraform" = "--version=1.5.0"
    "docker-desktop" = "--version=4.21.0"
}
```

#### Custom Installation Parameters
```powershell
$ChocoPackageParams = @{
    "python" = "--version=3.11.0 --params '/InstallDir:C:\Python311'"
    "nodejs" = "--version=18.17.0 --params '/ADDLOCAL=ALL'"
    "docker-desktop" = "--params '/HyperV'"
}
```

### Package Installation Verification

The PowerShell script automatically verifies common package installations:

```powershell
# Verification examples included in the script
switch ($package.ToLower()) {
    "nodejs" {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) { Write-Host "Found Node.js: $nodeVersion" -ForegroundColor Green }
    }
    "python" {
        $pythonVersion = python --version 2>$null
        if ($pythonVersion) { Write-Host "Found Python: $pythonVersion" -ForegroundColor Green }
    }
    "terraform" {
        $terraformVersion = terraform --version 2>$null
        if ($terraformVersion) { Write-Host "Found Terraform: $($terraformVersion.Split("`n")[0])" -ForegroundColor Green }
    }
    "docker-desktop" {
        $dockerVersion = docker --version 2>$null
        if ($dockerVersion) { Write-Host "Found Docker: $dockerVersion" -ForegroundColor Green }
    }
}
```

## 🔧 Performance Optimization

### VM Size Recommendations

#### Development Workloads
| Workload Type | Recommended VM Size | vCPUs | RAM | Storage | Cost/Month* |
|---------------|-------------------|-------|-----|---------|-------------|
| Light Development | Standard_D2s_v3 | 2 | 8 GB | 16 GB SSD | ~$70 |
| Standard Development | Standard_D4s_v3 | 4 | 16 GB | 32 GB SSD | ~$140 |
| Heavy Development | Standard_D8s_v3 | 8 | 32 GB | 64 GB SSD | ~$280 |
| Enterprise Development | Standard_D16s_v3 | 16 | 64 GB | 128 GB SSD | ~$560 |

#### Build Workloads
| Build Type | Recommended VM Size | vCPUs | RAM | Parallel Builds | Cost/Month* |
|------------|-------------------|-------|-----|-----------------|-------------|
| Simple Builds | Standard_D2s_v3 | 2 | 8 GB | 1-2 | ~$70 |
| Standard Builds | Standard_D4s_v3 | 4 | 16 GB | 2-4 | ~$140 |
| Complex Builds | Standard_D8s_v3 | 8 | 32 GB | 4-8 | ~$280 |
| Enterprise Builds | Standard_D16s_v3 | 16 | 64 GB | 8-16 | ~$560 |

*Estimated costs for East US region, subject to change

### Auto-scaling Configuration

#### Development Environment Scaling
```bicep
// Conservative scaling for development
autoscaleSettings: {
  profiles: [
    {
      name: 'DevelopmentHours'
      capacity: {
        minimum: '1'
        maximum: '5'
        default: '2'
      }
      rules: [
        {
          metricTrigger: {
            metricName: 'Percentage CPU'
            threshold: 80
            timeWindow: 'PT10M'
          }
          scaleAction: {
            direction: 'Increase'
            value: '1'
            cooldown: 'PT10M'
          }
        }
      ]
    }
  ]
}
```

#### CI/CD Environment Scaling
```bicep
// Aggressive scaling for CI/CD
autoscaleSettings: {
  profiles: [
    {
      name: 'BuildHours'
      capacity: {
        minimum: '2'
        maximum: '20'
        default: '5'
      }
      rules: [
        {
          metricTrigger: {
            metricName: 'Percentage CPU'
            threshold: 70
            timeWindow: 'PT5M'
          }
          scaleAction: {
            direction: 'Increase'
            value: '2'
            cooldown: 'PT5M'
          }
        }
      ]
    }
  ]
}
```

## 🔍 Troubleshooting

### Common Issues and Solutions

#### 1. Marketplace Terms Not Accepted
**Error**: `The subscription is not registered for the offer`
**Solution**: Run the marketplace terms acceptance commands shown above.

#### 2. VM Size Insufficient for Visual Studio
**Error**: Visual Studio performance issues or installation failures
**Solution**: Use minimum recommended VM sizes (D4s_v3 for VS Enterprise, D2s_v3 for Build Tools).

#### 3. Agent Registration Fails
**Error**: Agents don't appear in Azure DevOps
**Solutions**:
- Verify PAT token permissions
- Check Azure DevOps URL format
- Ensure network connectivity through Azure Firewall
- Review agent configuration logs

#### 4. Chocolatey Package Installation Fails
**Error**: Custom packages fail to install
**Solutions**:
- Check internet connectivity through Azure Firewall
- Verify package names and versions
- Review Chocolatey logs
- Use alternative package sources if needed

### Diagnostic Commands

```bash
# Check VMSS status
az vmss show --resource-group <rg> --name <vmss-name> --query "provisioningState"

# Check agent configuration logs
az vmss run-command invoke \
  --resource-group <rg> \
  --name <vmss-name> \
  --command-id RunPowerShellScript \
  --instance-id 0 \
  --scripts "Get-Content C:\temp\devops-agent-config.log -Tail 50"

# Test network connectivity
az vmss run-command invoke \
  --resource-group <rg> \
  --name <vmss-name> \
  --command-id RunPowerShellScript \
  --instance-id 0 \
  --scripts "Test-NetConnection dev.azure.com -Port 443"

# Check installed tools
az vmss run-command invoke \
  --resource-group <rg> \
  --name <vmss-name> \
  --command-id RunPowerShellScript \
  --instance-id 0 \
  --scripts "dotnet --version; git --version; choco list --local-only"
```

## 💰 Cost Optimization

### Cost-Effective Strategies

#### 1. Right-sizing VMs
- Start with smaller VM sizes and scale up as needed
- Use Build Tools images for CI/CD (cheaper than full Visual Studio)
- Monitor CPU and memory usage to optimize sizing

#### 2. Auto-scaling Optimization
- Set appropriate minimum instances (1-2 for development, 2-3 for production)
- Configure aggressive scale-down policies during off-hours
- Use schedule-based scaling for predictable workloads

#### 3. Reserved Instances
- Purchase Azure Reserved Instances for baseline capacity
- Use spot instances for non-critical workloads
- Combine reserved and pay-as-you-go for optimal cost

#### 4. Storage Optimization
- Use Standard SSD for non-critical workloads
- Implement automated cleanup of build artifacts
- Monitor storage usage and optimize retention policies

### Cost Monitoring

```bash
# Set up cost alerts
az consumption budget create \
  --budget-name "DevOps-VMSS-Budget" \
  --amount 1000 \
  --time-grain Monthly \
  --time-period start-date=2024-01-01 \
  --resource-group <rg>

# Monitor costs
az consumption usage list \
  --start-date 2024-01-01 \
  --end-date 2024-01-31 \
  --resource-group <rg>
```

## 📚 Best Practices

### Image Selection Guidelines

1. **Use VS 2022 Enterprise** for full development environments requiring all Visual Studio features
2. **Use VS 2022 Build Tools** for CI/CD pipelines and automated builds
3. **Use VS 2019 Enterprise** only for legacy applications that require older tooling
4. **Use Windows Server 2022** for highly customized environments or non-Microsoft stacks

### Security Best Practices

1. **Keep Images Updated**: Microsoft regularly updates these images with security patches
2. **Use Private Networks**: Deploy in private subnets with Azure Firewall for outbound connectivity
3. **Implement RBAC**: Use role-based access control for agent pool management
4. **Secure Secrets**: Store PAT tokens and passwords in Azure Key Vault

### Performance Best Practices

1. **Monitor Resource Usage**: Set up alerts for CPU, memory, and disk usage
2. **Optimize Build Processes**: Use parallel builds and efficient build scripts
3. **Cache Dependencies**: Implement dependency caching to reduce build times
4. **Regular Maintenance**: Schedule regular cleanup of temporary files and logs

### Operational Best Practices

1. **Version Control**: Pin to specific image versions for consistency
2. **Testing**: Test new image versions in development before production deployment
3. **Monitoring**: Implement comprehensive monitoring and alerting
4. **Documentation**: Maintain documentation of customizations and configurations

---

This guide provides comprehensive information for successfully deploying and managing Microsoft prebuilt runner images in your Azure DevOps VMSS environment. For additional support, refer to the [Troubleshooting Guide](docs/TROUBLESHOOTING.md) and [Architecture Guide](docs/ARCHITECTURE.md).

