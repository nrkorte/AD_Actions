# TODO: Change third parameter to mandatory and require specific access levels


# Accepts two arguments: A username and a path to a folder
param (
    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [string]$path,

    [Parameter(Mandatory = $false)]
    [string]$read
)
Import-Module ActiveDirectory

if (!($null -ne ([ADSISearcher] "(SamAccountName=$Username)").FindOne())) {
    Write-Host "Could not find user: $($Username)"
    exit
}

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



# Check to see if user has a non-empty job
$filter_user = Get-ADUser -Filter "SamAccountName -eq '$Username'"
$ggg = Get-ADUser -Identity $filter_user -Properties Description | Select-Object -ExpandProperty Description
if ($null -eq $ggg) {
    Write-Host "Specified user has no job listed in the description section in the Active Directory Suite, please add a job and restart this program."
    exit
}
else {
    $Job = $ggg
}

$FolderPath = $path
$GroupPrefix = "ICIG\"

# Check to see what groups have access to the folder
try {
    # This command gets the windows security groups and the AD groups attached to a folder based on the path the user provided
    $Acl = Get-Acl -Path $FolderPath
}
catch {
    Write-Host "Could not find path to folder: $($element): $_"
}

# Remove all groups that don't start with "ICIG\"
$Groups = $Acl.Access | Where-Object { $_.IdentityReference.Value -like "${GroupPrefix}*" } | Select-Object -ExpandProperty IdentityReference

# Remove all duplicate elements in the groups and put it in $ret
[String[]]$ret = @()
foreach ($element in $Groups) {
    if (-not($ret -contains $element)) {
        $ret += Write-Output $element
    }
}

# Remove it if it does not end in "-M" "-W" or "-R"
$ret = $ret | Where-Object { $_ -match "[-](M|R|W)$" }

# Make a k/v pair to store the group as the k and the jobs that are part of that group as the v
$permission_job = @{}
foreach ($element in $ret) {
    try {
        # For each group that did not get filtered out get all the members and place them in an array
        $members = Get-ADGroupMember -Identity $element.Substring(5) -ErrorAction Stop
        $descriptionHash = @{}
        foreach ($member in $members) {
            if ($member.objectClass -eq "user") {
                try {
                    $user = Get-ADUser -Identity $member -Properties Description -ErrorAction Stop
                    $description = $user.Description
                    # Get all of the jobs relating to each group and place it in an array called descriptionsHash
                    if ($null -ne $description -and !$descriptionHash.ContainsKey($description)) {
                        $descriptionHash[$description] = $true
                    }
                }
                catch {
                    Write-Host "Failed to retrieve user information for member $($member.Name): $_"
                }
            }
        }
        # As long as there is at least one description, build the k/v pair where the group is the k and the jobs are the v
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

# For every group that contains the job of the user, add the user to that group
for ($i = 0; $i -lt $permission_job.Count; $i++) {
    try {
        $group = Get-ADGroup ($ret[$i].Substring(5))
        # If the current group contains the same job as our user
        if ($permission_job[$ret[$i]] -contains $Job) {
            & ".\user_to_group.ps1" $Username $group
            $added += ($strs[$i].Substring(5))
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
    Write-Host "There were no known groups associated with the job specified ('$Job'). If you see the job you would like your user to be added to below please type M, R, or W, respectively. If you are unsure which group they need to be added to, please confirm within Active Directory."
    $ret
    $test = Read-Host "M,R,W"
    for ($i = 0; $i -lt $permission_job.Count; $i++) {
        $group = Get-ADGroup ($ret[$i].Substring(5))
        if ($group.samAccountName -like "*$test") {
            & ".\user_to_group.ps1" $Username $Group
        }
    }
}