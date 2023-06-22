param (
    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [string]$GroupName
)

$folderPath = "icig.global/_Divisions/CP/BOU/Security Groups"

try {
    $groupPath = "LDAP://$folderPath/$GroupName"
    $group = [adsi]$groupPath

    if ($null -eq $group) {
        Write-Host "Security group '$GroupName' does not exist in the specified folder."
        exit
    }
    $ous = "OU=Users,OU=COL,OU=CP,OU=_Divisions,DC=icig,DC=global", "OU=Users,OU=BOU,OU=CP,OU=_Divisions,DC=icig,DC=global"
    $users = $ous | ForEach-Object { Get-ADUser -SearchBase $_ -Filter * -Properties samAccountName | Select-Object -expand samAccountName }
    foreach ($usert in $users) {
        if ($usert -eq $Username) {
            $user = $usert
        }
    }

    if ($null -eq $user) {
        Write-Error "User with logon name '$Username' does not exist."
        exit
    }

    $tmp = Get-ADUser -Filter "SamAccountName -eq '$user'"
    $GroupDN = (Get-ADGroup $GroupName).DistinguishedName
    $UserDN = (Get-ADUser $Username).DistinguishedName
    if (Get-ADUser -Filter "memberOf -RecursiveMatch '$GroupDN'" -SearchBase $UserDN) {
        Write-Host "Member already exists in that group. Exiting..."
        exit
    }
    Add-ADGroupMember -Identity $GroupName -Members $tmp
    Write-Host "User '$Username' has been added to the security group '$GroupName' successfully."
}
catch {
    Write-Host "An error occurred: $($_.Exception.Message)"
}
