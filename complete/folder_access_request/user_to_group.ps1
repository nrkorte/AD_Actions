param (
    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [string]$GroupName
)

Import-Module ActiveDirectory

if (!($null -ne ([ADSISearcher] "(SamAccountName=$Username)").FindOne())) {
    Write-Error "Could not find user: $($Username)"
    exit 1
}


if ($GroupName.StartsWith("ICIG\")) {
    $GroupName = $GroupName.Substring(5)
}

$group = Get-ADGroup -Identity $GroupName

if ($null -eq $group) {
    Write-Host "Security group '$GroupName' does not exist in the specified folder."
    exit 1
}

$tmp = Get-ADUser -Filter "SamAccountName -eq '$Username'"
$GroupDN = $group.DistinguishedName
$UserDN = (Get-ADUser $Username).DistinguishedName
if (Get-ADUser -Filter "memberOf -RecursiveMatch '$GroupDN'" -SearchBase $UserDN) {
    Write-Error "" -erroraction 'silentlycontinue'
    exit 1
}
Add-ADGroupMember -Identity $GroupName -Members $tmp

