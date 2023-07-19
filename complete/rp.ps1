# Reset password of user to Welcome1

param (
    [Parameter(Mandatory = $true)]
    [string]$Username
)

Import-Module ActiveDirectory

$Pass = ConvertTo-SecureString "Welcome1" -AsPlainText -Force 
Set-ADAccountPassword -Identity $Username -NewPassword $pass -Reset
Set-ADUser -Identity $Username -ChangePasswordAtLogon $false
Unlock-ADAccount -Identity $Username