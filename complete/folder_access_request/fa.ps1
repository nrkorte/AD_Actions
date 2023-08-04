# Folder access file to find and give permissions to users

# Accepts three arguments: A username and a path to a folder and permission level
param (
    [Parameter(Mandatory = $true)]
    [string]$Username,

    [Parameter(Mandatory = $true)]
    [string]$path,

    [Parameter(Mandatory = $true)]
    [string]$rwm
)

Import-Module ActiveDirectory

if (!$rwm.Contains("r") -and !$rwm.Contains("w") -and !$rwm.Contains("m")) {
    Write-Host "Your permissions (rwm) argument needs to contain an r, w, or m"
    exit
}

if ($Username.Length -eq 0 -or $path.Length -eq 0 -or $rwm.Length -eq 0) {
    Write-Host "No program arguments can be null, please ensure you entered all values in correctly"
    exit
}

if (!($null -ne ([ADSISearcher] "(SamAccountName=$Username)").FindOne())) {
    Write-Host "Could not find user: $($Username)"
    exit
}

# Give the full path if the user sends a drive name

if ($path.Contains(":")) {
    $path = $path.Replace("\\", "\")
    $sub = $path.Substring(0, 1)
    $rest = $path.Substring(2)
    switch ($sub) {
        "J" { $path = "\\uscosf5101.icig.global\GroupShares\Departments" + $rest }
        "K" { $path = "\\uscosf5101.icig.global\GroupShares\Shared" + $rest }
        "L" { $path = "\\uscosf5101.icig.global\GroupShares\SFA" + $rest }
        "M" { $path = "\\uscosf5101.icig.global\GroupShares\Apps" + $rest }
        "R" { $path = "\\cp4boufs101.icig.global\g\forms" + $rest }
        "V" { $path = "\\cp4boufs102.icig.global\f\departments" + $rest }
        "W" { $path = "\\cp4boufs101.icig.global\f\Projects" + $rest }
        "X" { $path = "\\cp4boufs101.icig.global\f\Projects\Vault" + $rest }
        Default { Write-Host "You do not need an access request for your U or C drives. If you think this is an error, please ensure that your path name is correct" }
    }
}

$FolderPath = $path
$GroupPrefix = "ICIG\"

# Check to see what groups have access to the folder
try {
    # This command gets the windows security groups and the AD groups attached to a folder based on the path the user provided
    $Acl = Get-Acl -Path $FolderPath -ErrorAction Stop
}
catch {
    Write-Host "$_"
    exit
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

$fuck_it_we_ball = $false
$savestate = $ret | Where-Object { $_ -match "[-](M|R|W)$" }
if ($savestate.Count -lt 1) {
    [String[]]$big_array = "ICIG\QC_CofA", "ICIG\QC_TLC_Pictures", "ICIG\ROUFCT_ClientAdmin", "ICIG\ROUFCT_ITAdmins", "ICIG\ROUFCT_PlantSups", "ICIG\ROUORG_AllUsers", "ICIG\ROUORG_RCCPlantCommunication", "Boulder-Test-Mig1"
    $ret = $ret | Where-Object { $big_array -contains $_ }
    $fuck_it_we_ball = $true
}
else {
    $ret = $ret | Where-Object { $_ -match "[-](M|R|W)$" }
}
$endret = $ret


if (!$fuck_it_we_ball) {
    # Remove the unspecified permissions
    if ($rwm.Contains("m")) {
        $ret = $ret | Where-Object { ($_.EndsWith("-M")) }
    }
    elseif ($rwm.Contains("w")) {
        $ret = $ret | Where-Object { ($_.EndsWith("-W")) }
        if ($ret.Count -lt 1) {
            $tm = Read-Host "There was no write access found in association with the folder $path. Did you mean to request modify access? y/n"
            if ($tm -eq "y") {
                $ret = $savestate
                $ret = $ret | Where-Object { ($_.EndsWith("-M")) }
            }
            else {
                Write-Host "There were no known groups we could add the user to with the specified permissions -" $rwm "- The groups found are listed below"
                exit
            }
        }
    }
    elseif ($rwm.Contains("r")) {
        $ret = $ret | Where-Object { ($_.EndsWith("-R")) }
    }
}

$added = @()
$already = @()

# For every group that contains the job of the user, add the user to that group
foreach ($element in $ret) {
    try {
        $group = Get-ADGroup ($element.Substring(5))
        $error.Clear()
        & ".\user_to_group.ps1" $Username $group
        if ($error.Count -eq 0) {
            $added += ($element.Substring(5))
        }
        else {
            $already += ($element.Substring(5))
        }
    }
    catch {
        Write-Host "An error occurred: $($_.Exception.Message)"
    }
  
}

$full_name = (Get-ADUser $Username).Name

# Print out information about where the user was / was not added to
if ($added.Count -ne 0 -or $already.Count -ne 0) {
    if ($added.Count -ne 0) {
        Write-Host "Added the user '$full_name' to --> "
        $added
    }
    if ($already.Count -ne 0) {
        Write-Host "User '$full_name' was already found in --> "
        $already
    }
}
else {
    Write-Host "There were no known groups we could add the user to with the specified permissions -" $rwm "- The groups found are listed below"
    $endret
}