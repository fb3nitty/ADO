

<#
.SYNOPSIS
    Extracts organization-level permissions from Azure DevOps Services
.DESCRIPTION
    This script connects to Azure DevOps Services and extracts organization-level permissions,
    security groups, and user assignments for audit and documentation purposes.
.PARAMETER OrganizationUrl
    The URL of your Azure DevOps organization (e.g., https://dev.azure.com/yourorg)
.PARAMETER PersonalAccessToken
    Personal Access Token with appropriate permissions to read organization settings
.PARAMETER OutputPath
    Path where the output CSV file will be saved
.EXAMPLE
    .\Get-AzureDevOpsOrgPermissions.ps1 -OrganizationUrl "https://dev.azure.com/myorg" -PersonalAccessToken $pat -OutputPath "C:\Reports\org_permissions.csv"
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OrganizationUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$PersonalAccessToken,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\org_permissions_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
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

# Main execution
try {
    Write-Host "Starting Azure DevOps Organization Permissions Extraction..." -ForegroundColor Green
    
    # Validate organization URL format
    if ($OrganizationUrl -notmatch "^https://dev\.azure\.com/[^/]+/?$") {
        throw "Invalid organization URL format. Expected: https://dev.azure.com/yourorg"
    }
    
    $orgName = ($OrganizationUrl -split "/")[-1].TrimEnd("/")
    $headers = Get-AuthHeader -Token $PersonalAccessToken
    
    # Initialize results array
    $results = @()
    
    Write-Host "Extracting organization-level security groups..." -ForegroundColor Yellow
    
    # Get organization security groups using correct Graph API base URL
    $groupsUri = "https://vssps.dev.azure.com/$orgName/_apis/graph/groups?api-version=7.1-preview.1"
    $groups = Invoke-AzureDevOpsApi -Uri $groupsUri -Headers $headers
    
    if ($groups -and $groups.value) {
        Write-Host "Found $($groups.value.Count) groups to process" -ForegroundColor Cyan
        
        foreach ($group in $groups.value) {
            try {
                # Get group members using correct Graph API base URL
                $membersUri = "https://vssps.dev.azure.com/$orgName/_apis/graph/memberships/$($group.descriptor)?direction=down&api-version=7.1-preview.1"
                $members = Invoke-AzureDevOpsApi -Uri $membersUri -Headers $headers
                
                $memberCount = if ($members -and $members.value) { $members.value.Count } else { 0 }
                
                $results += [PSCustomObject]@{
                    GroupName = $group.displayName
                    GroupType = $group.subjectKind
                    Description = $group.description
                    MemberCount = $memberCount
                    IsProjectLevel = $false
                    Scope = "Organization"
                    LastModified = $group.lastModifiedDate
                    Descriptor = $group.descriptor
                    Origin = $group.origin
                    OriginId = $group.originId
                }
            }
            catch {
                Write-Warning "Failed to process group '$($group.displayName)': $($_.Exception.Message)"
            }
        }
    }
    else {
        Write-Warning "No groups found or failed to retrieve groups"
    }
    
    Write-Host "Extracting organization-level users..." -ForegroundColor Yellow
    
    # Get organization users using correct Graph API base URL
    $usersUri = "https://vssps.dev.azure.com/$orgName/_apis/graph/users?api-version=7.1-preview.1"
    $users = Invoke-AzureDevOpsApi -Uri $usersUri -Headers $headers
    
    if ($users -and $users.value) {
        Write-Host "Found $($users.value.Count) users to process" -ForegroundColor Cyan
        
        foreach ($user in $users.value) {
            try {
                # Get user's group memberships using correct Graph API base URL
                $membershipUri = "https://vssps.dev.azure.com/$orgName/_apis/graph/memberships/$($user.descriptor)?direction=up&api-version=7.1-preview.1"
                $memberships = Invoke-AzureDevOpsApi -Uri $membershipUri -Headers $headers
                
                $groupMemberships = if ($memberships -and $memberships.value) {
                    ($memberships.value | ForEach-Object { $_.containerDescriptor }) -join "; "
                } else { "None" }
                
                $results += [PSCustomObject]@{
                    UserName = $user.displayName
                    UserEmail = $user.mailAddress
                    UserType = $user.subjectKind
                    Origin = $user.origin
                    OriginId = $user.originId
                    PrincipalName = $user.principalName
                    GroupMemberships = $groupMemberships
                    LastAccessed = $user.lastAccessedDate
                    Scope = "Organization"
                    Status = "Active"
                    Descriptor = $user.descriptor
                }
            }
            catch {
                Write-Warning "Failed to process user '$($user.displayName)': $($_.Exception.Message)"
            }
        }
    }
    else {
        Write-Warning "No users found or failed to retrieve users"
    }
    
    Write-Host "Extracting organization settings and policies..." -ForegroundColor Yellow
    
    # Get organization policies using stable API version
    $policiesUri = "$OrganizationUrl/_apis/policy/configurations?api-version=7.1"
    $policies = Invoke-AzureDevOpsApi -Uri $policiesUri -Headers $headers
    
    if ($policies -and $policies.value) {
        Write-Host "Found $($policies.value.Count) policies to process" -ForegroundColor Cyan
        
        foreach ($policy in $policies.value) {
            try {
                $results += [PSCustomObject]@{
                    PolicyName = $policy.type.displayName
                    PolicyType = $policy.type.id
                    PolicyId = $policy.id
                    IsEnabled = $policy.isEnabled
                    IsBlocking = $policy.isBlocking
                    Scope = "Organization"
                    Settings = if ($policy.settings) { ($policy.settings | ConvertTo-Json -Compress -Depth 3) } else { "N/A" }
                    CreatedDate = $policy.createdDate
                    ModifiedDate = if ($policy.revision) { $policy.revision.revisionDate } else { $policy.createdDate }
                    CreatedBy = if ($policy.createdBy) { $policy.createdBy.displayName } else { "Unknown" }
                }
            }
            catch {
                Write-Warning "Failed to process policy '$($policy.type.displayName)': $($_.Exception.Message)"
            }
        }
    }
    else {
        Write-Warning "No policies found or failed to retrieve policies"
    }
    
    # Export results to CSV
    if ($results.Count -gt 0) {
        Write-Host "Exporting results to: $OutputPath" -ForegroundColor Green
        $results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        
        Write-Host "Organization permissions extraction completed successfully!" -ForegroundColor Green
        Write-Host "Total items extracted: $($results.Count)" -ForegroundColor Cyan
        Write-Host "Output saved to: $OutputPath" -ForegroundColor Cyan
        
        # Summary by type
        $groupCount = ($results | Where-Object { $_.PSObject.Properties.Name -contains 'GroupName' }).Count
        $userCount = ($results | Where-Object { $_.PSObject.Properties.Name -contains 'UserName' }).Count
        $policyCount = ($results | Where-Object { $_.PSObject.Properties.Name -contains 'PolicyName' }).Count
        
        Write-Host "Summary:" -ForegroundColor Yellow
        Write-Host "  Groups: $groupCount" -ForegroundColor Cyan
        Write-Host "  Users: $userCount" -ForegroundColor Cyan
        Write-Host "  Policies: $policyCount" -ForegroundColor Cyan
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

