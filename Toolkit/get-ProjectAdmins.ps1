$projects = az devops project list --query "value[].name" -o tsv

$results = @()

foreach ($project in $projects) {
    Write-Host "Checking $project..."
    $admins = az devops security group list --project "$project" --query "graphGroups[?contains(displayName, 'Project Administrators')].descriptor" -o tsv

    foreach ($group in $admins) {
        $members = az devops security group membership list --id $group --relationship members --query "members[]" -o json | ConvertFrom-Json

        foreach ($member in $members) {
            $results += [pscustomobject]@{
                ProjectName        = $project
                DisplayName        = $member.displayName
                PrincipalName      = $member.principalName
                Origin             = $member.origin
                SubjectKind        = $member.subjectKind
            }
        }
    }
}

$results | Export-Csv -Path "AzDO_ProjectAdminsReport.csv" -NoTypeInformation
Write-Host "`n✅ Report saved to AzDO_ProjectAdminsReport.csv"

#az extension add --name azure-devops

#az login
#az devops configure --defaults organization=https://dev.azure.com/yourorg

