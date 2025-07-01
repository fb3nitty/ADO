
<#
.SYNOPSIS
    Extracts pipeline-level permissions and security settings from Azure DevOps Services
.DESCRIPTION
    This script connects to Azure DevOps Services and extracts build/release pipeline permissions,
    service connections, agent pools, and variable groups security settings.
.PARAMETER OrganizationUrl
    The URL of your Azure DevOps organization (e.g., https://dev.azure.com/yourorg)
.PARAMETER ProjectName
    Name of the specific project to analyze
.PARAMETER PipelineType
    Type of pipelines to analyze: 'Build', 'Release', or 'Both' (default: Both)
.PARAMETER PersonalAccessToken
    Personal Access Token with appropriate permissions to read pipeline settings
.PARAMETER OutputPath
    Path where the output CSV file will be saved
.EXAMPLE
    .\Get-AzureDevOpsPipelinePermissions.ps1 -OrganizationUrl "https://dev.azure.com/myorg" -ProjectName "MyProject" -PersonalAccessToken $pat
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OrganizationUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Build", "Release", "Both")]
    [string]$PipelineType = "Both",
    
    [Parameter(Mandatory=$true)]
    [string]$PersonalAccessToken,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\pipeline_permissions_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
)

# Function to create authentication header
function Get-AuthHeader {
    param([string]$Token)
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Token"))
    return @{Authorization = "Basic $base64AuthInfo"}
}

# Function to make REST API calls with error handling
function Invoke-AzureDevOpsApi {
    param(
        [string]$Uri,
        [hashtable]$Headers,
        [string]$Method = "GET"
    )
    
    try {
        $response = Invoke-RestMethod -Uri $Uri -Headers $Headers -Method $Method -ContentType "application/json"
        return $response
    }
    catch {
        Write-Warning "API call failed for $Uri : $($_.Exception.Message)"
        return $null
    }
}

# Function to get build pipeline permissions
function Get-BuildPipelinePermissions {
    param(
        [string]$OrgUrl,
        [string]$Project,
        [hashtable]$Headers
    )
    
    $buildResults = @()
    
    Write-Host "  Analyzing build pipelines..." -ForegroundColor Cyan
    
    # Get build definitions
    $buildDefsUri = "$OrgUrl/$Project/_apis/build/definitions?api-version=7.1-preview.7"
    $buildDefs = Invoke-AzureDevOpsApi -Uri $buildDefsUri -Headers $Headers
    
    if ($buildDefs -and $buildDefs.value) {
        foreach ($buildDef in $buildDefs.value) {
            # Get build definition permissions
            $buildNamespaceId = "33344d9c-fc72-4d6f-aba5-fa317101a7e9"
            $aclUri = "$OrgUrl/_apis/accesscontrollists/$buildNamespaceId?api-version=7.1-preview.1"
            $acls = Invoke-AzureDevOpsApi -Uri $aclUri -Headers $Headers
            
            $buildResults += [PSCustomObject]@{
                ProjectName = $Project
                PipelineType = "Build"
                PipelineName = $buildDef.name
                PipelineId = $buildDef.id
                QueueStatus = $buildDef.queueStatus
                Repository = if ($buildDef.repository) { $buildDef.repository.name } else { "N/A" }
                AgentPool = if ($buildDef.queue) { $buildDef.queue.name } else { "N/A" }
                CreatedDate = $buildDef.createdDate
                ModifiedDate = $buildDef.modifiedDate
                AuthoredBy = $buildDef.authoredBy.displayName
                Path = $buildDef.path
                HasPermissions = if ($acls -and $acls.value) { 
                    ($acls.value | Where-Object { $_.token -like "*$($buildDef.id)*" }).Count -gt 0 
                } else { $false }
            }
        }
    }
    
    return $buildResults
}

# Function to get release pipeline permissions
function Get-ReleasePipelinePermissions {
    param(
        [string]$OrgUrl,
        [string]$Project,
        [hashtable]$Headers
    )
    
    $releaseResults = @()
    
    Write-Host "  Analyzing release pipelines..." -ForegroundColor Cyan
    
    # Get release definitions
    $releaseDefsUri = "$OrgUrl/$Project/_apis/release/definitions?api-version=7.1-preview.4"
    $releaseDefs = Invoke-AzureDevOpsApi -Uri $releaseDefsUri -Headers $Headers
    
    if ($releaseDefs -and $releaseDefs.value) {
        foreach ($releaseDef in $releaseDefs.value) {
            # Get release definition details
            $releaseDefDetailUri = "$OrgUrl/$Project/_apis/release/definitions/$($releaseDef.id)?api-version=7.1-preview.4"
            $releaseDefDetail = Invoke-AzureDevOpsApi -Uri $releaseDefDetailUri -Headers $Headers
            
            $environments = if ($releaseDefDetail -and $releaseDefDetail.environments) {
                ($releaseDefDetail.environments | ForEach-Object { $_.name }) -join "; "
            } else { "N/A" }
            
            $releaseResults += [PSCustomObject]@{
                ProjectName = $Project
                PipelineType = "Release"
                PipelineName = $releaseDef.name
                PipelineId = $releaseDef.id
                Path = $releaseDef.path
                Environments = $environments
                CreatedDate = $releaseDef.createdOn
                ModifiedDate = $releaseDef.modifiedOn
                CreatedBy = $releaseDef.createdBy.displayName
                ModifiedBy = $releaseDef.modifiedBy.displayName
                Source = if ($releaseDefDetail -and $releaseDefDetail.artifacts) {
                    ($releaseDefDetail.artifacts | ForEach-Object { "$($_.alias):$($_.type)" }) -join "; "
                } else { "N/A" }
            }
        }
    }
    
    return $releaseResults
}

# Function to get service connections
function Get-ServiceConnections {
    param(
        [string]$OrgUrl,
        [string]$Project,
        [hashtable]$Headers
    )
    
    $serviceResults = @()
    
    Write-Host "  Analyzing service connections..." -ForegroundColor Cyan
    
    # Get service endpoints
    $serviceEndpointsUri = "$OrgUrl/$Project/_apis/serviceendpoint/endpoints?api-version=7.1-preview.4"
    $serviceEndpoints = Invoke-AzureDevOpsApi -Uri $serviceEndpointsUri -Headers $Headers
    
    if ($serviceEndpoints -and $serviceEndpoints.value) {
        foreach ($endpoint in $serviceEndpoints.value) {
            $serviceResults += [PSCustomObject]@{
                ProjectName = $Project
                ResourceType = "ServiceConnection"
                Name = $endpoint.name
                Id = $endpoint.id
                Type = $endpoint.type
                Url = $endpoint.url
                IsShared = $endpoint.isShared
                IsReady = $endpoint.isReady
                Owner = $endpoint.owner
                CreatedBy = $endpoint.createdBy.displayName
                Description = $endpoint.description
                Authorization = $endpoint.authorization.scheme
            }
        }
    }
    
    return $serviceResults
}

# Function to get agent pools
function Get-AgentPools {
    param(
        [string]$OrgUrl,
        [string]$Project,
        [hashtable]$Headers
    )
    
    $agentResults = @()
    
    Write-Host "  Analyzing agent pools..." -ForegroundColor Cyan
    
    # Get agent pools for the project
    $agentPoolsUri = "$OrgUrl/$Project/_apis/distributedtask/queues?api-version=7.1-preview.1"
    $agentPools = Invoke-AzureDevOpsApi -Uri $agentPoolsUri -Headers $Headers
    
    if ($agentPools -and $agentPools.value) {
        foreach ($pool in $agentPools.value) {
            $agentResults += [PSCustomObject]@{
                ProjectName = $Project
                ResourceType = "AgentPool"
                Name = $pool.name
                Id = $pool.id
                PoolId = $pool.pool.id
                PoolName = $pool.pool.name
                IsHosted = $pool.pool.isHosted
                PoolType = $pool.pool.poolType
                Size = $pool.pool.size
                IsLegacy = $pool.pool.isLegacy
            }
        }
    }
    
    return $agentResults
}

# Function to get variable groups
function Get-VariableGroups {
    param(
        [string]$OrgUrl,
        [string]$Project,
        [hashtable]$Headers
    )
    
    $variableResults = @()
    
    Write-Host "  Analyzing variable groups..." -ForegroundColor Cyan
    
    # Get variable groups
    $variableGroupsUri = "$OrgUrl/$Project/_apis/distributedtask/variablegroups?api-version=7.1-preview.2"
    $variableGroups = Invoke-AzureDevOpsApi -Uri $variableGroupsUri -Headers $Headers
    
    if ($variableGroups -and $variableGroups.value) {
        foreach ($varGroup in $variableGroups.value) {
            $variableCount = if ($varGroup.variables) { $varGroup.variables.PSObject.Properties.Count } else { 0 }
            
            $variableResults += [PSCustomObject]@{
                ProjectName = $Project
                ResourceType = "VariableGroup"
                Name = $varGroup.name
                Id = $varGroup.id
                Description = $varGroup.description
                Type = $varGroup.type
                VariableCount = $variableCount
                CreatedBy = $varGroup.createdBy.displayName
                ModifiedBy = $varGroup.modifiedBy.displayName
                CreatedOn = $varGroup.createdOn
                ModifiedOn = $varGroup.modifiedOn
                IsShared = if ($varGroup.variableGroupProjectReferences) { 
                    $varGroup.variableGroupProjectReferences.Count -gt 1 
                } else { $false }
            }
        }
    }
    
    return $variableResults
}

# Main execution
try {
    Write-Host "Starting Azure DevOps Pipeline Permissions Extraction..." -ForegroundColor Green
    
    # Validate organization URL format
    if ($OrganizationUrl -notmatch "^https://dev\.azure\.com/[^/]+/?$") {
        throw "Invalid organization URL format. Expected: https://dev.azure.com/yourorg"
    }
    
    $headers = Get-AuthHeader -Token $PersonalAccessToken
    $allResults = @()
    
    Write-Host "Analyzing project: $ProjectName" -ForegroundColor Yellow
    
    # Analyze build pipelines
    if ($PipelineType -eq "Build" -or $PipelineType -eq "Both") {
        try {
            $buildResults = Get-BuildPipelinePermissions -OrgUrl $OrganizationUrl -Project $ProjectName -Headers $headers
            $allResults += $buildResults
        }
        catch {
            Write-Warning "Failed to analyze build pipelines: $($_.Exception.Message)"
        }
    }
    
    # Analyze release pipelines
    if ($PipelineType -eq "Release" -or $PipelineType -eq "Both") {
        try {
            $releaseResults = Get-ReleasePipelinePermissions -OrgUrl $OrganizationUrl -Project $ProjectName -Headers $headers
            $allResults += $releaseResults
        }
        catch {
            Write-Warning "Failed to analyze release pipelines: $($_.Exception.Message)"
        }
    }
    
    # Analyze service connections
    try {
        $serviceResults = Get-ServiceConnections -OrgUrl $OrganizationUrl -Project $ProjectName -Headers $headers
        $allResults += $serviceResults
    }
    catch {
        Write-Warning "Failed to analyze service connections: $($_.Exception.Message)"
    }
    
    # Analyze agent pools
    try {
        $agentResults = Get-AgentPools -OrgUrl $OrganizationUrl -Project $ProjectName -Headers $headers
        $allResults += $agentResults
    }
    catch {
        Write-Warning "Failed to analyze agent pools: $($_.Exception.Message)"
    }
    
    # Analyze variable groups
    try {
        $variableResults = Get-VariableGroups -OrgUrl $OrganizationUrl -Project $ProjectName -Headers $headers
        $allResults += $variableResults
    }
    catch {
        Write-Warning "Failed to analyze variable groups: $($_.Exception.Message)"
    }
    
    # Export results to CSV
    Write-Host "Exporting results to: $OutputPath" -ForegroundColor Green
    $allResults | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    
    Write-Host "Pipeline permissions extraction completed successfully!" -ForegroundColor Green
    Write-Host "Total items extracted: $($allResults.Count)" -ForegroundColor Cyan
    Write-Host "Output saved to: $OutputPath" -ForegroundColor Cyan
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}
