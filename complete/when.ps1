# When was a user created?

param (
    [Parameter(Mandatory = $true)]
    [string]$Username
)

Import-Module ActiveDirectory

Get-ADUser $Username -Properties whenCreated | Format-List Name, whenCreated