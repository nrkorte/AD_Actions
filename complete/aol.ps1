# Add office location. Adds COL or BOU respectively to their office location

Import-Module ActiveDirectory

$ous = "OU=Users,OU=COL,OU=CP,OU=_Divisions,DC=icig,DC=global", "OU=Users,OU=BOU,OU=CP,OU=_Divisions,DC=icig,DC=global"

$users = $ous | ForEach-Object { Get-ADUser -SearchBase $_ -Filter * -Properties DistinguishedName | Select-Object -expand DistinguishedName }
$sams = $ous | ForEach-Object { Get-ADUser -SearchBase $_ -Filter * -Properties SamAccountName | Select-Object -expand SamAccountName }
$i = 0
foreach ($usert in $users) {
    $OU = ($usert -split ',OU=')[2]
    if ($OU -eq "COL") {
        Set-ADUser -Identity $sams[$i] -Office "COL"
    }
    elseif ($OU -eq "BOU") {
        Set-ADUser -Identity $sams[$i] -Office "BOU"
    }
    else {
        Write-Host "There was an error retrieving user location for " ($usert -split ',OU=')[0]
    }
    $i++
}