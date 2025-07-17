param(
    [string]$OrgUrl = "https://dev.azure.com/yourorg",
    [string]$PAT = "<your-pat>",
    [string]$OutputFile = "AzDO_ProjectAdminsReport.csv"
)

$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$PAT"))
}

$results = @()

# 1. Get all projects
$projects = (Invoke-RestMethod -Uri "$OrgUrl/_apis/projects?api-version=6.0" -Headers $headers).value

foreach ($project in $projects) {
    $projectName = $project.name

    # 2. Get all Graph groups scoped to this project
    $scopeUrl = "$OrgUrl/_apis/graph/groups?scopeDescriptor=Microsoft.TeamFoundation.Project%2F$($project.id)&api-version=6.0-preview.1"
    $groups = (Invoke-RestMethod -Uri $scopeUrl -Headers $headers).value

    # 3. Find the Project Administrators group
    $adminGroup = $groups | Where-Object { $_.displayName -eq "Project Administrators" }

    if ($adminGroup) {
        $groupDescriptor = $adminGroup.descriptor
        $groupName = $adminGroup.displayName

        # 4. Get direct members of the group
        $membersUrl = "$OrgUrl/_apis/graph/memberships/$groupDescriptor?direction=down&api-version=6.0-preview.1"
        $memberships = (Invoke-RestMethod -Uri $membersUrl -Headers $headers).value

        foreach ($membership in $memberships) {
            $memberDescriptor = $membership.memberDescriptor
            $userUrl = "$OrgUrl/_apis/graph/users/$memberDescriptor?api-version=6.0-preview.1"

            try {
                $member = Invoke-RestMethod -Uri $userUrl -Headers $headers
                $results += [pscustomobject]@{
                    ProjectName        = $projectName
                    GroupName          = $groupName
                    DisplayName        = $member.displayName
                    UserPrincipalName  = $member.principalName
                    Origin             = $member.origin
                    SubjectKind        = $member.subjectKind
                }
            } catch {
                # skip non-user members (e.g., groups)
            }
        }
    }
}

$results | Export-Csv -Path $OutputFile -NoTypeInformation
Write-Host "`n✅ Report saved to $OutputFile"
