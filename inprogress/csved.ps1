param (
    [Parameter(Mandatory = $true)]
    [string]$path,

    [Parameter(Mandatory = $false)]
    [string]$read
)

if ($path.Contains(":")) {
    $path = $path.Replace("\\", "\")
    $sub = $path.Substring(0, 1)
    $rest = $path.Substring(2)
    switch ($sub) {
        "J" { $path = "\\uscosf5101.icig.global\GroupShares\Departments" + $rest }
        "K" { $path = "\\uscosf5101.icig.global\GroupShares\Shared" + $rest }
        "L" { $path = "\\uscosf5101.icig.global\GroupShares\SFA" + $rest }
        "M" { $path = "\\uscosf5101.icig.global\GroupShares\Apps" + $rest }
        "R" { $path = "\\cp4boufs101.icig.global\g\forms" + $rest }
        "V" { $path = "\\cp4boufs102.icig.global\f\departments" + $rest }
        "W" { $path = "\\cp4boufs101.icig.global\f\Projects" + $rest }
        "X" { $path = "\\cp4boufs101.icig.global\f\Projects\Vault" + $rest }
        Default { Write-Host "You do not need an access request for your U or C drives. If you think this is an error, please ensure that your path name is correct" }
    }
}

function Get-SubfolderGroups {
    param (
        [string]$FolderPath,
        [string[]]$GroupPrefixArray
    )

    $SubfolderGroups = @()
    $folders = Get-ChildItem -Path $FolderPath -Force | Where-Object { $_.Attributes -band [System.IO.FileAttributes]::Directory }
    foreach ($folder in $folders) {
        $Acl = $null
        try {
            $Acl = Get-Acl -Path $folder.FullName
        }
        catch {
            Write-Host "Could not find path to folder: $($folder.FullName): $_"
        }

        if ($Acl) {
            $Groups = $Acl.Access |
            Where-Object { $_.IdentityReference.Value -like "${GroupPrefixArray}*" } |
            Select-Object -ExpandProperty IdentityReference

            $Groups = $Groups | Where-Object { $_ -match "[-](M|R|W)$" }

            $GroupNames = ($Groups | ForEach-Object { $_.Value }) -join ","
            $SubfolderGroups += "$($folder.FullName),$GroupNames"
        }
    }

    return $SubfolderGroups
}

$GroupPrefixArray = @("ICIG\QC_CofA", "ICIG\QC_TLC_Pictures", "ICIG\ROUFCT_ClientAdmin", "ICIG\ROUFCT_ITAdmins", "ICIG\ROUFCT_PlantSups", "ICIG\ROUORG_AllUsers", "ICIG\ROUORG_RCCPlantCommunication")

$Result = Get-SubfolderGroups -FolderPath $path -GroupPrefixArray $GroupPrefixArray
$Result | Out-File -FilePath "output.csv"