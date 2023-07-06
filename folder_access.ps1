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
    Write-Host "Your permissions (rwm) argument needs to contain an r, a w, or an m"
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
        "J" { $path = "\\" + $rest }
        "K" { $path = "\\" + $rest }
        "L" { $path = "\\" + $rest }
        "V" { $path = "\\" + $rest }
        "W" { $path = "\\" + $rest }
        "X" { $path = "\\" + $rest }
        Default { Write-Host "You do not need an access request for your U or C drives. If you think this is an error, please ensure that your path name is correct" }
    }
}

$FolderPath = $path
$GroupPrefix = ""

# Check to see what groups have access to the folder
try {
    # This command gets the windows security groups and the AD groups attached to a folder based on the path the user provided
    $Acl = Get-Acl -Path $FolderPath -ErrorAction Stop
}
catch {
    Write-Host "$_. Attempting to connect the drive manually"
    try {
        New-PSDrive -Name "G" -PSProvider "FileSystem" -Root "$FolderPath"
        $Acl = Get-Acl -Path $FolderPath -ErrorAction Stop
    }
    catch {
        Write-Host "Could not connect to drive, if you think this is an error, please send a detailed message to IT explaining what you're trying to gain access to."
        exit
    }
}

# Remove all groups that don't start with "prefix"
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
    [String[]]$big_array = ""
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
        $ret = $ret | Where-Object { !($_.EndsWith("-W")) }
        $ret = $ret | Where-Object { !($_.EndsWith("-R")) }
    }
    elseif ($rwm.Contains("w")) {
        Write-Host "There was no write access found in association with the folder $path. Did you mean to request modify access?"
        $ret = $ret | Where-Object { !($_.EndsWith("-R")) }
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

# Print out information about where the user was / was not added to
if ($added.Count -ne 0 -or $already.Count -ne 0) {
    if ($added.Count -ne 0) {
        Write-Host "Added the user '$Username' to --> "
        $added
    }
    if ($already.Count -ne 0) {
        Write-Host "User '$Username' was already found in --> "
        $already
    }
}
else {
    Write-Host "There were no known groups we could add the user to with the specified permissions -" $rwm "- The groups found are listed below"
    $endret
}
