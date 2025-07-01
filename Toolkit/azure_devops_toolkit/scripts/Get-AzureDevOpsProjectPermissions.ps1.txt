
<#
.SYNOPSIS
    Extracts project-level permissions from Azure DevOps Services
.DESCRIPTION
    This script connects to Azure DevOps Services and extracts project-level permissions,
    security groups, teams, and user assignments for audit and documentation purposes.
.PARAMETER OrganizationUrl
    The URL of your Azure DevOps organization (e.g., https://dev.azure.com/yourorg)
.PARAMETER ProjectName
    Name of the specific project to analyze (optional - if not provided, analyzes all projects)
.PARAMETER PersonalAccessToken
    Personal Access Token with appropriate permissions to read project settings
.PARAMETER OutputPath
    Path where the output CSV file will be saved
.EXAMPLE
    .\Get-AzureDevOpsProjectPermissions.ps1 -OrganizationUrl "https://dev.azure.com/myorg" -ProjectName "MyProject" -PersonalAccessToken $pat
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OrganizationUrl,
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectName,
    
    [Parameter(Mandatory=$true)]
    [string]$PersonalAccessToken,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\project_permissions_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
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

# Function to get project security groups and permissions
function Get-ProjectPermissions {
    param(
        [string]$OrgUrl,
        [string]$Project,
        [hashtable]$Headers
    )
    
    $projectResults = @()
    
    Write-Host "  Analyzing project: $Project" -ForegroundColor Cyan
    
    # Get project details
    $projectUri = "$OrgUrl/_apis/projects/$Project?api-version=7.1-preview.4"
    $projectInfo = Invoke-AzureDevOpsApi -Uri $projectUri -Headers $Headers
    
    # Get project security groups
    $groupsUri = "$OrgUrl/_apis/graph/groups?scopeDescriptor=$($projectInfo.id)&api-version=7.1-preview.1"
    $groups = Invoke-AzureDevOpsApi -Uri $groupsUri -Headers $Headers
    
    if ($groups -and $groups.value) {
        foreach ($group in $groups.value) {
            # Get group members
            $membersUri = "$OrgUrl/_apis/graph/memberships/$($group.descriptor)?direction=down&api-version=7.1-preview.1"
            $members = Invoke-AzureDevOpsApi -Uri $membersUri -Headers $Headers
            
            $memberCount = if ($members -and $members.value) { $members.value.Count } else { 0 }
            
            $projectResults += [PSCustomObject]@{
                ProjectName = $Project
                GroupName = $group.displayName
                GroupType = $group.subjectKind
                Description = $group.description
                MemberCount = $memberCount
                IsTeam = $group.displayName -like "*Team*"
                Scope = "Project"
                LastModified = $group.lastModifiedDate
                ProjectId = $projectInfo.id
                ProjectState = $projectInfo.state
            }
        }
    }
    
    # Get project teams
    $teamsUri = "$OrgUrl/_apis/projects/$Project/teams?api-version=7.1-preview.3"
    $teams = Invoke-AzureDevOpsApi -Uri $teamsUri -Headers $Headers
    
    if ($teams -and $teams.value) {
        foreach ($team in $teams.value) {
            # Get team members
            $teamMembersUri = "$OrgUrl/_apis/projects/$Project/teams/$($team.id)/members?api-version=7.1-preview.2"
            $teamMembers = Invoke-AzureDevOpsApi -Uri $teamMembersUri -Headers $Headers
            
            $memberCount = if ($teamMembers -and $teamMembers.value) { $teamMembers.value.Count } else { 0 }
            
            $projectResults += [PSCustomObject]@{
                ProjectName = $Project
                TeamName = $team.name
                TeamId = $team.id
                Description = $team.description
                MemberCount = $memberCount
                Scope = "Team"
                ProjectId = $projectInfo.id
                ProjectState = $projectInfo.state
            }
        }
    }
    
    # Get project-level permissions for key security namespaces
    $securityNamespaces = @(
        @{Name="Project"; NamespaceId="52d39943-cb85-4d7f-8fa8-c6baac873819"},
        @{Name="Git Repositories"; NamespaceId="2e9eb7ed-3c0a-47d4-87c1-0ffdd275fd87"},
        @{Name="Build"; NamespaceId="33344d9c-fc72-4d6f-aba5-fa317101a7e9"},
        @{Name="Release"; NamespaceId="c788c23e-1b46-4162-8f5e-d7585343b5de"}
    )
    
    foreach ($namespace in $securityNamespaces) {
        $aclUri = "$OrgUrl/_apis/accesscontrollists/$($namespace.NamespaceId)?api-version=7.1-preview.1"
        $acls = Invoke-AzureDevOpsApi -Uri $aclUri -Headers $Headers
        
        if ($acls -and $acls.value) {
            foreach ($acl in $acls.value) {
                if ($acl.token -like "*$($projectInfo.id)*") {
                    $projectResults += [PSCustomObject]@{
                        ProjectName = $Project
                        SecurityNamespace = $namespace.Name
                        Token = $acl.token
                        InheritPermissions = $acl.inheritPermissions
                        AceCount = if ($acl.acesDictionary) { $acl.acesDictionary.Count } else { 0 }
                        Scope = "Security"
                        ProjectId = $projectInfo.id
                    }
                }
            }
        }
    }
    
    return $projectResults
}

# Main execution
try {
    Write-Host "Starting Azure DevOps Project Permissions Extraction..." -ForegroundColor Green
    
    # Validate organization URL format
    if ($OrganizationUrl -notmatch "^https://dev\.azure\.com/[^/]+/?$") {
        throw "Invalid organization URL format. Expected: https://dev.azure.com/yourorg"
    }
    
    $headers = Get-AuthHeader -Token $PersonalAccessToken
    $allResults = @()
    
    # Get list of projects to analyze
    if ($ProjectName) {
        $projectsToAnalyze = @($ProjectName)
    } else {
        Write-Host "Getting list of all projects..." -ForegroundColor Yellow
        $projectsUri = "$OrganizationUrl/_apis/projects?api-version=7.1-preview.4"
        $projects = Invoke-AzureDevOpsApi -Uri $projectsUri -Headers $headers
        
        if ($projects -and $projects.value) {
            $projectsToAnalyze = $projects.value | ForEach-Object { $_.name }
        } else {
            throw "No projects found or unable to retrieve projects list"
        }
    }
    
    Write-Host "Found $($projectsToAnalyze.Count) project(s) to analyze" -ForegroundColor Green
    
    # Analyze each project
    foreach ($project in $projectsToAnalyze) {
        try {
            $projectResults = Get-ProjectPermissions -OrgUrl $OrganizationUrl -Project $project -Headers $headers
            $allResults += $projectResults
        }
        catch {
            Write-Warning "Failed to analyze project '$project': $($_.Exception.Message)"
        }
    }
    
    # Export results to CSV
    Write-Host "Exporting results to: $OutputPath" -ForegroundColor Green
    $allResults | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    
    Write-Host "Project permissions extraction completed successfully!" -ForegroundColor Green
    Write-Host "Total items extracted: $($allResults.Count)" -ForegroundColor Cyan
    Write-Host "Projects analyzed: $($projectsToAnalyze.Count)" -ForegroundColor Cyan
    Write-Host "Output saved to: $OutputPath" -ForegroundColor Cyan
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    Write-Error "Stack trace: $($_.ScriptStackTrace)"
    exit 1
}
