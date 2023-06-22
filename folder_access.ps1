# Accepts two arguments: A username and a path to a folder
param (
    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [string]$path,

    [Parameter(Mandatory = $false)]
    [string]$read
)

# Give the full path if the user sends a drive name
$path = $path.Replace("\\", "\")
if ($path.Contains(":")) {
    $sub = $path.Substring(0, 1)
    $rest = $path.Substring(2)
    switch ($sub) {
        "J" { $path = "\\uscosf5101.icig.global\GroupShares\Departments" + $rest }
        "K" { $path = "\\uscosf5101.icig.global\GroupShares\Shared" + $rest }
        "L" { $path = "\\uscosf5101.icig.global\GroupShares\SFA" + $rest }
        "V" { $path = "\\cp4boufs102.icig.global\f\departments" + $rest }
        "W" { $path = "\\cp4boufs101.icig.global\f\Projects" + $rest }
        "X" { $path = "\\cp4boufs101.icig.global\f\Projects\Vault" + $rest }
        Default { Write-Host "You do not need an access request for your U or C drives. If you think this is an error, please ensure that your path name is correct" }
    }
}
Import-Module ActiveDirectory
# Check to see if user has a non-empty job
$filter_user = Get-ADUser -Filter "SamAccountName -eq '$Username'"
$ggg = Get-ADUser -Identity $filter_user -Properties Description | Select-Object -ExpandProperty Description
if ($null -eq $ggg) {
    Write-Host "Specified user has no job listed in the description section in the Active Directory Suite, please add a job and restart this program"
    exit
}
else {
    $Job = $ggg
}

$FolderPath = $path
$GroupPrefix = "ICIG\"

# Check to see what groups have access to the folder
try {
    $Acl = Get-Acl -Path $FolderPath
}
catch {
    Write-Host "Could not find path to folder: $($element): $_"
}
$Groups = $Acl.Access |
Where-Object { $_.IdentityReference.Value -like "${GroupPrefix}*" } |
Select-Object -ExpandProperty IdentityReference

[String[]]$ret = @()
foreach ($element in $Groups) {
    if (-not($ret -contains $element)) {
        $ret += Write-Output $element
    }
}
$ret = $ret | Where-Object { $_ -ne "ICIG\Domain Users" }
$ret = $ret | Where-Object { $_.Substring(0, 13) -ne "ICIG\DriveMap" }
if ("" -ne $read) {
    $ret = $ret | Where-Object { $_.Substring($_.Length - 2) -ne "-M" }
}
$ret
exit
# Make a k/v pair to store the group as the k and the jobs that are part of that group as the v
$permission_job = @{}
foreach ($element in $ret) {
    try {
        $members = Get-ADGroupMember -Identity $element.Substring(5) -ErrorAction Stop
        $descriptionHash = @{}
        foreach ($member in $members) {
            if ($member.objectClass -eq "user") {
                try {
                    $user = Get-ADUser -Identity $member -Properties Description -ErrorAction Stop
                    $description = $user.Description
                    if ($null -ne $description -and !$descriptionHash.ContainsKey($description)) {
                        $descriptionHash[$description] = $true
                    }
                }
                catch {
                    Write-Host "Failed to retrieve user information for member $($member.Name): $_"
                }
            }
        }
  
        if ($descriptionHash.Count -gt 0) {
            $descriptions = $descriptionHash.Keys
            $permission_job[$element] = $descriptions
        }
        else {
            Write-Host "No descriptions found for the group $($element)."
        }
    }
    catch {
        Write-Host "Failed to retrieve security group $($element): $_"
    }
}

$added = @()
$numsearched = 0
[String[]] $strs = $permission_job.Keys

# For every group that contains the job of the user, add the user to that group
for ($i = 0; $i -lt $permission_job.Count; $i++) {
    try {
        $group = Get-ADGroup ($strs[$i].Substring(5))
        if ($permission_job[$strs[$i]] -contains $Job) {
            if ($null -eq $group) {
                Write-Host "Security group does not exist in the specified folder."
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
            $GroupDN = (Get-ADGroup ($strs[$i].Substring(5))).DistinguishedName
            $UserDN = (Get-ADUser $Username).DistinguishedName
            if (Get-ADUser -Filter "memberOf -RecursiveMatch '$GroupDN'" -SearchBase $UserDN) {
                Write-Host "Member already exists in '$strs[$i]'."
                $numsearched += 1
            }
            else {
                Add-ADGroupMember -Identity ($strs[$i].Substring(5)) -Members $tmp
                $added += ($strs[$i].Substring(5))
                $numsearched += 1
            }
        }
    }
    catch {
        Write-Host "An error occurred: $($_.Exception.Message)"
    }
  
}

# Print out information about where the user was / was not added to
if ($added.Count -ne 0) {
    Write-Host "Added the user '$Username' to --> "
    $added
}
else {
    Write-Host "There were no known groups associated with the job specified ('$Job'). If this is the first instance of a user with this job being added to the group, add the user manually"
    Read-Host "Press enter to exit."
}