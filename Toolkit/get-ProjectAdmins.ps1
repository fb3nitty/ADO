param(
    [string]$OutputFile = "AzDO_ProjectAdminsReport.csv"
)

Import-Module Az.DevOps
$org = Get-AzDevOpsOrganization
$projects = Get-AzDevOpsProject

$results = @()

foreach ($project in $projects) {
    $projectName = $project.Name

    # Look for the "Project Administrators" team
    $adminTeam = Get-AzDevOpsTeam -ProjectName $projectName | Where-Object { $_.Name -eq "$projectName Team" }

    if ($adminTeam) {
        $members = Get-AzDevOpsTeamMember -ProjectName $projectName -Team $adminTeam.Name

        foreach ($member in $members) {
            $results += [pscustomobject]@{
                ProjectName        = $projectName
                TeamName           = $adminTeam.Name
                DisplayName        = $member.User.DisplayName
                UserPrincipalName  = $member.User.PrincipalName
                SubjectKind        = $member.User.SubjectKind
                Origin             = $member.User.Origin
            }
        }
    }
}

$results | Export-Csv -Path $OutputFile -NoTypeInformation
Write-Host "`n✅ Report saved to $OutputFile"


#Install-Module Az.DevOps -Scope CurrentUser -Force
#az login
#Set-AzDevOpsOrganization -Organization https://dev.azure.com/yourorg
