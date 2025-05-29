
<#
.SYNOPSIS
    Installs Azure DevOps build agent and .NET Core SDK on Windows Server 2022
    
.DESCRIPTION
    This script automates the installation of:
    - Azure DevOps build agent
    - .NET Core SDK (latest LTS)
    - Required dependencies and tools
    
.PARAMETER AzureDevOpsUrl
    The URL of your Azure DevOps organization (e.g., https://dev.azure.com/yourorg)
    
.PARAMETER PersonalAccessToken
    Personal Access Token with Agent Pools (read, manage) permissions
    
.PARAMETER AgentPool
    Name of the agent pool to register the agent with
    
.PARAMETER AgentName
    Name for the build agent (will be suffixed with computer name if not unique)
    
.PARAMETER WorkDirectory
    Working directory for the agent (default: C:\agent\_work)
    
.EXAMPLE
    .\install-devops-agent.ps1 -AzureDevOpsUrl "https://dev.azure.com/myorg" -PersonalAccessToken "pat123" -AgentPool "Default" -AgentName "BuildAgent"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AzureDevOpsUrl,
    
    [Parameter(Mandatory = $true)]
    [string]$PersonalAccessToken,
    
    [Parameter(Mandatory = $false)]
    [string]$AgentPool = "Default",
    
    [Parameter(Mandatory = $false)]
    [string]$AgentName = "BuildAgent",
    
    [Parameter(Mandatory = $false)]
    [string]$WorkDirectory = "C:\agent\_work"
)

# Enable logging
$LogFile = "C:\temp\devops-agent-install.log"
$null = New-Item -Path "C:\temp" -ItemType Directory -Force
Start-Transcript -Path $LogFile -Append

try {
    Write-Host "Starting Azure DevOps Agent installation..." -ForegroundColor Green
    Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Yellow
    
    # Set error action preference
    $ErrorActionPreference = "Stop"
    
    # Create agent directory
    $AgentDirectory = "C:\agent"
    Write-Host "Creating agent directory: $AgentDirectory" -ForegroundColor Yellow
    $null = New-Item -Path $AgentDirectory -ItemType Directory -Force
    
    # Set security protocol for downloads
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # Download and install .NET Core SDK
    Write-Host "Installing .NET Core SDK..." -ForegroundColor Yellow
    try {
        $dotnetInstallScript = "C:\temp\dotnet-install.ps1"
        Write-Host "Downloading .NET install script..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri "https://dot.net/v1/dotnet-install.ps1" -OutFile $dotnetInstallScript -UseBasicParsing
        
        Write-Host "Installing .NET SDK LTS..." -ForegroundColor Cyan
        & $dotnetInstallScript -Channel LTS -InstallDir "C:\Program Files\dotnet" -NoPath
        
        # Set environment variables
        $env:DOTNET_ROOT = "C:\Program Files\dotnet"
        $env:PATH = "$env:PATH;$env:DOTNET_ROOT"
        
        # Set system environment variables permanently
        [Environment]::SetEnvironmentVariable("DOTNET_ROOT", "C:\Program Files\dotnet", "Machine")
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($currentPath -notlike "*C:\Program Files\dotnet*") {
            [Environment]::SetEnvironmentVariable("PATH", "$currentPath;C:\Program Files\dotnet", "Machine")
        }
        
        Write-Host ".NET SDK installed successfully" -ForegroundColor Green
        
        # Verify installation
        $dotnetVersion = & "C:\Program Files\dotnet\dotnet.exe" --version
        Write-Host "Installed .NET version: $dotnetVersion" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to install .NET SDK: $($_.Exception.Message)"
        throw
    }
    
    # Install Chocolatey for additional tools
    Write-Host "Installing Chocolatey..." -ForegroundColor Yellow
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        
        # Refresh environment variables
        $env:PATH = [Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [Environment]::GetEnvironmentVariable("PATH", "User")
        
        Write-Host "Chocolatey installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to install Chocolatey: $($_.Exception.Message)"
    }
    
    # Install additional development tools
    Write-Host "Installing additional development tools..." -ForegroundColor Yellow
    try {
        choco install git -y
        choco install nodejs -y
        choco install azure-cli -y
        Write-Host "Additional tools installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Warning "Some additional tools failed to install: $($_.Exception.Message)"
    }
    
    # Download Azure DevOps agent
    Write-Host "Downloading Azure DevOps agent..." -ForegroundColor Yellow
    try {
        $agentZip = "$AgentDirectory\vsts-agent.zip"
        $agentUrl = "$AzureDevOpsUrl/_apis/distributedtask/packages/agent?platform=win-x64&`$top=1"
        
        # Get the latest agent download URL
        $headers = @{
            'Authorization' = "Basic $([Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$PersonalAccessToken")))"
            'Accept' = 'application/json'
        }
        
        Write-Host "Getting agent download URL from: $agentUrl" -ForegroundColor Cyan
        $response = Invoke-RestMethod -Uri $agentUrl -Headers $headers -UseBasicParsing
        $downloadUrl = $response.value[0].downloadUrl
        
        Write-Host "Downloading agent from: $downloadUrl" -ForegroundColor Cyan
        Invoke-WebRequest -Uri $downloadUrl -OutFile $agentZip -UseBasicParsing
        
        Write-Host "Agent downloaded successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to download Azure DevOps agent: $($_.Exception.Message)"
        throw
    }
    
    # Extract agent
    Write-Host "Extracting Azure DevOps agent..." -ForegroundColor Yellow
    try {
        Expand-Archive -Path $agentZip -DestinationPath $AgentDirectory -Force
        Remove-Item -Path $agentZip -Force
        Write-Host "Agent extracted successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to extract agent: $($_.Exception.Message)"
        throw
    }
    
    # Configure agent
    Write-Host "Configuring Azure DevOps agent..." -ForegroundColor Yellow
    try {
        Set-Location -Path $AgentDirectory
        
        # Make agent name unique by appending computer name
        $uniqueAgentName = "$AgentName-$env:COMPUTERNAME"
        
        Write-Host "Configuring agent with name: $uniqueAgentName" -ForegroundColor Cyan
        Write-Host "Agent pool: $AgentPool" -ForegroundColor Cyan
        Write-Host "Work directory: $WorkDirectory" -ForegroundColor Cyan
        
        # Run agent configuration
        $configArgs = @(
            "--unattended",
            "--url", $AzureDevOpsUrl,
            "--auth", "pat",
            "--token", $PersonalAccessToken,
            "--pool", $AgentPool,
            "--agent", $uniqueAgentName,
            "--work", $WorkDirectory,
            "--runAsService",
            "--windowsLogonAccount", "NT AUTHORITY\SYSTEM",
            "--overwriteautologon"
        )
        
        Write-Host "Running configuration command..." -ForegroundColor Cyan
        & .\config.cmd @configArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Agent configured successfully" -ForegroundColor Green
        } else {
            throw "Agent configuration failed with exit code: $LASTEXITCODE"
        }
    }
    catch {
        Write-Error "Failed to configure agent: $($_.Exception.Message)"
        throw
    }
    
    # Start agent service
    Write-Host "Starting Azure DevOps agent service..." -ForegroundColor Yellow
    try {
        $serviceName = "vstsagent.*"
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        
        if ($service) {
            Start-Service -Name $service.Name
            Write-Host "Agent service started successfully: $($service.Name)" -ForegroundColor Green
        } else {
            Write-Warning "Agent service not found. It may need to be started manually."
        }
    }
    catch {
        Write-Warning "Failed to start agent service: $($_.Exception.Message)"
    }
    
    # Verify agent installation
    Write-Host "Verifying agent installation..." -ForegroundColor Yellow
    try {
        $agentConfig = Get-Content -Path "$AgentDirectory\.agent" -Raw | ConvertFrom-Json
        Write-Host "Agent ID: $($agentConfig.agentId)" -ForegroundColor Green
        Write-Host "Agent Name: $($agentConfig.agentName)" -ForegroundColor Green
        Write-Host "Pool ID: $($agentConfig.poolId)" -ForegroundColor Green
        Write-Host "Server URL: $($agentConfig.serverUrl)" -ForegroundColor Green
    }
    catch {
        Write-Warning "Could not read agent configuration file"
    }
    
    # Install Windows Features for development
    Write-Host "Installing Windows Features..." -ForegroundColor Yellow
    try {
        Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All -NoRestart
        Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer -All -NoRestart
        Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures -All -NoRestart
        Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors -All -NoRestart
        Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpRedirect -All -NoRestart
        Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment -All -NoRestart
        Enable-WindowsOptionalFeature -Online -FeatureName IIS-NetFx45 -All -NoRestart
        Enable-WindowsOptionalFeature -Online -FeatureName IIS-NetFxExtensibility45 -All -NoRestart
        Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIExtensions -All -NoRestart
        Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIFilter -All -NoRestart
        Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45 -All -NoRestart
        
        Write-Host "Windows Features installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Warning "Some Windows Features failed to install: $($_.Exception.Message)"
    }
    
    Write-Host "Azure DevOps Agent installation completed successfully!" -ForegroundColor Green
    Write-Host "Agent Name: $uniqueAgentName" -ForegroundColor Yellow
    Write-Host "Agent Pool: $AgentPool" -ForegroundColor Yellow
    Write-Host "Work Directory: $WorkDirectory" -ForegroundColor Yellow
    Write-Host "Log File: $LogFile" -ForegroundColor Yellow
    
    # Create a summary file
    $summaryFile = "C:\temp\installation-summary.txt"
    @"
Azure DevOps Agent Installation Summary
======================================
Installation Date: $(Get-Date)
Agent Name: $uniqueAgentName
Agent Pool: $AgentPool
Work Directory: $WorkDirectory
Azure DevOps URL: $AzureDevOpsUrl
.NET Version: $dotnetVersion
Computer Name: $env:COMPUTERNAME
Log File: $LogFile

Installation Status: SUCCESS
"@ | Out-File -FilePath $summaryFile -Encoding UTF8
    
    Write-Host "Installation summary saved to: $summaryFile" -ForegroundColor Yellow
}
catch {
    Write-Error "Installation failed: $($_.Exception.Message)"
    Write-Host "Check the log file for details: $LogFile" -ForegroundColor Red
    
    # Create error summary
    $errorSummaryFile = "C:\temp\installation-error.txt"
    @"
Azure DevOps Agent Installation Error
====================================
Installation Date: $(Get-Date)
Error Message: $($_.Exception.Message)
Computer Name: $env:COMPUTERNAME
Log File: $LogFile

Installation Status: FAILED
"@ | Out-File -FilePath $errorSummaryFile -Encoding UTF8
    
    exit 1
}
finally {
    Stop-Transcript
}
