<#
.SYNOPSIS
    Extracts organization-level permissions from Azure DevOps Services with optional project-specific information and hierarchical output
.DESCRIPTION
    This script connects to Azure DevOps Services and extracts organization-level permissions,
    security groups, and user assignments for audit and documentation purposes. It can optionally
    include project-specific permissions and context in the output. Enhanced with hierarchical
    structure support for better organization and analysis.
.PARAMETER OrganizationUrl
    The URL of your Azure DevOps organization (e.g., https://dev.azure.com/yourorg)
.PARAMETER PersonalAccessToken
    Personal Access Token with appropriate permissions to read organization settings
.PARAMETER OutputPath
    Path where the output file will be saved (supports .csv, .xlsx, .json extensions)
.PARAMETER ProjectName
    Optional. Specific project name to include project-level permissions. If not provided, 
    all projects will be processed to include project-level permissions alongside organization permissions.
.PARAMETER HierarchicalView
    Switch to enable hierarchical output structure (Projects → Groups → Users)
.PARAMETER OutputFormat
    Output format: 'CSV' (default), 'Excel', 'JSON', or 'All'
.EXAMPLE
    .\Get-AzureDevOpsOrgPermissions.ps1 -OrganizationUrl "https://dev.azure.com/myorg" -PersonalAccessToken $pat -OutputPath "C:\Reports\org_permissions.csv"
.EXAMPLE
    .\Get-AzureDevOpsOrgPermissions.ps1 -OrganizationUrl "https://dev.azure.com/myorg" -PersonalAccessToken $pat -ProjectName "MyProject" -OutputPath "C:\Reports\org_permissions.xlsx" -HierarchicalView
.EXAMPLE
    .\Get-AzureDevOpsOrgPermissions.ps1 -OrganizationUrl "https://dev.azure.com/myorg" -PersonalAccessToken $pat -OutputFormat "All" -HierarchicalView
#>

param(
    [Parameter(Mandatory=$true)]
    [string]$OrganizationUrl,
    
    [Parameter(Mandatory=$true)]
    [string]$PersonalAccessToken,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath = ".\org_permissions_$(Get-Date -Format 'yyyyMMdd_HHmmss')",
    
    [Parameter(Mandatory=$false)]
    [string]$ProjectName = "",
    
    [Parameter(Mandatory=$false)]
    [switch]$HierarchicalView,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('CSV', 'Excel', 'JSON', 'All')]
    [string]$OutputFormat = 'CSV'
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

# Function to build hierarchical structure
function Build-HierarchicalStructure {
    param(
        [array]$AllResults
    )
    
    $hierarchicalData = @{}
    
    # Process each result to build the hierarchy
    foreach ($result in $AllResults) {
        $projectName = if ($result.ProjectName -eq "<Organization-Level>") { "Organization-Level" } else { $result.ProjectName }
        
        # Initialize project if not exists
        if (-not $hierarchicalData.ContainsKey($projectName)) {
            $hierarchicalData[$projectName] = @{
                Groups = @{}
                Users = @()
                ProjectInfo = $result
            }
        }
        
        # Process based on item type
        switch ($result.ItemType) {
            'Group' {
                $groupName = $result.GroupName
                if (-not $hierarchicalData[$projectName].Groups.ContainsKey($groupName)) {
                    $hierarchicalData[$projectName].Groups[$groupName] = @{
                        GroupInfo = $result
                        Users = @()
                    }
                }
            }
            'User' {
                # Add user to project level and try to associate with groups
                $hierarchicalData[$projectName].Users += $result
                
                # If user has group memberships, try to add to those groups
                if ($result.GroupMemberships -and $result.GroupMemberships -ne "None") {
                    $groupDescriptors = $result.GroupMemberships -split "; "
                    foreach ($groupDescriptor in $groupDescriptors) {
                        # Find matching group by descriptor
                        $matchingGroup = $hierarchicalData[$projectName].Groups.Keys | Where-Object {
                            $hierarchicalData[$projectName].Groups[$_].GroupInfo.Descriptor -eq $groupDescriptor
                        }
                        if ($matchingGroup) {
                            $hierarchicalData[$projectName].Groups[$matchingGroup].Users += $result
                        }
                    }
                }
            }
        }
    }
    
    return $hierarchicalData
}

# Function to export hierarchical CSV
function Export-HierarchicalCSV {
    param(
        [hashtable]$HierarchicalData,
        [string]$OutputPath
    )
    
    $csvData = @()
    
    foreach ($projectName in $HierarchicalData.Keys | Sort-Object) {
        $project = $HierarchicalData[$projectName]
        
        # Add project header
        $csvData += [PSCustomObject]@{
            Level = "Project"
            ProjectName = $projectName
            GroupName = ""
            UserName = ""
            UserEmail = ""
            ItemType = "Project"
            Description = "Project: $projectName"
            MemberCount = ""
            GroupType = ""
            UserType = ""
            PrincipalName = ""
            GroupMemberships = ""
            LastAccessed = ""
            Status = ""
            Scope = if ($projectName -eq "Organization-Level") { "Organization" } else { "Project" }
            LastModified = ""
            Descriptor = ""
            Origin = ""
            OriginId = ""
        }
        
        # Add groups and their users
        foreach ($groupName in $project.Groups.Keys | Sort-Object) {
            $group = $project.Groups[$groupName]
            
            # Add group row
            $csvData += [PSCustomObject]@{
                Level = "Group"
                ProjectName = $projectName
                GroupName = $group.GroupInfo.GroupName
                UserName = ""
                UserEmail = ""
                ItemType = "Group"
                Description = $group.GroupInfo.Description
                MemberCount = $group.GroupInfo.MemberCount
                GroupType = $group.GroupInfo.GroupType
                UserType = ""
                PrincipalName = ""
                GroupMemberships = ""
                LastAccessed = ""
                Status = ""
                Scope = $group.GroupInfo.Scope
                LastModified = $group.GroupInfo.LastModified
                Descriptor = $group.GroupInfo.Descriptor
                Origin = $group.GroupInfo.Origin
                OriginId = $group.GroupInfo.OriginId
            }
            
            # Add users in this group
            foreach ($user in $group.Users) {
                $csvData += [PSCustomObject]@{
                    Level = "User"
                    ProjectName = $projectName
                    GroupName = $group.GroupInfo.GroupName
                    UserName = $user.UserName
                    UserEmail = $user.UserEmail
                    ItemType = "User"
                    Description = "User in group: $($group.GroupInfo.GroupName)"
                    MemberCount = ""
                    GroupType = ""
                    UserType = $user.UserType
                    PrincipalName = $user.PrincipalName
                    GroupMemberships = $user.GroupMemberships
                    LastAccessed = $user.LastAccessed
                    Status = $user.Status
                    Scope = $user.Scope
                    LastModified = ""
                    Descriptor = $user.Descriptor
                    Origin = $user.Origin
                    OriginId = $user.OriginId
                }
            }
        }
    }
    
    $csvData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Host "Hierarchical CSV exported to: $OutputPath" -ForegroundColor Green
}

# Function to export hierarchical JSON
function Export-HierarchicalJSON {
    param(
        [hashtable]$HierarchicalData,
        [string]$OutputPath
    )
    
    $jsonData = @{
        ExportDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Structure = "Hierarchical"
        Projects = @{}
    }
    
    foreach ($projectName in $HierarchicalData.Keys) {
        $project = $HierarchicalData[$projectName]
        
        $jsonData.Projects[$projectName] = @{
            Groups = @{}
            Summary = @{
                GroupCount = $project.Groups.Count
                TotalUsers = ($project.Groups.Values | ForEach-Object { $_.Users.Count } | Measure-Object -Sum).Sum
            }
        }
        
        foreach ($groupName in $project.Groups.Keys) {
            $group = $project.Groups[$groupName]
            $jsonData.Projects[$projectName].Groups[$groupName] = @{
                GroupInfo = $group.GroupInfo
                Users = $group.Users
                UserCount = $group.Users.Count
            }
        }
    }
    
    $jsonData | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "Hierarchical JSON exported to: $OutputPath" -ForegroundColor Green
}

# Function to export hierarchical Excel with pivot table
function Export-HierarchicalExcel {
    param(
        [hashtable]$HierarchicalData,
        [array]$AllResults,
        [string]$OutputPath
    )
    
    try {
        # Import ImportExcel module
        Import-Module ImportExcel -ErrorAction Stop
        
        # Prepare data for Excel
        $excelData = @()
        
        foreach ($projectName in $HierarchicalData.Keys | Sort-Object) {
            $project = $HierarchicalData[$projectName]
            
            foreach ($groupName in $project.Groups.Keys | Sort-Object) {
                $group = $project.Groups[$groupName]
                
                # Add group row
                $excelData += [PSCustomObject]@{
                    Project = $projectName
                    Group = $group.GroupInfo.GroupName
                    User = ""
                    ItemType = "Group"
                    GroupType = $group.GroupInfo.GroupType
                    UserType = ""
                    UserEmail = ""
                    MemberCount = $group.GroupInfo.MemberCount
                    Description = $group.GroupInfo.Description
                    Scope = $group.GroupInfo.Scope
                    LastModified = $group.GroupInfo.LastModified
                    Status = ""
                    Origin = $group.GroupInfo.Origin
                }
                
                # Add users in this group
                foreach ($user in $group.Users) {
                    $excelData += [PSCustomObject]@{
                        Project = $projectName
                        Group = $group.GroupInfo.GroupName
                        User = $user.UserName
                        ItemType = "User"
                        GroupType = ""
                        UserType = $user.UserType
                        UserEmail = $user.UserEmail
                        MemberCount = ""
                        Description = "Member of $($group.GroupInfo.GroupName)"
                        Scope = $user.Scope
                        LastModified = ""
                        Status = $user.Status
                        Origin = $user.Origin
                    }
                }
            }
        }
        
        # Export to Excel with multiple sheets and pivot table
        if ($excelData.Count -gt 0) {
            # Main data sheet
            $excelData | Export-Excel -Path $OutputPath -WorksheetName "HierarchicalData" -AutoSize -FreezeTopRow -BoldTopRow
            
            # Create pivot table
            $pivotParams = @{
                Path = $OutputPath
                WorksheetName = "PivotAnalysis"
                SourceWorksheet = "HierarchicalData"
                PivotRows = @("Project", "Group")
                PivotData = @{'User'='count'}
                PivotTableName = "ProjectGroupUserSummary"
                IncludePivotChart = $true
                ChartType = "BarClustered3D"
                ChartTitle = "Users by Project and Group"
            }
            
            Export-Excel @pivotParams
            
            # Summary sheet
            $summary = @()
            foreach ($projectName in $HierarchicalData.Keys | Sort-Object) {
                $project = $HierarchicalData[$projectName]
                $totalUsers = ($project.Groups.Values | ForEach-Object { $_.Users.Count } | Measure-Object -Sum).Sum
                
                $summary += [PSCustomObject]@{
                    Project = $projectName
                    GroupCount = $project.Groups.Count
                    UserCount = $totalUsers
                    Scope = if ($projectName -eq "Organization-Level") { "Organization" } else { "Project" }
                }
            }
            
            $summary | Export-Excel -Path $OutputPath -WorksheetName "Summary" -AutoSize -FreezeTopRow -BoldTopRow -TableStyle Medium2
            
            Write-Host "Hierarchical Excel with pivot table exported to: $OutputPath" -ForegroundColor Green
        }
        else {
            Write-Warning "No data available for Excel export"
        }
    }
    catch {
        Write-Warning "Failed to create Excel file: $($_.Exception.Message)"
        Write-Host "Falling back to CSV export..." -ForegroundColor Yellow
        Export-HierarchicalCSV -HierarchicalData $HierarchicalData -OutputPath ($OutputPath -replace '\.xlsx$', '.csv')
    }
}

# Function to process organization-level permissions with enhanced group-user relationships
function Get-OrganizationPermissions {
    param(
        [string]$OrgName,
        [hashtable]$Headers,
        [string]$OrganizationUrl
    )
    
    $orgResults = @()
    $groupUserMap = @{}
    
    Write-Host "Extracting organization-level security groups..." -ForegroundColor Yellow
    
    # Get organization security groups using updated API version
    $groupsUri = "https://vssps.dev.azure.com/$OrgName/_apis/graph/groups?api-version=7.2-preview.1"
    $groups = Invoke-AzureDevOpsApi -Uri $groupsUri -Headers $Headers
    
    if ($groups -and $groups.value) {
        Write-Host "Found $($groups.value.Count) organization groups to process" -ForegroundColor Cyan
        
        foreach ($group in $groups.value) {
            try {
                # Get group members using updated API version
                $membersUri = "https://vssps.dev.azure.com/$OrgName/_apis/graph/memberships/$($group.descriptor)?direction=down&api-version=7.2-preview.1"
                $members = Invoke-AzureDevOpsApi -Uri $membersUri -Headers $Headers
                
                $memberCount = if ($members -and $members.value) { $members.value.Count } else { 0 }
                
                # Store group-user relationships
                if ($members -and $members.value) {
                    $groupUserMap[$group.descriptor] = $members.value | ForEach-Object { $_.memberDescriptor }
                }
                
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
    
    # Get organization users using updated API version
    $usersUri = "https://vssps.dev.azure.com/$OrgName/_apis/graph/users?api-version=7.2-preview.1"
    $users = Invoke-AzureDevOpsApi -Uri $usersUri -Headers $Headers
    
    if ($users -and $users.value) {
        Write-Host "Found $($users.value.Count) organization users to process" -ForegroundColor Cyan
        
        foreach ($user in $users.value) {
            try {
                # Get user's group memberships using updated API version
                $membershipUri = "https://vssps.dev.azure.com/$OrgName/_apis/graph/memberships/$($user.descriptor)?direction=up&api-version=7.2-preview.1"
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
    
    # Removed organization-level policy API calls to eliminate 404 errors
    Write-Host "Skipping organization-level policies (not typically available at organization scope)" -ForegroundColor Yellow
    
    return $orgResults
}

# Function to process project-level permissions with enhanced group-user relationships
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
        # Get project-specific security groups using updated API version
        $projectGroupsUri = "https://vssps.dev.azure.com/$OrgName/_apis/graph/groups?scopeDescriptor=$($Project.id)&api-version=7.2-preview.1"
        $projectGroups = Invoke-AzureDevOpsApi -Uri $projectGroupsUri -Headers $Headers
        
        if ($projectGroups -and $projectGroups.value) {
            foreach ($group in $projectGroups.value) {
                try {
                    # Get group members using updated API version
                    $membersUri = "https://vssps.dev.azure.com/$OrgName/_apis/graph/memberships/$($group.descriptor)?direction=down&api-version=7.2-preview.1"
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
                        CreatedDate = $null
                        ModifiedDate = $null
                        CreatedBy = $null
                    }
                    
                    # Get users in this group
                    if ($members -and $members.value) {
                        foreach ($memberDescriptor in $members.value) {
                            try {
                                # Get user details using updated API version
                                $userUri = "https://vssps.dev.azure.com/$OrgName/_apis/graph/users/$($memberDescriptor.memberDescriptor)?api-version=7.2-preview.1"
                                $userDetail = Invoke-AzureDevOpsApi -Uri $userUri -Headers $Headers
                                
                                if ($userDetail) {
                                    $projectResults += [PSCustomObject]@{
                                        ProjectName = $projectName
                                        Scope = "Project"
                                        ItemType = "User"
                                        UserName = $userDetail.displayName
                                        UserEmail = $userDetail.mailAddress
                                        UserType = $userDetail.subjectKind
                                        Origin = $userDetail.origin
                                        OriginId = $userDetail.originId
                                        PrincipalName = $userDetail.principalName
                                        GroupMemberships = $group.descriptor
                                        LastAccessed = $userDetail.lastAccessedDate
                                        Status = "Active"
                                        Descriptor = $userDetail.descriptor
                                        GroupName = $group.displayName
                                        GroupType = $group.subjectKind
                                        Description = "Member of $($group.displayName)"
                                        MemberCount = $null
                                        IsProjectLevel = $true
                                        LastModified = $null
                                        CreatedDate = $null
                                        ModifiedDate = $null
                                        CreatedBy = $null
                                    }
                                }
                            }
                            catch {
                                Write-Warning "Failed to get user details for member in group '$($group.displayName)': $($_.Exception.Message)"
                            }
                        }
                    }
                }
                catch {
                    Write-Warning "Failed to process project group '$($group.displayName)' in project '$projectName': $($_.Exception.Message)"
                }
            }
        }
        
        # Removed project-level policy API calls to eliminate 404 errors
        Write-Host "Skipping project-level policies for '$projectName' (removed to prevent 404 errors)" -ForegroundColor Yellow
    }
    catch {
        Write-Warning "Failed to process project '$projectName': $($_.Exception.Message)"
    }
    
    return $projectResults
}

# Main script execution
try {
    Write-Host "Starting Azure DevOps Organization Permissions Extraction..." -ForegroundColor Green
    Write-Host "Organization: $OrganizationUrl" -ForegroundColor Cyan
    Write-Host "Output Format: $OutputFormat" -ForegroundColor Cyan
    Write-Host "Hierarchical View: $HierarchicalView" -ForegroundColor Cyan
    
    # Validate organization URL format
    if ($OrganizationUrl -notmatch '^https://dev\.azure\.com/[^/]+/?$') {
        throw "Invalid organization URL format. Expected: https://dev.azure.com/yourorg"
    }
    
    # Extract organization name from URL
    $orgName = ($OrganizationUrl -replace 'https://dev\.azure\.com/', '') -replace '/$', ''
    Write-Host "Extracted organization name: $orgName" -ForegroundColor Cyan
    
    # Create authentication header
    $headers = Get-AuthHeader -Token $PersonalAccessToken
    
    # Test API connectivity
    Write-Host "Testing API connectivity..." -ForegroundColor Yellow
    $testUri = "$OrganizationUrl/_apis/projects?api-version=7.1"
    $testResponse = Invoke-AzureDevOpsApi -Uri $testUri -Headers $headers
    
    if (-not $testResponse) {
        throw "Failed to connect to Azure DevOps API. Please check your organization URL and Personal Access Token."
    }
    
    Write-Host "API connectivity test successful" -ForegroundColor Green
    
    # Get organization-level permissions
    $orgResults = Get-OrganizationPermissions -OrgName $orgName -Headers $headers -OrganizationUrl $OrganizationUrl
    
    # Get projects
    Write-Host "Retrieving projects..." -ForegroundColor Yellow
    $projectsUri = "$OrganizationUrl/_apis/projects?api-version=7.1"
    $projects = Invoke-AzureDevOpsApi -Uri $projectsUri -Headers $headers
    
    $projectResults = @()
    
    if ($projects -and $projects.value) {
        $projectsToProcess = if ($ProjectName) {
            $projects.value | Where-Object { $_.name -eq $ProjectName }
        } else {
            $projects.value
        }
        
        if ($projectsToProcess) {
            Write-Host "Found $($projectsToProcess.Count) project(s) to process" -ForegroundColor Cyan
            
            foreach ($project in $projectsToProcess) {
                $projectPerms = Get-ProjectPermissions -OrgName $orgName -Headers $headers -OrganizationUrl $OrganizationUrl -Project $project
                $projectResults += $projectPerms
            }
        }
        else {
            if ($ProjectName) {
                Write-Warning "Project '$ProjectName' not found in organization"
            }
            else {
                Write-Warning "No projects found in organization"
            }
        }
    }
    else {
        Write-Warning "No projects found or failed to retrieve projects"
    }
    
    # Combine all results
    $allResults = @()
    $allResults += $orgResults
    $allResults += $projectResults
    
    if ($allResults.Count -gt 0) {
        Write-Host "Processing $($allResults.Count) total items for export..." -ForegroundColor Yellow
        
        if ($HierarchicalView) {
            # Build hierarchical structure
            $hierarchicalData = Build-HierarchicalStructure -AllResults $allResults
            
            # Export based on format
            switch ($OutputFormat) {
                'CSV' {
                    $outputPath = if ($OutputPath -notmatch '\.[^.]*$') { "$OutputPath.csv" } else { $OutputPath }
                    Export-HierarchicalCSV -HierarchicalData $hierarchicalData -OutputPath $outputPath
                }
                'Excel' {
                    $outputPath = if ($OutputPath -notmatch '\.[^.]*$') { "$OutputPath.xlsx" } else { $OutputPath }
                    Export-HierarchicalExcel -HierarchicalData $hierarchicalData -AllResults $allResults -OutputPath $outputPath
                }
                'JSON' {
                    $outputPath = if ($OutputPath -notmatch '\.[^.]*$') { "$OutputPath.json" } else { $OutputPath }
                    Export-HierarchicalJSON -HierarchicalData $hierarchicalData -OutputPath $outputPath
                }
                'All' {
                    $basePath = $OutputPath -replace '\.[^.]*$', ''
                    Export-HierarchicalCSV -HierarchicalData $hierarchicalData -OutputPath "$basePath.csv"
                    Export-HierarchicalExcel -HierarchicalData $hierarchicalData -AllResults $allResults -OutputPath "$basePath.xlsx"
                    Export-HierarchicalJSON -HierarchicalData $hierarchicalData -OutputPath "$basePath.json"
                }
            }
            
            # Display hierarchical summary
            Write-Host "`nHierarchical Structure Summary:" -ForegroundColor Yellow
            foreach ($projectName in $hierarchicalData.Keys | Sort-Object) {
                $project = $hierarchicalData[$projectName]
                $totalUsers = ($project.Groups.Values | ForEach-Object { $_.Users.Count } | Measure-Object -Sum).Sum
                
                Write-Host "  Project: $projectName" -ForegroundColor Cyan
                Write-Host "    Groups: $($project.Groups.Count)" -ForegroundColor White
                Write-Host "    Users: $totalUsers" -ForegroundColor White
            }
        }
        else {
            # Standard flat export
            $outputPath = if ($OutputPath -notmatch '\.[^.]*$') { "$OutputPath.csv" } else { $OutputPath }
            
            # Define consistent column order for CSV output (removed policy columns)
            $orderedResults = $allResults | Select-Object ProjectName, Scope, ItemType, GroupName, GroupType, Description, MemberCount, UserName, UserEmail, UserType, PrincipalName, GroupMemberships, IsProjectLevel, LastModified, LastAccessed, CreatedDate, ModifiedDate, CreatedBy, Status, Descriptor, Origin, OriginId
            
            $orderedResults | Export-Csv -Path $outputPath -NoTypeInformation -Encoding UTF8
            Write-Host "Standard permissions export completed to: $outputPath" -ForegroundColor Green
        }
        
        Write-Host "Organization and project permissions extraction completed successfully!" -ForegroundColor Green
        Write-Host "Total items extracted: $($allResults.Count)" -ForegroundColor Cyan
        
        # Enhanced summary by type and scope (removed policy counts)
        $orgGroupCount = ($allResults | Where-Object { $_.ItemType -eq 'Group' -and $_.Scope -eq 'Organization' }).Count
        $orgUserCount = ($allResults | Where-Object { $_.ItemType -eq 'User' -and $_.Scope -eq 'Organization' }).Count
        $projectGroupCount = ($allResults | Where-Object { $_.ItemType -eq 'Group' -and $_.Scope -eq 'Project' }).Count
        $projectUserCount = ($allResults | Where-Object { $_.ItemType -eq 'User' -and $_.Scope -eq 'Project' }).Count
        $projectCount = ($allResults | Where-Object { $_.Scope -eq 'Project' } | Select-Object ProjectName -Unique).Count
        
        Write-Host "Extraction Summary:" -ForegroundColor Yellow
        Write-Host "  Organization Level:" -ForegroundColor Cyan
        Write-Host "    Groups: $orgGroupCount" -ForegroundColor White
        Write-Host "    Users: $orgUserCount" -ForegroundColor White
        Write-Host "  Project Level:" -ForegroundColor Cyan
        Write-Host "    Projects Processed: $projectCount" -ForegroundColor White
        Write-Host "    Groups: $projectGroupCount" -ForegroundColor White
        Write-Host "    Users: $projectUserCount" -ForegroundColor White
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
