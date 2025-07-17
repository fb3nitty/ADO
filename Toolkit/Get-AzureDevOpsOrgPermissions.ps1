<#
.SYNOPSIS
    Extracts organization and project-level group/user assignments from Azure DevOps Services.
.DESCRIPTION
    Connects to Azure DevOps Services and enumerates:
      • Org-level graph groups and their direct members
      • Org-level graph users and their group memberships
      • Per-project graph groups and their direct members
    Supports flat or hierarchical exports to CSV, Excel, and JSON.
.PARAMETER OrganizationUrl
    URL of your Azure DevOps org (e.g., https://dev.azure.com/yourorg)
.PARAMETER PersonalAccessToken
    PAT with at least Read on Graph & Projects
.PARAMETER ProjectName
    Optional. If supplied, only that project is processed; otherwise all projects.
.PARAMETER HierarchicalView
    Switch. If set, produces a hierarchical export (Projects → Groups → Users).
.PARAMETER OutputFormat
    One of: CSV (default), Excel, JSON, All
.PARAMETER OutputPath
    Base path (no extension). Default: .\AzDO_PermissionAudit_yyyyMMdd_HHmmss
#>

param(
    [Parameter(Mandatory)][string]$OrganizationUrl,
    [Parameter(Mandatory)][string]$PersonalAccessToken,
    [string]$ProjectName        = "",
    [switch]$HierarchicalView,
    [ValidateSet('CSV','Excel','JSON','All')][string]$OutputFormat = 'CSV',
    [string]$OutputPath         = ".\AzDO_PermissionAudit_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
)

function Get-AuthHeader {
    param([string]$Token)
    $b = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$Token"))
    @{ Authorization = "Basic $b" }
}

function Invoke-AzureDevOpsApi {
    param(
        [string]$Uri,
        [hashtable]$Headers
    )
    try {
        Write-Verbose "GET $Uri"
        $resp = Invoke-RestMethod -Uri $Uri -Headers $Headers -Method Get -ContentType 'application/json'
        return $resp
    }
    catch {
        $code = $_.Exception.Response.StatusCode.value__         `
        Write-Warning "API failed [$code]: $Uri"
        return $null
    }
}

function Get-OrganizationPermissions {
    param($OrgName, $Headers)
    $out = @()

    # 1. Org-level Groups
    $uri = "https://vssps.dev.azure.com/$OrgName/_apis/graph/groups?api-version=7.2-preview.1"
    $grpResp = Invoke-AzureDevOpsApi -Uri $uri -Headers $Headers
    foreach ($g in $grpResp.value) {
        # direct member count
        $mUri = "https://vssps.dev.azure.com/$OrgName/_apis/graph/memberships/$($g.descriptor)?direction=down&api-version=7.2-preview.1"
        $mResp = Invoke-AzureDevOpsApi -Uri $mUri -Headers $Headers
        $count = if ($mResp) { $mResp.value.Count } else { 0 }

        $out += [PSCustomObject]@{
            Scope           = 'Organization'
            ItemType        = 'Group'
            ProjectName     = '<Organization-Level>'
            GroupName       = $g.displayName
            Descriptor      = $g.descriptor
            Origin          = $g.origin
            SubjectKind     = $g.subjectKind
            MemberCount     = $count
            # user-specific columns blank
            UserName        = $null
            PrincipalName   = $null
            UserType        = $null
            OriginId        = $null
            GroupMemberships= $null
            LastAccessed    = $null
            Status          = $null
        }
    }

    # 2. Org-level Users
    $uUri = "https://vssps.dev.azure.com/$OrgName/_apis/graph/users?api-version=7.2-preview.1"
    $usrResp = Invoke-AzureDevOpsApi -Uri $uUri -Headers $Headers
    foreach ($u in $usrResp.value) {
        $memUri = "https://vssps.dev.azure.com/$OrgName/_apis/graph/memberships/$($u.descriptor)?direction=up&api-version=7.2-preview.1"
        $memResp = Invoke-AzureDevOpsApi -Uri $memUri -Headers $Headers
        $memberships = if ($memResp) { ($memResp.value | ForEach-Object { $_.containerDescriptor }) -join '; ' } else { '' }

        $out += [PSCustomObject]@{
            Scope           = 'Organization'
            ItemType        = 'User'
            ProjectName     = '<Organization-Level>'
            GroupName       = $null
            Descriptor      = $u.descriptor
            Origin          = $u.origin
            SubjectKind     = $u.subjectKind
            MemberCount     = $null
            UserName        = $u.displayName
            PrincipalName   = $u.principalName
            UserType        = $u.subjectKind
            OriginId        = $u.originId
            GroupMemberships= $memberships
            LastAccessed    = $u.lastAccessedDate
            Status          = 'Active'
        }
    }

    return $out
}

function Get-ProjectPermissions {
    param($OrgName, $Headers, $Project)
    $out = @()
    $pId   = $Project.id
    $pName = $Project.name

    # 1. Project-level Groups
    $gUri = "https://vssps.dev.azure.com/$OrgName/_apis/graph/groups?scopeDescriptor=Microsoft.TeamFoundation.Project%2F$pId&api-version=7.2-preview.1"
    $gResp = Invoke-AzureDevOpsApi -Uri $gUri -Headers $Headers
    foreach ($g in $gResp.value) {
        $mUri = "https://vssps.dev.azure.com/$OrgName/_apis/graph/memberships/$($g.descriptor)?direction=down&api-version=7.2-preview.1"
        $mResp = Invoke-AzureDevOpsApi -Uri $mUri -Headers $Headers
        $count = if ($mResp) { $mResp.value.Count } else { 0 }

        $out += [PSCustomObject]@{
            Scope           = 'Project'
            ItemType        = 'Group'
            ProjectName     = $pName
            GroupName       = $g.displayName
            Descriptor      = $g.descriptor
            Origin          = $g.origin
            SubjectKind     = $g.subjectKind
            MemberCount     = $count
            UserName        = $null
            PrincipalName   = $null
            UserType        = $null
            OriginId        = $null
            GroupMemberships= $null
            LastAccessed    = $null
            Status          = $null
        }

        # 2. Members of that group
        foreach ($m in $mResp.value) {
            $uUri  = "https://vssps.dev.azure.com/$OrgName/_apis/graph/users/$($m.memberDescriptor)?api-version=7.2-preview.1"
            $uResp = Invoke-AzureDevOpsApi -Uri $uUri -Headers $Headers
            if ($uResp) {
                $out += [PSCustomObject]@{
                    Scope           = 'Project'
                    ItemType        = 'User'
                    ProjectName     = $pName
                    GroupName       = $g.displayName
                    Descriptor      = $uResp.descriptor
                    Origin          = $uResp.origin
                    SubjectKind     = $uResp.subjectKind
                    MemberCount     = $null
                    UserName        = $uResp.displayName
                    PrincipalName   = $uResp.principalName
                    UserType        = $uResp.subjectKind
                    OriginId        = $uResp.originId
                    GroupMemberships= $g.descriptor
                    LastAccessed    = $uResp.lastAccessedDate
                    Status          = 'Active'
                }
            }
        }
    }

    return $out
}

# Hierarchical builder and exports (unchanged—policies simply won't appear)
# ... (reuse your existing Build-HierarchicalStructure, Export-HierarchicalCSV/JSON/Excel) ...

# ------ Main ------

# Validate org URL
if ($OrganizationUrl -notmatch '^https://dev\.azure\.com/[^/]+/?$') {
    throw "Org URL must be https://dev.azure.com/yourorg"
}
$orgName = ($OrganizationUrl -split '/')[ -1 ].TrimEnd('/')
$headers = Get-AuthHeader -Token $PersonalAccessToken

# Collect
$all = @()
$all += Get-OrganizationPermissions -OrgName $orgName -Headers $headers

# Projects
if ($ProjectName) {
    $pUri = "$OrganizationUrl/_apis/projects/$ProjectName?api-version=7.2"
    $proj = Invoke-AzureDevOpsApi -Uri $pUri -Headers $headers
    if ($proj) { $all += Get-ProjectPermissions -OrgName $orgName -Headers $headers -Project $proj }
}
else {
    $plist = Invoke-AzureDevOpsApi -Uri "$OrganizationUrl/_apis/projects?api-version=7.2" -Headers $headers
    foreach ($p in $plist.value) {
        $all += Get-ProjectPermissions -OrgName $orgName -Headers $headers -Project $p
    }
}

# Export
switch ($OutputFormat) {
    'CSV'   { $all | Export-Csv -Path "$OutputPath.csv" -NoTypeInformation -Encoding UTF8 }
    'JSON'  { $all | ConvertTo-Json -Depth 5 | Out-File "$OutputPath.json" -Encoding UTF8 }
    'Excel' { $all | Export-Excel -Path "$OutputPath.xlsx" -AutoSize -WorksheetName 'Data' }
    'All'   {
        $all | Export-Csv  -Path "$OutputPath.csv"  -NoTypeInformation -Encoding UTF8
        $all | ConvertTo-Json -Depth 5 | Out-File "$OutputPath.json" -Encoding UTF8
        $all | Export-Excel -Path "$OutputPath.xlsx" -AutoSize -WorksheetName 'Data'
    }
}

Write-Host "✅ Permission extraction complete. Output at: $OutputPath.*"
