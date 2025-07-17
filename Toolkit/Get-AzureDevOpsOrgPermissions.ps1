


<#
.SYNOPSIS
    Extracts organization-level permissions from Azure DevOps Services with optional project-specific information
.DESCRIPTION
    This script connects to Azure DevOps Services and extracts organization-level permissions,
    security groups, and user assignments for audit and documentation purposes. It can optionally
    include project-specific permissions and context in the output.
.PARAMETER OrganizationUrl
    The URL of your Azure DevOps organization (e.g., https://dev.azure.com/yourorg)
.PARAMETER PersonalAccessToken
    Personal Access Token with appropriate permissions to read organization settings
.PARAMETER OutputPath
    Path where the output CSV file will be saved
.PARAMETER ProjectName
    Optional. Specific project name to include project-level permissions. If not provided, 
    all projects will be processed to include project-level permissions alongside organization permissions.
.EXAMPLE
    .\Get-AzureDevOpsOrgPermissions.ps1 -OrganizationUrl "https://dev.azure.com/myorg" -PersonalAccessToken $pat -OutputPath "C:\Reports\org_permissions.csv"
.EXAMPLE
    .\Get-AzureDevOpsOrgPermissions.ps1 -OrganizationUrl "https://dev.azure.com/myorg" -PersonalAccessToken $pat -ProjectName "MyProject" -OutputPath "C:\Reports\org_permissions.csv"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OrganizationUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$PersonalAccessToken,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\org_permissions_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv",
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = ""
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

# Function to process organization-level permissions
function Get-OrganizationPermissions {
    param(
        [string]$OrgName,
        [hashtable]$Headers,
        [string]$OrganizationUrl
    )
    
    $orgResults = @()
    
    Write-Host "Extracting organization-level security groups..." -ForegroundColor Yellow
    
    # Get organization security groups using correct Graph API base URL
    $groupsUri = "https://vssps.dev.azure.com/$OrgName/_apis/graph/groups?api-version=7.1-preview.1"
    $groups = Invoke-AzureDevOpsApi -Uri $groupsUri -Headers $Headers
    
    if ($groups -and $groups.value) {
        Write-Host "Found $($groups.value.Count) organization groups to process" -ForegroundColor Cyan
        
        foreach ($group in $groups.value) {
            try {
                # Get group members using correct Graph API base URL
                $membersUri = "https://vssps.dev.azure.com/$OrgName/_apis/graph/memberships/$($group.descriptor)?direction=down&api-version=7.1-preview.1"
                $members = Invoke-AzureDevOpsApi -Uri $membersUri -Headers $Headers
                
                $memberCount = if ($members -and $members.value) { $members.value.Count } else { 0 }
                
                $orgResults += [PSCustomObject]@{
                    ProjectName = "<Organization-Level>"
                    Scope = "Organization"
                    ItemType = "Group"
                    GroupName = $group.displayName
                    GroupType = $group.subjectKind
                    Description = $group.description
                    MemberCount = $memberCount
                    IsProjectLevel = $false
                    LastModified = $group.lastModifiedDate
                    Descriptor = $group.descriptor
                    Origin = $group.origin
                    OriginId = $group.originId
                    UserName = $null
                    UserEmail = $null
                    UserType = $null
                    PrincipalName = $null
                    GroupMemberships = $null
                    LastAccessed = $null
                    Status = $null
                    PolicyName = $null
                    PolicyType = $null
                    PolicyId = $null
                    IsEnabled = $null
                    IsBlocking = $null
                    Settings = $null
                    CreatedDate = $null
                    ModifiedDate = $null
                    CreatedBy = $null
                }
            }
            catch {
                Write-Warning "Failed to process organization group '$($group.displayName)': $($_.Exception.Message)"
            }
        }
    }
    else {
        Write-Warning "No organization groups found or failed to retrieve groups"
    }
    
    Write-Host "Extracting organization-level users..." -ForegroundColor Yellow
    
    # Get organization users using correct Graph API base URL
    $usersUri = "https://vssps.dev.azure.com/$OrgName/_apis/graph/users?api-version=7.1-preview.1"
    $users = Invoke-AzureDevOpsApi -Uri $usersUri -Headers $Headers
    
    if ($users -and $users.value) {
        Write-Host "Found $($users.value.Count) organization users to process" -ForegroundColor Cyan
        
        foreach ($user in $users.value) {
            try {
                # Get user's group memberships using correct Graph API base URL
                $membershipUri = "https://vssps.dev.azure.com/$OrgName/_apis/graph/memberships/$($user.descriptor)?direction=up&api-version=7.1-preview.1"
                $memberships = Invoke-AzureDevOpsApi -Uri $membershipUri -Headers $Headers
                
                $groupMemberships = if ($memberships -and $memberships.value) {
                    ($memberships.value | ForEach-Object { $_.containerDescriptor }) -join "; "
                } else { "None" }
                
                $orgResults += [PSCustomObject]@{
                    ProjectName = "<Organization-Level>"
                    Scope = "Organization"
                    ItemType = "User"
                    UserName = $user.displayName
                    UserEmail = $user.mailAddress
                    UserType = $user.subjectKind
                    Origin = $user.origin
                    OriginId = $user.originId
                    PrincipalName = $user.principalName
                    GroupMemberships = $groupMemberships
                    LastAccessed = $user.lastAccessedDate
                    Status = "Active"
                    Descriptor = $user.descriptor
                    GroupName = $null
                    GroupType = $null
                    Description = $null
                    MemberCount = $null
                    IsProjectLevel = $false
                    LastModified = $null
                    PolicyName = $null
                    PolicyType = $null
                    PolicyId = $null
                    IsEnabled = $null
                    IsBlocking = $null
                    Settings = $null
                    CreatedDate = $null
                    ModifiedDate = $null
                    CreatedBy = $null
                }
            }
            catch {
                Write-Warning "Failed to process organization user '$($user.displayName)': $($_.Exception.Message)"
            }
        }
    }
    else {
        Write-Warning "No organization users found or failed to retrieve users"
    }
    
    Write-Host "Extracting organization settings and policies..." -ForegroundColor Yellow
    
    # Get organization policies using stable API version
    $policiesUri = "$OrganizationUrl/_apis/policy/configurations?api-version=7.1"
    $policies = Invoke-AzureDevOpsApi -Uri $policiesUri -Headers $Headers
    
    if ($policies -and $policies.value) {
        Write-Host "Found $($policies.value.Count) organization policies to process" -ForegroundColor Cyan
        
        foreach ($policy in $policies.value) {
            try {
                $orgResults += [PSCustomObject]@{
                    ProjectName = "<Organization-Level>"
                    Scope = "Organization"
                    ItemType = "Policy"
                    PolicyName = $policy.type.displayName
                    PolicyType = $policy.type.id
                    PolicyId = $policy.id
                    IsEnabled = $policy.isEnabled
                    IsBlocking = $policy.isBlocking
                    Settings = if ($policy.settings) { ($policy.settings | ConvertTo-Json -Compress -Depth 3) } else { "N/A" }
                    CreatedDate = $policy.createdDate
                    ModifiedDate = if ($policy.revision) { $policy.revision.revisionDate } else { $policy.createdDate }
                    CreatedBy = if ($policy.createdBy) { $policy.createdBy.displayName } else { "Unknown" }
                    GroupName = $null
                    GroupType = $null
                    Description = $null
                    MemberCount = $null
                    IsProjectLevel = $false
                    LastModified = $null
                    Descriptor = $null
                    Origin = $null
                    OriginId = $null
                    UserName = $null
                    UserEmail = $null
                    UserType = $null
                    PrincipalName = $null
                    GroupMemberships = $null
                    LastAccessed = $null
                    Status = $null
                }
            }
            catch {
                Write-Warning "Failed to process organization policy '$($policy.type.displayName)': $($_.Exception.Message)"
            }
        }
    }
    else {
        Write-Warning "No organization policies found or failed to retrieve policies"
    }
    
    return $orgResults
}

# Function to process project-level permissions
function Get-ProjectPermissions {
    param(
        [string]$OrgName,
        [hashtable]$Headers,
        [string]$OrganizationUrl,
        [object]$Project
    )
    
    $projectResults = @()
    $projectId = $Project.id
    $projectName = $Project.name
    
    Write-Host "Processing project: $projectName" -ForegroundColor Cyan
    
    try {
        # Get project-specific security groups
        $projectGroupsUri = "https://vssps.dev.azure.com/$OrgName/_apis/graph/groups?scopeDescriptor=$($Project.id)&api-version=7.1-preview.1"
        $projectGroups = Invoke-AzureDevOpsApi -Uri $projectGroupsUri -Headers $Headers
        
        if ($projectGroups -and $projectGroups.value) {
            foreach ($group in $projectGroups.value) {
                try {
                    # Get group members
                    $membersUri = "https://vssps.dev.azure.com/$OrgName/_apis/graph/memberships/$($group.descriptor)?direction=down&api-version=7.1-preview.1"
                    $members = Invoke-AzureDevOpsApi -Uri $membersUri -Headers $Headers
                    
                    $memberCount = if ($members -and $members.value) { $members.value.Count } else { 0 }
                    
                    $projectResults += [PSCustomObject]@{
                        ProjectName = $projectName
                        Scope = "Project"
                        ItemType = "Group"
                        GroupName = $group.displayName
                        GroupType = $group.subjectKind
                        Description = $group.description
                        MemberCount = $memberCount
                        IsProjectLevel = $true
                        LastModified = $group.lastModifiedDate
                        Descriptor = $group.descriptor
                        Origin = $group.origin
                        OriginId = $group.originId
                        UserName = $null
                        UserEmail = $null
                        UserType = $null
                        PrincipalName = $null
                        GroupMemberships = $null
                        LastAccessed = $null
                        Status = $null
                        PolicyName = $null
                        PolicyType = $null
                        PolicyId = $null
                        IsEnabled = $null
                        IsBlocking = $null
                        Settings = $null
                        CreatedDate = $null
                        ModifiedDate = $null
                        CreatedBy = $null
                    }
                }
                catch {
                    Write-Warning "Failed to process project group '$($group.displayName)' in project '$projectName': $($_.Exception.Message)"
                }
            }
        }
        
        # Get project-specific policies
        $projectPoliciesUri = "$OrganizationUrl/$projectId/_apis/policy/configurations?api-version=7.1"
        $projectPolicies = Invoke-AzureDevOpsApi -Uri $projectPoliciesUri -Headers $Headers
        
        if ($projectPolicies -and $projectPolicies.value) {
            foreach ($policy in $projectPolicies.value) {
                try {
                    $projectResults += [PSCustomObject]@{
                        ProjectName = $projectName
                        Scope = "Project"
                        ItemType = "Policy"
                        PolicyName = $policy.type.displayName
                        PolicyType = $policy.type.id
                        PolicyId = $policy.id
                        IsEnabled = $policy.isEnabled
                        IsBlocking = $policy.isBlocking
                        Settings = if ($policy.settings) { ($policy.settings | ConvertTo-Json -Compress -Depth 3) } else { "N/A" }
                        CreatedDate = $policy.createdDate
                        ModifiedDate = if ($policy.revision) { $policy.revision.revisionDate } else { $policy.createdDate }
                        CreatedBy = if ($policy.createdBy) { $policy.createdBy.displayName } else { "Unknown" }
                        GroupName = $null
                        GroupType = $null
                        Description = $null
                        MemberCount = $null
                        IsProjectLevel = $true
                        LastModified = $null
                        Descriptor = $null
                        Origin = $null
                        OriginId = $null
                        UserName = $null
                        UserEmail = $null
                        UserType = $null
                        PrincipalName = $null
                        GroupMemberships = $null
                        LastAccessed = $null
                        Status = $null
                    }
                }
                catch {
                    Write-Warning "Failed to process project policy '$($policy.type.displayName)' in project '$projectName': $($_.Exception.Message)"
                }
            }
        }
    }
    catch {
        Write-Warning "Failed to process project '$projectName': $($_.Exception.Message)"
    }
    
    return $projectResults
}

# Main execution
try {
    Write-Host "Starting Azure DevOps Organization Permissions Extraction with Project Context..." -ForegroundColor Green
    
    # Validate organization URL format
    if ($OrganizationUrl -notmatch "^https://dev\.azure\.com/[^/]+/?$") {
        throw "Invalid organization URL format. Expected: https://dev.azure.com/yourorg"
    }
    
    $orgName = ($OrganizationUrl -split "/")[-1].TrimEnd("/")
    $headers = Get-AuthHeader -Token $PersonalAccessToken
    
    # Initialize results array
    $allResults = @()
    
    # Get organization-level permissions
    $orgResults = Get-OrganizationPermissions -OrgName $orgName -Headers $headers -OrganizationUrl $OrganizationUrl
    $allResults += $orgResults
    
    # Get projects to process
    $projectsToProcess = @()
    
    if ($ProjectName -ne "") {
        # Get specific project
        Write-Host "Looking for specific project: $ProjectName" -ForegroundColor Yellow
        $projectUri = "$OrganizationUrl/_apis/projects/$ProjectName" + "?api-version=7.1"
        $project = Invoke-AzureDevOpsApi -Uri $projectUri -Headers $headers
        
        if ($project) {
            $projectsToProcess += $project
            Write-Host "Found project: $($project.name)" -ForegroundColor Cyan
        }
        else {
            Write-Warning "Project '$ProjectName' not found or access denied"
        }
    }
    else {
        # Get all projects
        Write-Host "Retrieving all projects for project-level permissions..." -ForegroundColor Yellow
        $projectsUri = "$OrganizationUrl/_apis/projects?api-version=7.1"
        $projects = Invoke-AzureDevOpsApi -Uri $projectsUri -Headers $headers
        
        if ($projects -and $projects.value) {
            $projectsToProcess = $projects.value
            Write-Host "Found $($projectsToProcess.Count) projects to process" -ForegroundColor Cyan
        }
        else {
            Write-Warning "No projects found or failed to retrieve projects"
        }
    }
    
    # Process each project
    foreach ($project in $projectsToProcess) {
        $projectResults = Get-ProjectPermissions -OrgName $orgName -Headers $headers -OrganizationUrl $OrganizationUrl -Project $project
        $allResults += $projectResults
    }
    
    # Export results to CSV with consistent column order
    if ($allResults.Count -gt 0) {
        Write-Host "Exporting results to: $OutputPath" -ForegroundColor Green
        
        # Define consistent column order for CSV output
        $orderedResults = $allResults | Select-Object ProjectName, Scope, ItemType, GroupName, GroupType, Description, MemberCount, UserName, UserEmail, UserType, PrincipalName, GroupMemberships, PolicyName, PolicyType, PolicyId, IsEnabled, IsBlocking, Settings, IsProjectLevel, LastModified, LastAccessed, CreatedDate, ModifiedDate, CreatedBy, Status, Descriptor, Origin, OriginId
        
        $orderedResults | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        
        Write-Host "Organization and project permissions extraction completed successfully!" -ForegroundColor Green
        Write-Host "Total items extracted: $($allResults.Count)" -ForegroundColor Cyan
        Write-Host "Output saved to: $OutputPath" -ForegroundColor Cyan
        
        # Enhanced summary by type and scope
        $orgGroupCount = ($allResults | Where-Object { $_.ItemType -eq 'Group' -and $_.Scope -eq 'Organization' }).Count
        $orgUserCount = ($allResults | Where-Object { $_.ItemType -eq 'User' -and $_.Scope -eq 'Organization' }).Count
        $orgPolicyCount = ($allResults | Where-Object { $_.ItemType -eq 'Policy' -and $_.Scope -eq 'Organization' }).Count
        $projectGroupCount = ($allResults | Where-Object { $_.ItemType -eq 'Group' -and $_.Scope -eq 'Project' }).Count
        $projectPolicyCount = ($allResults | Where-Object { $_.ItemType -eq 'Policy' -and $_.Scope -eq 'Project' }).Count
        $projectCount = ($allResults | Where-Object { $_.Scope -eq 'Project' } | Select-Object ProjectName -Unique).Count
        
        Write-Host "Summary:" -ForegroundColor Yellow
        Write-Host "  Organization Level:" -ForegroundColor Cyan
        Write-Host "    Groups: $orgGroupCount" -ForegroundColor White
        Write-Host "    Users: $orgUserCount" -ForegroundColor White
        Write-Host "    Policies: $orgPolicyCount" -ForegroundColor White
        Write-Host "  Project Level:" -ForegroundColor Cyan
        Write-Host "    Projects Processed: $projectCount" -ForegroundColor White
        Write-Host "    Groups: $projectGroupCount" -ForegroundColor White
        Write-Host "    Policies: $projectPolicyCount" -ForegroundColor White
    }
    else {
        Write-Warning "No data was extracted. Please check your permissions and organization URL."
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}


