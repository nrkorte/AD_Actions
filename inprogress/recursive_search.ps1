param (
    [Parameter(Mandatory = $true)]
    [string]$StartingFolder,

    [Parameter(Mandatory = $true)]
    [string]$SearchString,

    [string]$FilterType = ""
)


if ($StartingFolder.Contains(":")) {
    $StartingFolder = $StartingFolder.Replace("\\", "\")
    $sub = $StartingFolder.Substring(0, 1)
    $rest = $StartingFolder.Substring(2)
    switch ($sub) {
        "J" { $StartingFolder = "\\uscosf5101.icig.global\GroupShares\Departments" + $rest }
        "K" { $StartingFolder = "\\uscosf5101.icig.global\GroupShares\Shared" + $rest }
        "L" { $StartingFolder = "\\uscosf5101.icig.global\GroupShares\SFA" + $rest }
        "V" { $StartingFolder = "\\cp4boufs102.icig.global\f\departments" + $rest }
        "W" { $StartingFolder = "\\cp4boufs101.icig.global\f\Projects" + $rest }
        "X" { $StartingFolder = "\\cp4boufs101.icig.global\f\Projects\Vault" + $rest }
        Default { Write-Host "You do not need an access request for your U or C drives. If you think this is an error, please ensure that your path name is correct" }
    }
}