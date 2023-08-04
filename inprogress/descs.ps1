Import-Module ActiveDirectory

$ous = "OU=Workstations,OU=Clients,OU=COL,OU=CP,OU=_Divisions,DC=icig,DC=global", "OU=Mobile Workstations,OU=Clients,OU=COL,OU=CP,OU=_Divisions,DC=icig,DC=global"

$users = $ous | ForEach-Object { Get-ADUser -SearchBase $_ -Filter "Description -ne '*' -and Name -like '*,*'" }
# $users = Get-ADUser -Filter "Description -ne '*' -and Name -like '*,*'"

$mts = @()
$count = 0
foreach ($user in $users) {
    $count += 1
    $mts += $user.Name
}

$count

foreach ($user in $mts) {
    $name = $user.Name
    $desc = Read-Host "Description for" $name":"
    $tmp = Get-ADUser -Filter "Name -like '*$name*'"
    $tmp.Description = $desc
}