# Accepts two arguments: A username and a path to a folder
param (
    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [string]$path
)
Import-Module ActiveDirectory

if ($Username.Length -eq 0 -or $path.Length -eq 0) {
    Write-Host "No program arguments can be null, please ensure you entered all values in correctly"
    exit
}

if (!($null -ne ([ADSISearcher] "(SamAccountName=$Username)").FindOne())) {
    Write-Host "Could not find user: $($Username)"
    exit
}

$path = $path.Replace("\\", "\")
if ($path.Contains(":")) {
    $sub = $path.Substring(0, 1)
    $rest = $path.Substring(2)
    switch ($sub) {
        "J" { $path = "\\uscosf5101.icig.global\GroupShares\Departments" + $rest }
        "K" { $path = "\\uscosf5101.icig.global\GroupShares\Shared" + $rest }
        "L" { $path = "\\uscosf5101.icig.global\GroupShares\SFA" + $rest }
        "V" { $path = "\\cp4boufs102.icig.global\f\departments" + $rest }
        "W" { $path = "\\cp4boufs101.icig.global\f\Projects" + $rest }
        "X" { $path = "\\cp4boufs101.icig.global\f\Projects\Vault" + $rest }
        Default { Write-Host "You do not need an access request for your U or C drives. If you think this is an error, please ensure that your path name is correct" }
    }
}

$FolderPath = $path
$GroupPrefix = "ICIG\"

try {
    $Acl = Get-Acl -Path $FolderPath
}
catch {
    Write-Host "Could not find path to folder: $($element): $_"
}

$Groups = $Acl.Access | Where-Object { $_.IdentityReference.Value -like "${GroupPrefix}*" } | Select-Object -ExpandProperty IdentityReference

[String[]]$ret = @()
foreach ($element in $Groups) {
    if (-not($ret -contains $element)) {
        $ret += Write-Output $element
    }
}

$ret = $ret | Where-Object { $_ -match "[-](M|R|W)$" }

$removed = @()
$already = @()

foreach ($element in $ret) {
    try {
        $group = Get-ADGroup ($element.Substring(5))
        $error.Clear()
        & ".\user_from_group.ps1" $Username $group
        if ($error.Count -eq 0) {
            $removed += ($element.Substring(5))
        }
        else {
            $already += ($element.Substring(5))
        }
    }
    catch {
        Write-Host "An error occurred: $($_.Exception.Message)"
    }

}

if ($removed.Count -ne 0 -or $already.Count -ne 0) {
    if ($removed.Count -ne 0) {
        Write-Host "Removed the user '$Username' from --> "
        $removed
    }
}
else {
    Write-Host "There were no known groups the user had that contained an association with the folder specified"
    $ret
}