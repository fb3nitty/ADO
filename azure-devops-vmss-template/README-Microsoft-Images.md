
# Azure DevOps VMSS with Microsoft Prebuilt Runner Images

This template has been updated to use Microsoft's official prebuilt runner images from the Azure Marketplace instead of custom images. These images come with development tools pre-installed, significantly reducing deployment time and complexity.

## Available Microsoft Prebuilt Images

### 1. Visual Studio 2022 Enterprise (`vs2022-enterprise`)
**Recommended for full development environments**

- **Publisher**: `MicrosoftVisualStudio`
- **Offer**: `visualstudio2022`
- **SKU**: `vs-2022-ent-latest-ws2022`
- **Base OS**: Windows Server 2022

**Included Tools:**
- Visual Studio 2022 Enterprise (latest version)
- .NET 6, 7, and 8 SDKs
- .NET Framework 4.8
- Azure CLI
- Git for Windows
- MSBuild
- NuGet Package Manager
- PowerShell Core
- Windows SDK
- Azure PowerShell Module
- GitHub CLI

**Recommended VM Size**: `Standard_D4s_v3` or larger

### 2. Visual Studio 2022 Build Tools (`vs2022-buildtools`)
**Recommended for CI/CD build agents**

- **Publisher**: `MicrosoftVisualStudio`
- **Offer**: `visualstudio2022`
- **SKU**: `vs-2022-buildtools-latest-ws2022`
- **Base OS**: Windows Server 2022

**Included Tools:**
- MSBuild (latest version)
- .NET SDKs (6, 7, 8)
- C++ Build Tools
- Windows SDK
- NuGet Package Manager
- Git (minimal installation)
- PowerShell

**Recommended VM Size**: `Standard_D2s_v3` or larger

### 3. Visual Studio 2019 Enterprise (`vs2019-enterprise`)
**For legacy applications requiring VS2019**

- **Publisher**: `MicrosoftVisualStudio`
- **Offer**: `visualstudio2019`
- **SKU**: `vs-2019-ent-latest-ws2019`
- **Base OS**: Windows Server 2019

**Included Tools:**
- Visual Studio 2019 Enterprise
- .NET Framework 4.8
- .NET Core 3.1
- Azure CLI
- Git for Windows
- MSBuild

**Recommended VM Size**: `Standard_D4s_v3` or larger

### 4. Windows Server 2022 (`windowsserver-2022`)
**For custom tooling scenarios**

- **Publisher**: `MicrosoftWindowsServer`
- **Offer**: `WindowsServer`
- **SKU**: `2022-datacenter-azure-edition`
- **Base OS**: Windows Server 2022

**Included Tools:**
- Windows Server 2022 Datacenter
- PowerShell 5.1
- Basic Windows features
- IIS (can be enabled)

**Recommended VM Size**: `Standard_D2s_v3` or larger

## Key Changes from Custom Images

### Simplified Parameters
The template now uses simplified parameters focused on Microsoft's prebuilt images:

```json
{
  "microsoftImageType": {
    "value": "vs2022-enterprise"
  },
  "configureDevOpsAgent": {
    "value": true
  }
}
```

### Removed Complex Custom Image Parameters
- `useCustomImage`
- `customImageType`
- `customImageResourceId`
- `sharedImageGalleryName`
- `imageDefinitionName`
- `imageVersion`
- `installDevOpsAgent`

### Simplified PowerShell Script
The PowerShell script (`configure-devops-agent.ps1`) is now much simpler since development tools are pre-installed:
- No .NET SDK installation
- No Chocolatey installation
- No Visual Studio installation
- No Windows Features installation
- Focus only on Azure DevOps agent configuration

## Marketplace Terms Acceptance

**IMPORTANT**: Visual Studio images require accepting marketplace terms before deployment.

### Accept Terms via Azure CLI
```bash
# For Visual Studio 2022 Enterprise
az vm image terms accept --publisher MicrosoftVisualStudio --offer visualstudio2022 --plan vs-2022-ent-latest-ws2022

# For Visual Studio 2022 Build Tools
az vm image terms accept --publisher MicrosoftVisualStudio --offer visualstudio2022 --plan vs-2022-buildtools-latest-ws2022

# For Visual Studio 2019 Enterprise
az vm image terms accept --publisher MicrosoftVisualStudio --offer visualstudio2019 --plan vs-2019-ent-latest-ws2019
```

### Accept Terms via PowerShell
```powershell
# For Visual Studio 2022 Enterprise
Set-AzMarketplaceTerms -Publisher "MicrosoftVisualStudio" -Product "visualstudio2022" -Name "vs-2022-ent-latest-ws2022" -Accept

# For Visual Studio 2022 Build Tools
Set-AzMarketplaceTerms -Publisher "MicrosoftVisualStudio" -Product "visualstudio2022" -Name "vs-2022-buildtools-latest-ws2022" -Accept

# For Visual Studio 2019 Enterprise
Set-AzMarketplaceTerms -Publisher "MicrosoftVisualStudio" -Product "visualstudio2019" -Name "vs-2019-ent-latest-ws2019" -Accept
```

## Deployment Examples

### Example 1: Visual Studio 2022 Enterprise Environment
```bash
az deployment group create \
  --resource-group rg-devops \
  --template-file vmss-infrastructure.bicep \
  --parameters microsoftImageType=vs2022-enterprise \
  --parameters vmSize=Standard_D4s_v3 \
  --parameters azureDevOpsUrl=https://dev.azure.com/myorg \
  --parameters azureDevOpsPat=<your-pat> \
  --parameters agentPoolName=VS2022-Pool
```

### Example 2: Build Tools Only Environment
```bash
az deployment group create \
  --resource-group rg-devops \
  --template-file vmss-infrastructure.bicep \
  --parameters microsoftImageType=vs2022-buildtools \
  --parameters vmSize=Standard_D2s_v3 \
  --parameters azureDevOpsUrl=https://dev.azure.com/myorg \
  --parameters azureDevOpsPat=<your-pat> \
  --parameters agentPoolName=BuildTools-Pool
```

### Example 3: Legacy VS2019 Environment
```bash
az deployment group create \
  --resource-group rg-devops \
  --template-file vmss-infrastructure.bicep \
  --parameters microsoftImageType=vs2019-enterprise \
  --parameters vmSize=Standard_D4s_v3 \
  --parameters azureDevOpsUrl=https://dev.azure.com/myorg \
  --parameters azureDevOpsPat=<your-pat> \
  --parameters agentPoolName=VS2019-Pool
```

## Benefits of Microsoft Prebuilt Images

### 1. **Faster Deployment**
- No need to install Visual Studio, .NET SDKs, or development tools
- Reduced deployment time from 30-45 minutes to 5-10 minutes
- Pre-configured development environment

### 2. **Consistency**
- Microsoft-maintained images with regular updates
- Consistent tool versions across all instances
- Tested and validated configurations

### 3. **Reduced Complexity**
- Simplified Bicep template
- Minimal PowerShell script
- Fewer parameters to configure

### 4. **Better Support**
- Microsoft-supported images
- Regular security updates
- Documented configurations

### 5. **Cost Optimization**
- Faster scaling due to quicker deployment
- Reduced compute time during provisioning
- Lower operational overhead

## Migration from Custom Images

If you're migrating from the previous custom image approach:

1. **Accept marketplace terms** for your chosen Visual Studio image
2. **Update parameters.json** to use `microsoftImageType` instead of custom image parameters
3. **Update any CI/CD pipelines** to reference the new parameter structure
4. **Test deployment** in a development environment first
5. **Update documentation** to reflect the new image types

## Troubleshooting

### Common Issues

1. **Marketplace Terms Not Accepted**
   ```
   Error: The subscription is not registered for the offer
   ```
   **Solution**: Accept marketplace terms using Azure CLI or PowerShell commands above

2. **Agent Configuration Fails**
   ```
   Error: Failed to configure agent
   ```
   **Solution**: Verify Azure DevOps URL and PAT token permissions

3. **VM Size Too Small**
   ```
   Warning: Performance issues with Visual Studio
   ```
   **Solution**: Use recommended VM sizes (D4s_v3 for VS Enterprise, D2s_v3 for Build Tools)

### Verification Steps

1. **Check VM Scale Set Status**
   ```bash
   az vmss list-instances --resource-group rg-devops --name vmss-devops-agents
   ```

2. **Verify Agent Registration**
   - Check Azure DevOps organization → Project Settings → Agent pools
   - Verify agents appear as "Online"

3. **Test Build Capability**
   - Run a simple build pipeline
   - Verify tools are available (dotnet, msbuild, git)

## Support and Updates

- **Image Updates**: Microsoft regularly updates these images with latest tools and security patches
- **Version Management**: Use `latest` version for automatic updates, or pin to specific versions for consistency
- **Support**: Contact Microsoft Azure Support for image-related issues
- **Documentation**: Refer to [Microsoft Visual Studio VM documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/using-visual-studio-vm)
