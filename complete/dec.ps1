# Disable empty computers. If a computer has no descritpion, disable it

Import-Module ActiveDirectory

$ous = "OU=Workstations,OU=Clients,OU=COL,OU=CP,OU=_Divisions,DC=icig,DC=global", "OU=Mobile Workstations,OU=Clients,OU=COL,OU=CP,OU=_Divisions,DC=icig,DC=global"

$comps = $ous | ForEach-Object { Get-ADComputer -SearchBase $_ -Filter "Description -notlike '*'" -Properties Description | Select-Object -ExpandProperty Name }

[String[]]$already = @()
[String[]]$new = @()

Foreach ($Computer in $comps) {
    Get-ADComputer -Identity $Computer | Select-Object Enabled
    if ((Get-ADComputer -Identity $Computer | Select-Object Enabled) -eq "False") {
        $already += $computer
    }
    else {
        # Set-ADComputer -Identity $computer -Enabled $false
        $new += $computer
    }
}

Write-Host "Newly disabled users -->"
$new
Write-Host "Already disabled users -->"
$already