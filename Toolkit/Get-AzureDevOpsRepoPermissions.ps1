

<#
.SYNOPSIS
    Extracts repository-level permissions and branch policies from Azure DevOps Services
.DESCRIPTION
    This script connects to Azure DevOps Services and extracts repository permissions,
    branch policies, and security settings for audit and documentation purposes.
.PARAMETER OrganizationUrl
    The URL of your Azure DevOps organization (e.g., https://dev.azure.com/yourorg)
.PARAMETER ProjectName
    Name of the specific project to analyze
.PARAMETER RepositoryName
    Name of specific repository (optional - if not provided, analyzes all repositories in project)
.PARAMETER PersonalAccessToken
    Personal Access Token with appropriate permissions to read repository settings
.PARAMETER OutputPath
    Path where the output CSV file will be saved
.EXAMPLE
    .\Get-AzureDevOpsRepoPermissions.ps1 -OrganizationUrl "https://dev.azure.com/myorg" -ProjectName "MyProject" -PersonalAccessToken $pat
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OrganizationUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$false)]
    [string]$RepositoryName,
    
    [Parameter(Mandatory=$true)]
    [string]$PersonalAccessToken,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\repo_permissions_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
)

# Function to create authentication header
function Get-AuthHeader {
    param([string]$Token)
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Token"))
    return @{Authorization = "Basic $base64AuthInfo"}
}

# Function to make REST API calls with enhanced error handling
function Invoke-AzureDevOpsApi {
    param(
        [string]$Uri,
        [hashtable]$Headers,
        [string]$Method = "GET"
    )
    
    try {
        Write-Verbose "Making API call to: $Uri"
        $response = Invoke-RestMethod -Uri $Uri -Headers $Headers -Method $Method -ContentType "application/json"
        
        # Check if response is empty or null
        if ($null -eq $response) {
            Write-Warning "API call returned null response for: $Uri"
            return $null
        }
        
        # Check if response has expected structure
        if ($response.PSObject.Properties.Name -contains 'value' -and $null -eq $response.value) {
            Write-Warning "API call returned empty value array for: $Uri"
        }
        
        return $response
    }
    catch {
        $statusCode = $_.Exception.Response.StatusCode.value__ -as [int]
        $statusDescription = $_.Exception.Response.StatusDescription
        Write-Error "API call failed for $Uri - Status: $statusCode $statusDescription - Error: $($_.Exception.Message)"
        return $null
    }
}

# Function to analyze repository permissions and policies
function Get-RepositoryPermissions {
    param(
        [string]$OrgUrl,
        [string]$Project,
        [string]$Repository,
        [hashtable]$Headers
    )
    
    $repoResults = @()
    
    Write-Host "    Analyzing repository: $Repository" -ForegroundColor Cyan
    
    try {
        # Get repository details using stable API version
        $repoUri = "$OrgUrl/$Project/_apis/git/repositories/$Repository?api-version=7.1"
        $repoInfo = Invoke-AzureDevOpsApi -Uri $repoUri -Headers $Headers
        
        if (-not $repoInfo) {
            Write-Warning "Could not retrieve repository information for $Repository"
            return $repoResults
        }
        
        # Get repository permissions (Git namespace) with proper error handling
        $gitNamespaceId = "2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87"
        $aclUri = "$OrgUrl/_apis/accesscontrollists/$gitNamespaceId?api-version=7.1"
        $acls = Invoke-AzureDevOpsApi -Uri $aclUri -Headers $Headers
        
        if ($acls -and $acls.value) {
            Write-Verbose "Processing $($acls.value.Count) ACL entries for repository $Repository"
            
            foreach ($acl in $acls.value) {
                # Check if this ACL applies to our repository
                if ($acl.token -like "*$($repoInfo.id)*") {
                    if ($acl.acesDictionary -and $acl.acesDictionary.PSObject.Properties.Count -gt 0) {
                        foreach ($ace in $acl.acesDictionary.PSObject.Properties) {
                            try {
                                $repoResults += [PSCustomObject]@{
                                    ProjectName = $Project
                                    RepositoryName = $Repository
                                    RepositoryId = $repoInfo.id
                                    SecurityToken = $acl.token
                                    IdentityDescriptor = $ace.Name
                                    Allow = $ace.Value.allow
                                    Deny = $ace.Value.deny
                                    PermissionType = "Repository"
                                    InheritPermissions = $acl.inheritPermissions
                                    LastModified = $repoInfo.lastModifiedDate
                                    DefaultBranch = $repoInfo.defaultBranch
                                    Size = $repoInfo.size
                                    IsDisabled = $repoInfo.isDisabled
                                    RemoteUrl = $repoInfo.remoteUrl
                                }
                            }
                            catch {
                                Write-Warning "Failed to process ACE for repository $Repository : $($_.Exception.Message)"
                            }
                        }
                    }
                    else {
                        Write-Verbose "No ACEs found in ACL for repository $Repository"
                    }
                }
            }
        }
        else {
            Write-Warning "No ACLs found for Git namespace or failed to retrieve ACLs"
        }
        
        # Get branch policies using stable API version
        $policiesUri = "$OrgUrl/$Project/_apis/policy/configurations?repositoryId=$($repoInfo.id)&api-version=7.1"
        $policies = Invoke-AzureDevOpsApi -Uri $policiesUri -Headers $Headers
        
        if ($policies -and $policies.value) {
            Write-Verbose "Processing $($policies.value.Count) policies for repository $Repository"
            
            foreach ($policy in $policies.value) {
                try {
                    $branchName = "All Branches"
                    if ($policy.settings -and $policy.settings.scope -and $policy.settings.scope[0] -and $policy.settings.scope[0].refName) {
                        $branchName = $policy.settings.scope[0].refName -replace "refs/heads/", ""
                    }
                    
                    $repoResults += [PSCustomObject]@{
                        ProjectName = $Project
                        RepositoryName = $Repository
                        RepositoryId = $repoInfo.id
                        PolicyType = if ($policy.type) { $policy.type.displayName } else { "Unknown" }
                        PolicyId = $policy.id
                        BranchName = $branchName
                        IsEnabled = $policy.isEnabled
                        IsBlocking = $policy.isBlocking
                        PermissionType = "BranchPolicy"
                        Settings = if ($policy.settings) { ($policy.settings | ConvertTo-Json -Compress -Depth 3) } else { "N/A" }
                        CreatedDate = $policy.createdDate
                        ModifiedDate = if ($policy.revision) { $policy.revision.revisionDate } else { $policy.createdDate }
                        CreatedBy = if ($policy.createdBy) { $policy.createdBy.displayName } else { "Unknown" }
                    }
                }
                catch {
                    Write-Warning "Failed to process policy for repository $Repository : $($_.Exception.Message)"
                }
            }
        }
        else {
            Write-Verbose "No branch policies found for repository $Repository"
        }
        
        # Get branch security (for protected branches) with improved error handling
        $branchesUri = "$OrgUrl/$Project/_apis/git/repositories/$Repository/refs?filter=heads&api-version=7.1"
        $branches = Invoke-AzureDevOpsApi -Uri $branchesUri -Headers $Headers
        
        if ($branches -and $branches.value) {
            Write-Verbose "Processing branch security for $($branches.value.Count) branches in repository $Repository"
            
            # Limit to first 10 branches to avoid too much data
            $branchesToProcess = $branches.value | Select-Object -First 10
            
            foreach ($branch in $branchesToProcess) {
                try {
                    $branchName = $branch.name -replace "refs/heads/", ""
                    $branchToken = "repoV2/$($repoInfo.id)/refs/heads/$branchName"
                    
                    # Check if this branch has specific permissions
                    if ($acls -and $acls.value) {
                        $branchAcl = $acls.value | Where-Object { $_.token -eq $branchToken }
                        if ($branchAcl) {
                            $repoResults += [PSCustomObject]@{
                                ProjectName = $Project
                                RepositoryName = $Repository
                                RepositoryId = $repoInfo.id
                                BranchName = $branchName
                                BranchObjectId = $branch.objectId
                                PermissionType = "BranchSecurity"
                                HasSpecificPermissions = $true
                                InheritPermissions = $branchAcl.inheritPermissions
                                AceCount = if ($branchAcl.acesDictionary) { $branchAcl.acesDictionary.PSObject.Properties.Count } else { 0 }
                                LastCommitDate = $branch.creator.date
                            }
                        }
                    }
                }
                catch {
                    Write-Warning "Failed to process branch security for branch $branchName in repository $Repository : $($_.Exception.Message)"
                }
            }
        }
        else {
            Write-Verbose "No branches found for repository $Repository"
        }
    }
    catch {
        Write-Error "Failed to analyze repository $Repository : $($_.Exception.Message)"
    }
    
    return $repoResults
}

# Main execution
try {
    Write-Host "Starting Azure DevOps Repository Permissions Extraction..." -ForegroundColor Green
    
    # Validate organization URL format
    if ($OrganizationUrl -notmatch "^https://dev\.azure\.com/[^/]+/?$") {
        throw "Invalid organization URL format. Expected: https://dev.azure.com/yourorg"
    }
    
    $headers = Get-AuthHeader -Token $PersonalAccessToken
    $allResults = @()
    
    Write-Host "Analyzing project: $ProjectName" -ForegroundColor Yellow
    
    # Get list of repositories to analyze
    if ($RepositoryName) {
        $repositoriesToAnalyze = @($RepositoryName)
        Write-Host "  Analyzing specific repository: $RepositoryName" -ForegroundColor Green
    } else {
        Write-Host "  Getting list of all repositories..." -ForegroundColor Yellow
        $reposUri = "$OrganizationUrl/$ProjectName/_apis/git/repositories?api-version=7.1"
        $repositories = Invoke-AzureDevOpsApi -Uri $reposUri -Headers $headers
        
        if ($repositories -and $repositories.value -and $repositories.value.Count -gt 0) {
            $repositoriesToAnalyze = $repositories.value | ForEach-Object { $_.name }
            Write-Host "  Found $($repositoriesToAnalyze.Count) repository(ies) to analyze" -ForegroundColor Green
        } else {
            throw "No repositories found or unable to retrieve repositories list for project $ProjectName"
        }
    }
    
    # Analyze each repository
    $processedCount = 0
    foreach ($repository in $repositoriesToAnalyze) {
        try {
            $processedCount++
            Write-Host "  Processing repository $processedCount of $($repositoriesToAnalyze.Count)" -ForegroundColor Yellow
            
            $repoResults = Get-RepositoryPermissions -OrgUrl $OrganizationUrl -Project $ProjectName -Repository $repository -Headers $headers
            
            if ($repoResults -and $repoResults.Count -gt 0) {
                $allResults += $repoResults
                Write-Host "    Added $($repoResults.Count) items for repository $repository" -ForegroundColor Cyan
            }
            else {
                Write-Warning "No data extracted for repository '$repository'"
            }
        }
        catch {
            Write-Warning "Failed to analyze repository '$repository': $($_.Exception.Message)"
        }
    }
    
    # Export results to CSV
    if ($allResults.Count -gt 0) {
        Write-Host "Exporting results to: $OutputPath" -ForegroundColor Green
        $allResults | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        
        Write-Host "Repository permissions extraction completed successfully!" -ForegroundColor Green
        Write-Host "Total items extracted: $($allResults.Count)" -ForegroundColor Cyan
        Write-Host "Repositories analyzed: $($repositoriesToAnalyze.Count)" -ForegroundColor Cyan
        Write-Host "Output saved to: $OutputPath" -ForegroundColor Cyan
        
        # Summary by type
        $repoPermCount = ($allResults | Where-Object { $_.PermissionType -eq "Repository" }).Count
        $policyCount = ($allResults | Where-Object { $_.PermissionType -eq "BranchPolicy" }).Count
        $branchSecCount = ($allResults | Where-Object { $_.PermissionType -eq "BranchSecurity" }).Count
        
        Write-Host "Summary:" -ForegroundColor Yellow
        Write-Host "  Repository Permissions: $repoPermCount" -ForegroundColor Cyan
        Write-Host "  Branch Policies: $policyCount" -ForegroundColor Cyan
        Write-Host "  Branch Security Settings: $branchSecCount" -ForegroundColor Cyan
    }
    else {
        Write-Warning "No data was extracted. Please check your permissions, project name, and repository access."
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}

