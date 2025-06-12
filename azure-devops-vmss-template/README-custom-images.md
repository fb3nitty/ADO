# Azure DevOps VMSS with Custom Runner Images

This guide explains how to use the enhanced Bicep template that supports both marketplace images and custom Azure DevOps runner images for faster deployment and better consistency.

## Overview

The template now supports two deployment approaches:

1. **Marketplace Images** (Traditional): Uses Windows Server base image with PowerShell script installation
2. **Custom Images** (Recommended): Uses pre-built Azure DevOps runner images for faster deployment

## Custom Image Benefits

- **Faster Deployment**: No need to install and configure agents during VM startup
- **Consistency**: All VMs use identical, tested configurations
- **Reliability**: Reduces deployment failures from network issues during agent installation
- **Customization**: Include additional tools, configurations, and dependencies
- **Security**: Pre-hardened images with security configurations

## Configuration Options

### Using Marketplace Images (Default)

```json
{
  "useCustomImage": { "value": false },
  "installDevOpsAgent": { "value": true },
  "azureDevOpsUrl": { "value": "https://dev.azure.com/your-organization" }
}
```

### Using Shared Image Gallery Custom Images

```json
{
  "useCustomImage": { "value": true },
  "customImageType": { "value": "sharedGallery" },
  "customImageResourceId": { 
    "value": "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-images/providers/Microsoft.Compute/galleries/myDevOpsGallery/images/windows-devops-agent/versions/1.0.0" 
  },
  "installDevOpsAgent": { "value": false }
}
```

### Using Managed Images

```json
{
  "useCustomImage": { "value": true },
  "customImageType": { "value": "managedImage" },
  "customImageResourceId": { 
    "value": "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-images/providers/Microsoft.Compute/images/devops-agent-image" 
  },
  "installDevOpsAgent": { "value": false }
}
```

## Creating Custom Azure DevOps Runner Images

### Method 1: Using Azure VM Image Builder (Recommended)

Azure VM Image Builder provides a declarative approach to create custom images.

#### 1. Create Image Builder Template

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-05-01/deploymentTemplate.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "imageTemplateName": {
      "type": "string",
      "defaultValue": "devops-agent-template"
    },
    "galleryName": {
      "type": "string"
    },
    "imageDefinitionName": {
      "type": "string",
      "defaultValue": "windows-devops-agent"
    }
  },
  "resources": [
    {
      "type": "Microsoft.VirtualMachineImages/imageTemplates",
      "apiVersion": "2022-02-14",
      "name": "[parameters('imageTemplateName')]",
      "location": "[resourceGroup().location]",
      "properties": {
        "source": {
          "type": "PlatformImage",
          "publisher": "MicrosoftWindowsServer",
          "offer": "WindowsServer",
          "sku": "2022-datacenter-azure-edition",
          "version": "latest"
        },
        "customize": [
          {
            "type": "PowerShell",
            "name": "InstallChocolatey",
            "inline": [
              "Set-ExecutionPolicy Bypass -Scope Process -Force",
              "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072",
              "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))"
            ]
          },
          {
            "type": "PowerShell",
            "name": "InstallBuildTools",
            "inline": [
              "choco install git -y",
              "choco install nodejs -y",
              "choco install dotnet-sdk -y",
              "choco install azure-cli -y",
              "choco install docker-desktop -y"
            ]
          },
          {
            "type": "File",
            "name": "DownloadAgentScript",
            "sourceUri": "https://raw.githubusercontent.com/your-repo/azure-devops-vmss-template/main/scripts/install-devops-agent.ps1",
            "destination": "C:\\Scripts\\install-devops-agent.ps1"
          },
          {
            "type": "PowerShell",
            "name": "PrepareAgentInstallation",
            "inline": [
              "New-Item -Path 'C:\\Scripts' -ItemType Directory -Force",
              "# Download and prepare Azure DevOps agent but don't configure it yet",
              "Invoke-WebRequest -Uri 'https://vstsagentpackage.azureedge.net/agent/3.232.0/vsts-agent-win-x64-3.232.0.zip' -OutFile 'C:\\Scripts\\agent.zip'",
              "Expand-Archive -Path 'C:\\Scripts\\agent.zip' -DestinationPath 'C:\\agent' -Force",
              "# Create startup script for agent configuration",
              "@'",
              "# This script will be run on first boot to configure the agent",
              "param(",
              "    [string]$AzureDevOpsUrl,",
              "    [string]$PersonalAccessToken,",
              "    [string]$AgentPool = 'Default',",
              "    [string]$AgentName = $env:COMPUTERNAME",
              ")",
              "cd C:\\agent",
              ".\\config.cmd --unattended --url $AzureDevOpsUrl --auth pat --token $PersonalAccessToken --pool $AgentPool --agent $AgentName --runAsService",
              "'@ | Out-File -FilePath 'C:\\Scripts\\configure-agent.ps1' -Encoding UTF8"
            ]
          },
          {
            "type": "WindowsRestart",
            "restartCheckCommand": "echo Azure-Image-Builder-Restarted-the-VM > c:\\buildArtifacts\\azureImageBuilderRestart.txt",
            "restartTimeout": "5m"
          }
        ],
        "distribute": [
          {
            "type": "SharedImage",
            "galleryImageId": "[concat('/subscriptions/', subscription().subscriptionId, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Compute/galleries/', parameters('galleryName'), '/images/', parameters('imageDefinitionName'))]",
            "runOutputName": "aibCustomWinManaged",
            "replicationRegions": [
              "[resourceGroup().location]"
            ]
          }
        ],
        "vmProfile": {
          "vmSize": "Standard_D2s_v3"
        }
      }
    }
  ]
}
```

#### 2. Build the Image

```bash
# Create resource group for images
az group create --name rg-devops-images --location eastus

# Create Azure Compute Gallery
az sig create --resource-group rg-devops-images --gallery-name myDevOpsGallery

# Create image definition
az sig image-definition create \
  --resource-group rg-devops-images \
  --gallery-name myDevOpsGallery \
  --gallery-image-definition windows-devops-agent \
  --publisher MyCompany \
  --offer DevOpsAgents \
  --sku WindowsServer2022 \
  --os-type Windows \
  --os-state Generalized

# Deploy the image builder template
az deployment group create \
  --resource-group rg-devops-images \
  --template-file imagebuilder-template.json \
  --parameters galleryName=myDevOpsGallery

# Start the image build
az image builder run --name devops-agent-template --resource-group rg-devops-images
```

### Method 2: Manual VM Creation and Sysprep

#### 1. Create Base VM

```bash
# Create VM from marketplace image
az vm create \
  --resource-group rg-devops-images \
  --name vm-devops-base \
  --image Win2022Datacenter \
  --admin-username azureuser \
  --admin-password 'YourSecurePassword123!' \
  --size Standard_D2s_v3
```

#### 2. Configure the VM

1. RDP to the VM
2. Install required software:
   - Git
   - Node.js
   - .NET SDK
   - Azure CLI
   - Docker Desktop
   - Visual Studio Build Tools
   - Any other required tools

3. Download and prepare Azure DevOps agent:
```powershell
# Create agent directory
New-Item -Path 'C:\agent' -ItemType Directory -Force

# Download agent
Invoke-WebRequest -Uri 'https://vstsagentpackage.azureedge.net/agent/3.232.0/vsts-agent-win-x64-3.232.0.zip' -OutFile 'C:\temp\agent.zip'
Expand-Archive -Path 'C:\temp\agent.zip' -DestinationPath 'C:\agent' -Force

# Create configuration script for first boot
@'
param(
    [string]$AzureDevOpsUrl,
    [string]$PersonalAccessToken,
    [string]$AgentPool = "Default",
    [string]$AgentName = $env:COMPUTERNAME
)
cd C:\agent
.\config.cmd --unattended --url $AzureDevOpsUrl --auth pat --token $PersonalAccessToken --pool $AgentPool --agent $AgentName --runAsService
'@ | Out-File -FilePath 'C:\Scripts\configure-agent.ps1' -Encoding UTF8
```

#### 3. Sysprep and Capture

```powershell
# Run Sysprep
C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown
```

#### 4. Create Managed Image

```bash
# Deallocate and generalize VM
az vm deallocate --resource-group rg-devops-images --name vm-devops-base
az vm generalize --resource-group rg-devops-images --name vm-devops-base

# Create managed image
az image create \
  --resource-group rg-devops-images \
  --name devops-agent-image \
  --source vm-devops-base
```

## Best Practices for Custom Images

### 1. Image Versioning Strategy

- Use semantic versioning (e.g., 1.0.0, 1.1.0, 2.0.0)
- Tag images with build date and tools versions
- Maintain multiple versions for rollback capability

```bash
# Example versioning
az sig image-version create \
  --resource-group rg-devops-images \
  --gallery-name myDevOpsGallery \
  --gallery-image-definition windows-devops-agent \
  --gallery-image-version 1.2.0 \
  --target-regions eastus=1 westus2=1 \
  --replica-count 2
```

### 2. Automated Image Updates

Create a pipeline to automatically update images:

```yaml
# azure-pipelines-image-update.yml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

steps:
- task: AzureCLI@2
  displayName: 'Build Updated Image'
  inputs:
    azureSubscription: 'your-service-connection'
    scriptType: 'bash'
    scriptLocation: 'inlineScript'
    inlineScript: |
      # Update image builder template with latest tools
      az image builder run --name devops-agent-template --resource-group rg-devops-images
      
      # Wait for completion
      az image builder show-runs --name devops-agent-template --resource-group rg-devops-images
```

### 3. Security Hardening

- Apply Windows security baselines
- Install latest security updates
- Configure Windows Defender
- Remove unnecessary features and services
- Implement least privilege principles

### 4. Monitoring and Maintenance

- Set up alerts for image build failures
- Monitor image usage and performance
- Regular security scanning of images
- Automated cleanup of old image versions

```bash
# Cleanup old image versions (keep last 3)
az sig image-version list \
  --resource-group rg-devops-images \
  --gallery-name myDevOpsGallery \
  --gallery-image-definition windows-devops-agent \
  --query '[3:].name' -o tsv | \
  xargs -I {} az sig image-version delete \
    --resource-group rg-devops-images \
    --gallery-name myDevOpsGallery \
    --gallery-image-definition windows-devops-agent \
    --gallery-image-version {}
```

## Referencing Marketplace Images with Build Tools

For scenarios where you want to use marketplace images with pre-installed development tools:

### Visual Studio Build Tools Images

```json
{
  "imageReference": {
    "publisher": "MicrosoftVisualStudio",
    "offer": "visualstudio2022",
    "sku": "vs-2022-ent-latest-ws2022",
    "version": "latest"
  }
}
```

### Windows Server with Containers

```json
{
  "imageReference": {
    "publisher": "MicrosoftWindowsServer",
    "offer": "WindowsServer",
    "sku": "2022-datacenter-azure-edition-core-smalldisk",
    "version": "latest"
  }
}
```

### SQL Server Developer Edition

```json
{
  "imageReference": {
    "publisher": "MicrosoftSQLServer",
    "offer": "sql2022-ws2022",
    "sku": "sqldev-gen2",
    "version": "latest"
  }
}
```

## Troubleshooting

### Common Issues

1. **Image not found**: Verify the resource ID format and permissions
2. **Agent configuration fails**: Check network connectivity and PAT permissions
3. **Slow deployment**: Ensure custom images are in the same region as VMSS
4. **Build failures**: Check Image Builder logs and network access

### Debugging Commands

```bash
# Check image builder status
az image builder show --name devops-agent-template --resource-group rg-devops-images

# View build logs
az image builder show-runs --name devops-agent-template --resource-group rg-devops-images

# Test VMSS deployment
az vmss show --name vmss-devops-agents --resource-group rg-devops

# Check VM instances
az vmss list-instances --name vmss-devops-agents --resource-group rg-devops
```

## Cost Optimization

- Use Azure Spot instances for non-critical workloads
- Implement auto-scaling based on build queue depth
- Use smaller VM sizes for lightweight builds
- Schedule scale-down during off-hours
- Monitor and optimize storage costs for images

## Security Considerations

- Store PAT tokens in Azure Key Vault
- Use managed identities where possible
- Implement network security groups and private endpoints
- Regular security updates for custom images
- Audit and monitor image access

## Next Steps

1. Create your first custom image using Azure VM Image Builder
2. Test deployment with the updated Bicep template
3. Implement automated image update pipeline
4. Set up monitoring and alerting
5. Optimize for your specific build requirements
