
<#
.SYNOPSIS
    Configures Azure DevOps build agent on Microsoft prebuilt runner images
    
.DESCRIPTION
    This script configures Azure DevOps build agent on Microsoft's prebuilt runner images.
    These images already have development tools installed, so this script focuses on:
    - Downloading and configuring the Azure DevOps agent
    - Registering the agent with the specified pool
    - Starting the agent service
    
    This is a simplified version for use with Microsoft prebuilt images that already
    include Visual Studio, .NET SDKs, and other development tools.
    
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
    .\configure-devops-agent.ps1 -AzureDevOpsUrl "https://dev.azure.com/myorg" -PersonalAccessToken "pat123" -AgentPool "Default" -AgentName "BuildAgent"
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
$LogFile = "C:\temp\devops-agent-config.log"
$null = New-Item -Path "C:\temp" -ItemType Directory -Force
Start-Transcript -Path $LogFile -Append

try {
    Write-Host "Starting Azure DevOps Agent configuration on Microsoft prebuilt image..." -ForegroundColor Green
    Write-Host "Timestamp: $(Get-Date)" -ForegroundColor Yellow
    
    # Set error action preference
    $ErrorActionPreference = "Stop"
    
    # Create agent directory
    $AgentDirectory = "C:\agent"
    Write-Host "Creating agent directory: $AgentDirectory" -ForegroundColor Yellow
    $null = New-Item -Path $AgentDirectory -ItemType Directory -Force
    
    # Set security protocol for downloads
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    
    # Verify development tools are available (since we're using Microsoft prebuilt images)
    Write-Host "Verifying development tools on prebuilt image..." -ForegroundColor Yellow
    try {
        # Check for .NET
        if (Test-Path "C:\Program Files\dotnet\dotnet.exe") {
            $dotnetVersion = & "C:\Program Files\dotnet\dotnet.exe" --version
            Write-Host "Found .NET SDK version: $dotnetVersion" -ForegroundColor Green
        }
        
        # Check for Visual Studio
        $vsPath = Get-ChildItem -Path "C:\Program Files*" -Name "*Visual Studio*" -Directory -ErrorAction SilentlyContinue
        if ($vsPath) {
            Write-Host "Found Visual Studio installation: $($vsPath -join ', ')" -ForegroundColor Green
        }
        
        # Check for MSBuild
        $msbuildPath = Get-ChildItem -Path "C:\Program Files*" -Recurse -Name "MSBuild.exe" -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($msbuildPath) {
            Write-Host "Found MSBuild at: $msbuildPath" -ForegroundColor Green
        }
        
        # Check for Git
        $gitVersion = git --version 2>$null
        if ($gitVersion) {
            Write-Host "Found Git: $gitVersion" -ForegroundColor Green
        }
        
        Write-Host "Development tools verification completed" -ForegroundColor Green
    }
    catch {
        Write-Warning "Some development tools verification failed: $($_.Exception.Message)"
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
    
    Write-Host "Azure DevOps Agent configuration completed successfully!" -ForegroundColor Green
    Write-Host "Agent Name: $uniqueAgentName" -ForegroundColor Yellow
    Write-Host "Agent Pool: $AgentPool" -ForegroundColor Yellow
    Write-Host "Work Directory: $WorkDirectory" -ForegroundColor Yellow
    Write-Host "Log File: $LogFile" -ForegroundColor Yellow
    
    # Create a summary file
    $summaryFile = "C:\temp\agent-config-summary.txt"
    @"
Azure DevOps Agent Configuration Summary
=======================================
Configuration Date: $(Get-Date)
Agent Name: $uniqueAgentName
Agent Pool: $AgentPool
Work Directory: $WorkDirectory
Azure DevOps URL: $AzureDevOpsUrl
Computer Name: $env:COMPUTERNAME
Log File: $LogFile
Image Type: Microsoft Prebuilt Runner Image

Configuration Status: SUCCESS
"@ | Out-File -FilePath $summaryFile -Encoding UTF8
    
    Write-Host "Configuration summary saved to: $summaryFile" -ForegroundColor Yellow
}
catch {
    Write-Error "Configuration failed: $($_.Exception.Message)"
    Write-Host "Check the log file for details: $LogFile" -ForegroundColor Red
    
    # Create error summary
    $errorSummaryFile = "C:\temp\agent-config-error.txt"
    @"
Azure DevOps Agent Configuration Error
=====================================
Configuration Date: $(Get-Date)
Error Message: $($_.Exception.Message)
Computer Name: $env:COMPUTERNAME
Log File: $LogFile

Configuration Status: FAILED
"@ | Out-File -FilePath $errorSummaryFile -Encoding UTF8
    
    exit 1
}
finally {
    Stop-Transcript
}
