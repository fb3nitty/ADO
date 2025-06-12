
# Custom Images Guide (Legacy)

> **⚠️ NOTICE**: This guide covers the legacy custom image approach. The template now primarily uses **Microsoft Prebuilt Images** which are faster, more reliable, and easier to maintain. See [README-Microsoft-Images.md](README-Microsoft-Images.md) for the current recommended approach.

This guide explains how to create and use custom Azure DevOps runner images as an alternative to Microsoft prebuilt images. While custom images provide maximum flexibility, they require more maintenance and longer deployment times.

## 📋 Overview

Custom images allow you to:
- Pre-install specific tool versions
- Include proprietary software
- Create standardized environments
- Reduce agent startup time
- Implement custom security configurations

However, they also require:
- Image creation and maintenance
- Regular security updates
- Version management
- Additional storage costs

## 🏗️ Custom Image Creation Methods

### Method 1: Azure VM Image Builder (Recommended)

Azure VM Image Builder provides a declarative approach to create custom images with automated builds and updates.

#### 1.1 Create Image Builder Template

Create `imagebuilder-template.json`:

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
    },
    "imageVersion": {
      "type": "string",
      "defaultValue": "1.0.0"
    }
  },
  "variables": {
    "userAssignedIdentityName": "aibIdentity",
    "roleDefinitionName": "[guid(resourceGroup().id, 'aibRole')]"
  },
  "resources": [
    {
      "type": "Microsoft.ManagedIdentity/userAssignedIdentities",
      "apiVersion": "2018-11-30",
      "name": "[variables('userAssignedIdentityName')]",
      "location": "[resourceGroup().location]"
    },
    {
      "type": "Microsoft.Authorization/roleDefinitions",
      "apiVersion": "2018-07-01",
      "name": "[variables('roleDefinitionName')]",
      "properties": {
        "roleName": "Azure Image Builder Service Role",
        "description": "Custom role for Azure Image Builder",
        "permissions": [
          {
            "actions": [
              "Microsoft.Compute/galleries/read",
              "Microsoft.Compute/galleries/images/read",
              "Microsoft.Compute/galleries/images/versions/read",
              "Microsoft.Compute/galleries/images/versions/write",
              "Microsoft.Compute/images/write",
              "Microsoft.Compute/images/read",
              "Microsoft.Compute/images/delete"
            ]
          }
        ],
        "assignableScopes": [
          "[resourceGroup().id]"
        ]
      }
    },
    {
      "type": "Microsoft.VirtualMachineImages/imageTemplates",
      "apiVersion": "2022-02-14",
      "name": "[parameters('imageTemplateName')]",
      "location": "[resourceGroup().location]",
      "dependsOn": [
        "[resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', variables('userAssignedIdentityName'))]"
      ],
      "identity": {
        "type": "UserAssigned",
        "userAssignedIdentities": {
          "[resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', variables('userAssignedIdentityName'))]": {}
        }
      },
      "properties": {
        "buildTimeoutInMinutes": 120,
        "vmProfile": {
          "vmSize": "Standard_D4s_v3",
          "osDiskSizeGB": 128
        },
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
            "name": "SetExecutionPolicy",
            "inline": [
              "Set-ExecutionPolicy Bypass -Scope LocalMachine -Force"
            ]
          },
          {
            "type": "PowerShell",
            "name": "InstallChocolatey",
            "inline": [
              "[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072",
              "iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
            ]
          },
          {
            "type": "PowerShell",
            "name": "InstallDevelopmentTools",
            "inline": [
              "choco install git -y",
              "choco install nodejs -y",
              "choco install dotnet-sdk -y",
              "choco install azure-cli -y",
              "choco install vscode -y",
              "choco install 7zip -y",
              "choco install curl -y"
            ]
          },
          {
            "type": "PowerShell",
            "name": "InstallVisualStudioBuildTools",
            "inline": [
              "$vsUrl = 'https://aka.ms/vs/17/release/vs_buildtools.exe'",
              "$vsInstaller = 'C:\\temp\\vs_buildtools.exe'",
              "New-Item -Path 'C:\\temp' -ItemType Directory -Force",
              "Invoke-WebRequest -Uri $vsUrl -OutFile $vsInstaller",
              "Start-Process -FilePath $vsInstaller -ArgumentList '--quiet', '--wait', '--add', 'Microsoft.VisualStudio.Workload.MSBuildTools', '--add', 'Microsoft.VisualStudio.Workload.WebBuildTools', '--add', 'Microsoft.VisualStudio.Workload.NetCoreBuildTools' -Wait",
              "Remove-Item $vsInstaller -Force"
            ]
          },
          {
            "type": "PowerShell",
            "name": "PrepareAzureDevOpsAgent",
            "inline": [
              "New-Item -Path 'C:\\agent' -ItemType Directory -Force",
              "New-Item -Path 'C:\\Scripts' -ItemType Directory -Force",
              "$agentUrl = 'https://vstsagentpackage.azureedge.net/agent/3.232.0/vsts-agent-win-x64-3.232.0.zip'",
              "Invoke-WebRequest -Uri $agentUrl -OutFile 'C:\\temp\\agent.zip'",
              "Expand-Archive -Path 'C:\\temp\\agent.zip' -DestinationPath 'C:\\agent' -Force",
              "Remove-Item 'C:\\temp\\agent.zip' -Force"
            ]
          },
          {
            "type": "File",
            "name": "CopyConfigurationScript",
            "sourceUri": "https://raw.githubusercontent.com/your-repo/azure-devops-vmss-template/main/scripts/configure-devops-agent.ps1",
            "destination": "C:\\Scripts\\configure-devops-agent.ps1"
          },
          {
            "type": "PowerShell",
            "name": "ConfigureWindowsFeatures",
            "inline": [
              "Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All",
              "Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer -All",
              "Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures -All",
              "Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors -All",
              "Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpLogging -All",
              "Enable-WindowsOptionalFeature -Online -FeatureName IIS-Security -All",
              "Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestFiltering -All"
            ]
          },
          {
            "type": "PowerShell",
            "name": "CleanupAndOptimize",
            "inline": [
              "Remove-Item -Path 'C:\\temp\\*' -Recurse -Force -ErrorAction SilentlyContinue",
              "Clear-RecycleBin -Force -ErrorAction SilentlyContinue",
              "Optimize-Volume -DriveLetter C -ReTrim -Verbose"
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
            "galleryImageId": "[concat('/subscriptions/', subscription().subscriptionId, '/resourceGroups/', resourceGroup().name, '/providers/Microsoft.Compute/galleries/', parameters('galleryName'), '/images/', parameters('imageDefinitionName'), '/versions/', parameters('imageVersion'))]",
            "runOutputName": "aibCustomWinManaged",
            "replicationRegions": [
              "[resourceGroup().location]"
            ],
            "storageAccountType": "Standard_LRS"
          }
        ]
      }
    }
  ]
}
```

#### 1.2 Deploy Image Builder Infrastructure

```bash
# Set variables
RESOURCE_GROUP="rg-devops-images"
LOCATION="East US"
GALLERY_NAME="myDevOpsGallery"
IMAGE_DEFINITION="windows-devops-agent"

# Create resource group
az group create --name $RESOURCE_GROUP --location "$LOCATION"

# Create Azure Compute Gallery
az sig create \
  --resource-group $RESOURCE_GROUP \
  --gallery-name $GALLERY_NAME \
  --location "$LOCATION"

# Create image definition
az sig image-definition create \
  --resource-group $RESOURCE_GROUP \
  --gallery-name $GALLERY_NAME \
  --gallery-image-definition $IMAGE_DEFINITION \
  --publisher MyCompany \
  --offer DevOpsAgents \
  --sku WindowsServer2022 \
  --os-type Windows \
  --os-state Generalized \
  --hyper-v-generation V2 \
  --location "$LOCATION"

# Deploy image builder template
az deployment group create \
  --resource-group $RESOURCE_GROUP \
  --template-file imagebuilder-template.json \
  --parameters galleryName=$GALLERY_NAME \
  --parameters imageDefinitionName=$IMAGE_DEFINITION
```

#### 1.3 Build the Image

```bash
# Start image build
az image builder run \
  --name devops-agent-template \
  --resource-group $RESOURCE_GROUP

# Monitor build progress
az image builder show-runs \
  --name devops-agent-template \
  --resource-group $RESOURCE_GROUP \
  --output table

# Check build logs
az image builder show-runs \
  --name devops-agent-template \
  --resource-group $RESOURCE_GROUP \
  --run-output-name aibCustomWinManaged
```

### Method 2: Manual VM Creation and Sysprep

For more control over the image creation process, you can manually create and configure a VM.

#### 2.1 Create Base VM

```bash
# Create VM from marketplace image
az vm create \
  --resource-group $RESOURCE_GROUP \
  --name vm-devops-base \
  --image Win2022Datacenter \
  --admin-username azureuser \
  --admin-password 'YourSecurePassword123!' \
  --size Standard_D4s_v3 \
  --location "$LOCATION"

# Get public IP for RDP access
az vm show \
  --resource-group $RESOURCE_GROUP \
  --name vm-devops-base \
  --show-details \
  --query publicIps \
  --output tsv
```

#### 2.2 Configure the VM

Connect via RDP and run the following PowerShell script:

```powershell
# Set execution policy
Set-ExecutionPolicy Bypass -Scope LocalMachine -Force

# Install Chocolatey
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install development tools
choco install git -y
choco install nodejs -y
choco install dotnet-sdk -y
choco install azure-cli -y
choco install vscode -y
choco install 7zip -y
choco install curl -y
choco install docker-desktop -y

# Install Visual Studio Build Tools
$vsUrl = 'https://aka.ms/vs/17/release/vs_buildtools.exe'
$vsInstaller = 'C:\temp\vs_buildtools.exe'
New-Item -Path 'C:\temp' -ItemType Directory -Force
Invoke-WebRequest -Uri $vsUrl -OutFile $vsInstaller
Start-Process -FilePath $vsInstaller -ArgumentList '--quiet', '--wait', '--add', 'Microsoft.VisualStudio.Workload.MSBuildTools', '--add', 'Microsoft.VisualStudio.Workload.WebBuildTools', '--add', 'Microsoft.VisualStudio.Workload.NetCoreBuildTools' -Wait
Remove-Item $vsInstaller -Force

# Prepare Azure DevOps agent directory
New-Item -Path 'C:\agent' -ItemType Directory -Force
New-Item -Path 'C:\Scripts' -ItemType Directory -Force

# Download Azure DevOps agent
$agentUrl = 'https://vstsagentpackage.azureedge.net/agent/3.232.0/vsts-agent-win-x64-3.232.0.zip'
Invoke-WebRequest -Uri $agentUrl -OutFile 'C:\temp\agent.zip'
Expand-Archive -Path 'C:\temp\agent.zip' -DestinationPath 'C:\agent' -Force
Remove-Item 'C:\temp\agent.zip' -Force

# Enable IIS features
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer -All
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures -All

# Create agent configuration script
@'
param(
    [string]$AzureDevOpsUrl,
    [string]$PersonalAccessToken,
    [string]$AgentPool = "Default",
    [string]$AgentName = $env:COMPUTERNAME
)

cd C:\agent
.\config.cmd --unattended --url $AzureDevOpsUrl --auth pat --token $PersonalAccessToken --pool $AgentPool --agent $AgentName --runAsService --windowsLogonAccount "NT AUTHORITY\SYSTEM"
'@ | Out-File -FilePath 'C:\Scripts\configure-agent.ps1' -Encoding UTF8

# Cleanup
Remove-Item -Path 'C:\temp\*' -Recurse -Force -ErrorAction SilentlyContinue
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

# Optimize disk
Optimize-Volume -DriveLetter C -ReTrim -Verbose

Write-Host "VM configuration completed. Ready for Sysprep." -ForegroundColor Green
```

#### 2.3 Sysprep and Capture

```powershell
# Run Sysprep to generalize the VM
C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown /mode:vm
```

After the VM shuts down:

```bash
# Deallocate and generalize VM
az vm deallocate --resource-group $RESOURCE_GROUP --name vm-devops-base
az vm generalize --resource-group $RESOURCE_GROUP --name vm-devops-base

# Create managed image
az image create \
  --resource-group $RESOURCE_GROUP \
  --name devops-agent-image \
  --source vm-devops-base \
  --location "$LOCATION"

# Or create image version in Shared Image Gallery
az sig image-version create \
  --resource-group $RESOURCE_GROUP \
  --gallery-name $GALLERY_NAME \
  --gallery-image-definition $IMAGE_DEFINITION \
  --gallery-image-version 1.0.0 \
  --target-regions "$LOCATION=1" \
  --managed-image devops-agent-image
```

## 🔧 Using Custom Images in VMSS Template

### Configuration for Shared Image Gallery

```json
{
  "useCustomImage": {
    "value": true
  },
  "customImageType": {
    "value": "sharedGallery"
  },
  "customImageResourceId": {
    "value": "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-devops-images/providers/Microsoft.Compute/galleries/myDevOpsGallery/images/windows-devops-agent/versions/1.0.0"
  },
  "configureDevOpsAgent": {
    "value": true
  }
}
```

### Configuration for Managed Image

```json
{
  "useCustomImage": {
    "value": true
  },
  "customImageType": {
    "value": "managedImage"
  },
  "customImageResourceId": {
    "value": "/subscriptions/12345678-1234-1234-1234-123456789012/resourceGroups/rg-devops-images/providers/Microsoft.Compute/images/devops-agent-image"
  },
  "configureDevOpsAgent": {
    "value": true
  }
}
```

### Deployment Example

```bash
az deployment group create \
  --resource-group rg-devops \
  --template-file bicep/vmss-infrastructure.bicep \
  --parameters useCustomImage=true \
  --parameters customImageType=sharedGallery \
  --parameters customImageResourceId="/subscriptions/.../galleries/myDevOpsGallery/images/windows-devops-agent/versions/1.0.0" \
  --parameters configureDevOpsAgent=true \
  --parameters azureDevOpsUrl=https://dev.azure.com/myorg \
  --parameters azureDevOpsPat=<your-pat> \
  --parameters adminPassword=<secure-password>
```

## 📋 Image Management Best Practices

### 1. Version Management Strategy

#### Semantic Versioning
```bash
# Major version for breaking changes
az sig image-version create --gallery-image-version 2.0.0

# Minor version for new features
az sig image-version create --gallery-image-version 1.1.0

# Patch version for bug fixes
az sig image-version create --gallery-image-version 1.0.1
```

#### Tagging Strategy
```bash
# Tag images with metadata
az sig image-version create \
  --gallery-image-version 1.2.0 \
  --tags "BuildDate=$(date +%Y-%m-%d)" \
         "DotNetVersion=8.0" \
         "NodeVersion=18.17.0" \
         "Environment=Production"
```

### 2. Automated Image Updates

Create an Azure DevOps pipeline for automated image builds:

```yaml
# azure-pipelines-image-build.yml
trigger:
  branches:
    include:
    - main
  paths:
    include:
    - images/
    - scripts/

variables:
  resourceGroupName: 'rg-devops-images'
  galleryName: 'myDevOpsGallery'
  imageDefinitionName: 'windows-devops-agent'

stages:
- stage: BuildImage
  displayName: 'Build Custom Image'
  jobs:
  - job: BuildJob
    displayName: 'Build Image Job'
    pool:
      vmImage: 'ubuntu-latest'
    
    steps:
    - task: AzureCLI@2
      displayName: 'Create Image Version'
      inputs:
        azureSubscription: 'your-service-connection'
        scriptType: 'bash'
        scriptLocation: 'inlineScript'
        inlineScript: |
          # Calculate next version
          LATEST_VERSION=$(az sig image-version list \
            --resource-group $(resourceGroupName) \
            --gallery-name $(galleryName) \
            --gallery-image-definition $(imageDefinitionName) \
            --query "max_by([].name, &name)" -o tsv)
          
          # Increment patch version
          IFS='.' read -ra VERSION_PARTS <<
