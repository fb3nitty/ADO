param(
    [string]$OrgUrl = "https://dev.azure.com/yourorg",
    [string]$PAT = "<your-pat>",
    [string]$OutputFile = "AzDO_UserGroupProjectReport.csv"
)

$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$PAT"))
}

$results = @()

# 1. Get all projects
$projects = (Invoke-RestMethod -Uri "$OrgUrl/_apis/projects?api-version=7.1-preview.7" -Headers $headers).value

foreach ($project in $projects) {
    $projectName = $project.name

    # 2. Get groups for this project
    $groupsUrl = "$OrgUrl/_apis/projects/$($project.id)/teams?api-version=7.1-preview.3"
    $teams = (Invoke-RestMethod -Uri $groupsUrl -Headers $headers).value

    foreach ($team in $teams) {
        $teamName = $team.name
        $teamId = $team.id

        # 3. Get team members
        $membersUrl = "$OrgUrl/_apis/projects/$($project.id)/teams/$teamId/members?api-version=7.1-preview.2"
        $members = (Invoke-RestMethod -Uri $membersUrl -Headers $headers).value

        foreach ($member in $members) {
            $results += [pscustomobject]@{
                ProjectName        = $projectName
                TeamName           = $teamName
                UserPrincipalName  = $member.identity.uniqueName
                DisplayName        = $member.identity.displayName
                SubjectKind        = $member.identity.subjectKind
                Origin             = $member.identity.origin
            }
        }
    }
}

$results | Export-Csv -Path $OutputFile -NoTypeInformation
Write-Host "`n✅ Report saved to $OutputFile"
