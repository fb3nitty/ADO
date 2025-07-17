param(
    [string]$OrgUrl = "https://dev.azure.com/yourorg",
    [string]$PAT = "<your-pat>",
    [string]$OutputFile = "AzDO_UserPermissionsReport.csv"
)

$headers = @{
    Authorization = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$PAT"))
}

$results = @()

# 1. Get all projects
$projects = (Invoke-RestMethod -Uri "$OrgUrl/_apis/projects?api-version=6.0" -Headers $headers).value

foreach ($project in $projects) {
    $projectId = $project.id
    $projectName = $project.name

    # 2. Get all members of the project (via team membership, a good proxy for access)
    $teams = (Invoke-RestMethod -Uri "$OrgUrl/_apis/projects/$projectId/teams?api-version=6.0" -Headers $headers).value

    foreach ($team in $teams) {
        $teamName = $team.name
        $members = (Invoke-RestMethod -Uri "$OrgUrl/_apis/projects/$projectId/teams/$($team.id)/members?api-version=6.0" -Headers $headers).value

        foreach ($member in $members) {
            $results += [pscustomobject]@{
                ProjectName        = $projectName
                TeamName           = $teamName
                UserPrincipalName  = $member.identity.uniqueName
                DisplayName        = $member.identity.displayName
                Origin             = $member.identity.origin
                SubjectKind        = $member.identity.subjectKind
                # Optional: use Access Levels API if needed (see below)
            }
        }
    }
}

$results | Export-Csv -Path $OutputFile -NoTypeInformation
Write-Host "`n✅ Report saved to $OutputFile"
