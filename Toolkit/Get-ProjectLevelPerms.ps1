param(
    [string]$OrgUrl = "https://dev.azure.com/yourorg",
    [string]$PAT = "<your-pat>",
    [string]$OutputFile = "AzDO_UserGroupProjectReport.csv"
)

$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$PAT"))
}

# Get all projects
$projectsUrl = "$OrgUrl/_apis/projects?api-version=7.1-preview.1"
$projects = (Invoke-RestMethod -Uri $projectsUrl -Headers $headers).value

$results = @()

foreach ($project in $projects) {
    $projectName = $project.name
    $groupUrl = "$OrgUrl/_apis/graph/groups?scopeDescriptor=Microsoft.TeamFoundation.Project%2F$($project.id)&api-version=7.1-preview.1"
    $groups = (Invoke-RestMethod -Uri $groupUrl -Headers $headers).value

    foreach ($group in $groups) {
        $groupDescriptor = $group.descriptor
        $groupName = $group.displayName

        # Get members of the group
        $membersUrl = "$OrgUrl/_apis/graph/memberships/$groupDescriptor?direction=down&api-version=7.1-preview.1"
        $memberships = (Invoke-RestMethod -Uri $membersUrl -Headers $headers).value

        foreach ($membership in $memberships) {
            $memberDescriptor = $membership.memberDescriptor
            $memberUrl = "$OrgUrl/_apis/graph/descriptors/$memberDescriptor?api-version=7.1-preview.1"
            $descriptor = (Invoke-RestMethod -Uri $memberUrl -Headers $headers).value

            $type = $descriptor.subjectKind

            # Get user/group details only if user or group
            if ($type -eq "user" -or $type -eq "group") {
                $memberInfoUrl = "$OrgUrl/_apis/graph/users/$memberDescriptor?api-version=7.1-preview.1"
                try {
                    $member = Invoke-RestMethod -Uri $memberInfoUrl -Headers $headers

                    $results += [pscustomobject]@{
                        ProjectName        = $projectName
                        GroupName          = $groupName
                        GroupDescriptor    = $groupDescriptor
                        UserPrincipalName  = $member.principalName
                        Origin             = $member.origin
                        SubjectKind        = $member.subjectKind
                    }
                } catch {
                    # In case it's a group not a user (use different endpoint if needed)
                }
            }
        }
    }
}

$results | Export-Csv -Path $OutputFile -NoTypeInformation
Write-Host "`n✅ Report saved to $OutputFile"
