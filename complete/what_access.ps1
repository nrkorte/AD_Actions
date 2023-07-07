# Accepts two arguments: A username and a path to a folder
param (
    [Parameter(Mandatory = $true)]
    [string]$path,

    [Parameter(Mandatory = $false)]
    [string]$read
)

# Give the full path if the user sends a drive name

if ($path.Contains(":")) {
    $path = $path.Replace("\\", "\")
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
Import-Module ActiveDirectory

$FolderPath = $path
$GroupPrefix = "ICIG\"

# Check to see what groups have access to the folder
try {
    $Acl = Get-Acl -Path $FolderPath
}
catch {
    Write-Host "Could not find path to folder: $($element): $_"
}
$Groups = $Acl.Access |
Where-Object { $_.IdentityReference.Value -like "${GroupPrefix}*" } |
Select-Object -ExpandProperty IdentityReference

[String[]]$ret = @()
foreach ($element in $Groups) {
    if (-not($ret -contains $element)) {
        $ret += Write-Output $element
    }
}

$savestate = $ret | Where-Object { $_ -match "[-](M|R|W)$" }
if ($savestate.Count -lt 1) {
    [String[]]$big_array = "ICIG\QC_CofA", "ICIG\QC_TLC_Pictures", "ICIG\ROUFCT_ClientAdmin", "ICIG\ROUFCT_ITAdmins", "ICIG\ROUFCT_PlantSups", "ICIG\ROUORG_AllUsers", "ICIG\ROUORG_RCCPlantCommunication"
    $ret = $ret | Where-Object { $big_array -contains $_ }
}
else {
    $ret = $ret | Where-Object { $_ -match "[-](M|R|W)$" }
}

$ret