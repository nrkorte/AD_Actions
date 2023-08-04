param (
    [Parameter(Mandatory = $true)]
    [string]$usersam
)

Import-Module ActiveDirectory

$ou1 = "OU=Directory Groups,OU=BOU,OU=CP,OU=_Divisions,DC=icig,DC=global"
$ou2 = "OU=Directory Groups,OU=COL,OU=CP,OU=_Divisions,DC=icig,DC=global"

$user = Get-ADuser -Filter { SamAccountName -eq $usersam }

foreach ($ou in ($ou1, $ou2)) {
    $groups = Get-ADGroup -Filter * -SearchBase $ou
    foreach ($group in $groups) {
        $error.Clear()
        Add-ADGroupMember -Identity $group -Members $user
    }
}