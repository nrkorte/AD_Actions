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
        Write-Error "" -erroraction 'silentlycontinue'
        exit 1
    }
    $tmp = Get-ADUser -Filter "SamAccountName -eq '$Username'"

    if ($null -eq $tmp) {
        Write-Error "" -erroraction 'silentlycontinue'
        exit 1
    }

    $GroupDN = (Get-ADGroup $GroupName).DistinguishedName
    $UserDN = (Get-ADUser $Username).DistinguishedName
    if (Get-ADUser -Filter "memberOf -RecursiveMatch '$GroupDN'" -SearchBase $UserDN) {
        Remove-ADGroupMember -Identity $GroupName -Members $tmp -Confirm:$false
    }
    else {
        Write-Error "" -erroraction 'silentlycontinue'
        exit 1
    }
}
catch {
    Write-Host "An error occurred: $($_.Exception.Message)"
}
