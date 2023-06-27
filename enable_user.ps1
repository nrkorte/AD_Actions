param (
   [Parameter(Mandatory = $true)]
   [string]$Username
)

Import-Module ActiveDirectory

$SamAccountName = $Username
$UserDN = Get-ADUser -Filter "samAccountName -eq '$SamAccountName'" -Properties DistinguishedName | Select-Object -ExpandProperty DistinguishedName
$User = Get-ADUser -Identity $UserDN -Properties Office
$OfficeLocation = $User.Office

if ((Get-ADUser -Identity $SamAccountName).Enabled -eq $True) {
   Write-Host "User is already enabled"
   exit
}

if ($OfficeLocation -eq "gp1") {
   $UsersOU = "OU=Users,OU=gp1,OU=CP,OU=_Divisions,DC=domain,DC=global"
}
elseif ($OfficeLocation -eq "BOU") {
   $UsersOU = "OU=Users,OU=gp2,OU=CP,OU=_Divisions,DC=domain,DC=global"
}
else {
   Write-Host "User not found or invalid office location. Please run ./add_office_location.ps1 with admin privileges to set the office locations of the users."
   exit
}

Write-Host "Moving " $Username " to " $UsersOU
Move-ADObject -Identity $UserDN -TargetPath $UsersOU
Write-Host "Enabling " $Username
Set-ADUser -Identity $SamAccountName -Enabled $true
