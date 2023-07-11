Import-Module ActiveDirectory

$wks1 = "OU=Workstations,OU=Clients,OU=BOU,OU=CP,OU=_Divisions,DC=icig,DC=global"
$wks2 = "OU=Workstations,OU=Clients,OU=COL,OU=CP,OU=_Divisions,DC=icig,DC=global"
$mwks1 = "OU=Mobile Workstations,OU=Clients,OU=BOU,OU=CP,OU=_Divisions,DC=icig,DC=global"
$mwks2 = "OU=Mobile Workstations,OU=Clients,OU=COL,OU=CP,OU=_Divisions,DC=icig,DC=global"

Get-Content ..\output.txt | ForEach-Object {
    $asset = $_
    $workstations = @()
    $mworkstations = @()

    # Search for computers in the Workstations OU
    foreach ($ou in ($wks1, $wks2)) {
        $workstations += Get-ADComputer -Filter "((Name -like '*CPC*$asset') -or (Name -like '*CP4*$asset'))" -SearchBase $ou |
        Select-Object -ExpandProperty Name
    }

    # Search for computers in the Mobile Workstations OU
    foreach ($ou in ($mwks1, $mwks2)) {
        $mworkstations += Get-ADComputer -Filter "((Name -like '*CPC*$asset') -or (Name -like '*CP4*$asset'))" -SearchBase $ou |
        Select-Object -ExpandProperty Name
    }

    if ($workstations.Count -gt 1) {
        $count = $workstations.Count
        $compString = $workstations -join ', '
        Write-Output "There were $count computers with the asset $asset found in workstations. { $compString }"
    }

    if ($mworkstations.Count -gt 1) {
        $count = $mworkstations.Count
        $compString = $mworkstations -join ', '
        Write-Output "There were $count computers with the asset $asset found in mobile workstations. { $compString }"
    }
}