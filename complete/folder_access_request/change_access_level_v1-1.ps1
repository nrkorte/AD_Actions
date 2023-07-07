param (
    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [string]$path,

    [Parameter(Mandatory = $false)]
    [string]$permissions
)
Import-Module ActiveDirectory

$error.Clear()
& ".\remove_access_v1-1.ps1" $Username $path
if ($error.Count -ne 0) {
    Write-Error "There was a problem removing users from groups" -erroraction 'silentlycontinue'
}
$error.Clear()
& ".\folder_access_v2-6.ps1" $Username $path $permissions
if ($error.Count -ne 0) {
    Write-Error "There was a problem addding users to groups" -erroraction 'silentlycontinue'
}

