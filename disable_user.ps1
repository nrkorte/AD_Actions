param (
   [Parameter(Mandatory = $true)]
   [string]$Username
)

Import-Module ActiveDirectory

$SamAccountName = $Username
$UserDN = Get-ADUser -Filter "samAccountName -eq '$SamAccountName'" -Properties DistinguishedName | Select-Object -ExpandProperty DistinguishedName
$OU = ($UserDN -split ',OU=')[2]

if ((Get-ADUser -Identity $SamAccountName).Enabled -eq $False) {
   Write-Host "User is already disabled"
   exit
}

if ($OU -eq "gp1") {
   $DisabledUsersOU = "OU=Disabled Users,OU=COL,OU=CP,OU=_Divisions,DC=icig,DC=global"
   $OfficeLocation = "gp1"
}
elseif ($OU -eq "gp2") {
   $DisabledUsersOU = "OU=Disabled Users,OU=BOU,OU=CP,OU=_Divisions,DC=icig,DC=global"
   $OfficeLocation = "gp2"
}
else {
   Write-Host "User not found"
   exit
}

Write-Host "Moving "$Username" to "$DisabledUsersOU
Move-ADObject -Identity $UserDN -TargetPath $DisabledUsersOU
Write-Host "Setting "$Username" office location to "$OfficeLocation
Set-ADUser -Identity $SamAccountName -Office $OfficeLocation
Write-Host "Disabling "$Username
Disable-ADAccount -Identity $SamAccountName
