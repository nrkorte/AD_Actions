# Gets the jobs associated with a group

param (
    [Parameter(Mandatory = $true)]
    [string]$Group
)

Import-Module ActiveDirectory

$groupName = $Group
if ($groupName.StartsWith("ICIG\")) {
    $groupName = $groupName.Substring(5)
}
try {
    $group = Get-ADGroup -Filter { Name -eq $groupName } -ErrorAction Stop
    $members = Get-ADGroupMember -Identity $group -ErrorAction Stop
 
    $descriptionHash = @{}
    foreach ($member in $members) {
        if ($member.objectClass -eq "user") {
            try {
                $user = Get-ADUser -Identity $member -Properties Description -ErrorAction Stop
                $description = $user.Description
                if ($null -ne $description -and !$descriptionHash.ContainsKey($description)) {
                    $descriptionHash[$description] = $true
                }
            }
            catch {
                Write-Host "Failed to retrieve user information for member $($member.Name): $_"
            }
        }
    }

    if ($descriptionHash.Count -gt 0) {
        $descriptions = $descriptionHash.Keys
        Write-Host "Jobs under the group->"$groupName":"
        $descriptions | Sort-Object
    }
    else {
        Write-Host "No descriptions found for the group $($groupName)."
    }
}
catch {
    Write-Host "Failed to retrieve security group $($groupName): $_"
}