param(
    [string]$OrgUrl = "https://dev.azure.com/yourorg",
    [string]$PAT = "<your-pat>",
    [string]$OutputFile = "AzDO_UserGroupReport.csv"
)

$base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$PAT"))
$headers = @{ Authorization = "Basic $base64AuthInfo" }

# Get all groups
$groupsUrl = "$OrgUrl/_apis/graph/groups?api-version=7.1-preview.1"
$groups = (Invoke-RestMethod -Uri $groupsUrl -Headers $headers).value

$results = @()

foreach ($group in $groups) {
    $membersUrl = "$OrgUrl/_apis/graph/memberships/$($group.descriptor)?direction=down&api-version=7.1-preview.1"
    $memberships = (Invoke-RestMethod -Uri $membersUrl -Headers $headers).value

    foreach ($membership in $memberships) {
        $memberUrl = "$OrgUrl/_apis/graph/users/$($membership.memberDescriptor)?api-version=7.1-preview.1"
        try {
            $member = Invoke-RestMethod -Uri $memberUrl -Headers $headers
            $results += [pscustomobject]@{
                GroupName   = $group.displayName
                UserPrincipalName = $member.principalName
                Origin      = $member.origin
                SubjectKind = $member.subjectKind
            }
        } catch {
            # Skip non-user members like nested groups
        }
    }
}

$results | Export-Csv -Path $OutputFile -NoTypeInformation
Write-Host "✅ Report saved to $OutputFile"
