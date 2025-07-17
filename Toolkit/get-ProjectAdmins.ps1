param(
    [string]$OrgUrl = "https://dev.azure.com/yourorg",
    [string]$PAT = "<your-pat>",
    [string]$OutputFile = "AzDO_ProjectAdminsReport.csv"
)

$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$PAT"))
}

$results = @()

# Get all projects
$projects = (Invoke-RestMethod -Uri "$OrgUrl/_apis/projects?api-version=6.0" -Headers $headers).value

foreach ($project in $projects) {
    $projectName = $project.name

    # Get groups for the project
    $groupsUrl = "$OrgUrl/_apis/securitynamespaces/WindowsLiveId/groups?scope=$($project.id)&api-version=6.0-preview.1"
    $groups = (Invoke-RestMethod -Uri $groupsUrl -Headers $headers).value

    # Find Project Administrators group
    $adminGroup = $groups | Where-Object { $_.principalName -like "*Project Administrators*" }

    if ($adminGroup) {
        $groupDescriptor = $adminGroup.descriptor

        # Get direct members
        $membersUrl = "$OrgUrl/_apis/graph/memberships/$groupDescriptor?direction=down&api-version=6.0-preview.1"
        $memberships = (Invoke-RestMethod -Uri $membersUrl -Headers $headers).value

        foreach ($membership in $memberships) {
            $memberDescriptor = $membership.memberDescriptor
            $memberUrl = "$OrgUrl/_apis/graph/users/$memberDescriptor?api-version=6.0-preview.1"

            try {
                $member = Invoke-RestMethod -Uri $memberUrl -Headers $headers
                $results += [pscustomobject]@{
                    ProjectName        = $projectName
                    GroupName          = $adminGroup.principalName
                    DisplayName        = $member.displayName
                    UserPrincipalName  = $member.principalName
                    Origin             = $member.origin
                    SubjectKind        = $member.subjectKind
                }
            } catch {
                # Skip if member is not a user (e.g., group)
            }
        }
    }
}

$results | Export-Csv -Path $OutputFile -NoTypeInformation
Write-Host "`n✅ Report saved to $OutputFile"
