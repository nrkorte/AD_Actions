Import-Module ActiveDirectory

$ous = "OU=Users,OU=COL,OU=CP,OU=_Divisions,DC=domain,DC=global", "OU=Users,OU=BOU,OU=CP,OU=_Divisions,DC=domain,DC=global"

$users = $ous | ForEach-Object { Get-ADUser -SearchBase $_ -Filter * -Properties DistinguishedName | Select-Object -expand DistinguishedName }
$sams = $ous | ForEach-Object { Get-ADUser -SearchBase $_ -Filter * -Properties SamAccountName | Select-Object -expand SamAccountName }
$i = 0
foreach ($usert in $users) {
    $OU = ($usert -split ',OU=')[2]
    if ($OU -eq "gp1") {
        Set-ADUser -Identity $sams[$i] -Office "gp1"
    }
    elseif ($OU -eq "gp2") {
        Set-ADUser -Identity $sams[$i] -Office "gp2"
    }
    else {
        Write-Host "There was an error retrieving user location for " ($usert -split ',OU=')[0]
    }
    $i++
}
