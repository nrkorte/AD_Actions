param (
    [Parameter(Mandatory = $true)]
    [string]$search
)

Import-Module ActiveDirectory

$wks1 = "OU=Workstations,OU=Clients,OU=BOU,OU=CP,OU=_Divisions,DC=icig,DC=global"
$wks2 = "OU=Workstations,OU=Clients,OU=COL,OU=CP,OU=_Divisions,DC=icig,DC=global"
$mwks1 = "OU=Mobile Workstations,OU=Clients,OU=BOU,OU=CP,OU=_Divisions,DC=icig,DC=global"
$mwks2 = "OU=Mobile Workstations,OU=Clients,OU=COL,OU=CP,OU=_Divisions,DC=icig,DC=global"

$mts = @()

foreach ($ou in ($wks1, $wks2, $mwks1, $mwks2)) {
    $comps = Get-ADComputer -Filter "Description -ne '*'" -SearchBase $ou | Sort-Object -Property Description
    foreach ($comp in $comps) {
        $desc = Get-ADComputer -Identity $comp -Property Name, Description | Select-Object Description
        if ($desc -like "*$search*") {
            $mts += $comp
        }
    }
}

foreach ($m in $mts) {
    $tmp = Get-ADComputer -Identity $m -Property Name, Description | Format-Table Name, Description
    $tmp
}