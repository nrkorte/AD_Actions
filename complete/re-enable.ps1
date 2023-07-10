param (
    [Parameter(Mandatory = $true)]
    [string]$number
)

Import-Module ActiveDirectory

$comp = Get-ADComputer -Filter "Name -like '*$number*'"
$name = Get-ADComputer -Filter "Name -like '*$number*'" | Select-Object -Property Name
if ($comp.Count -gt 0) {
    [String[]]$big_array = "CPC", "CP4"
    $comp = $comp | Where-Object { $_.Name -match "^($($big_array -join '|'))" }
    $name = $name | Where-Object { $_.Name -match "^($($big_array -join '|'))" }
}

if (-not $comp.Enabled) {
    while ($true) {
        $answer = Read-Host "$name has been disabled, would you like to re-enable it? y/n"
        if ($answer -like "y") {
            Set-ADComputer -Identity $comp -Enabled $true
            $desc = Read-Host "Add a description or hit ENTER to skip"
            if (-not $desc -eq "") {
                Set-ADComputer -Identity $comp -Description $desc
            }
            exit
        }
        elseif ($answer -like "n" -or $answer -like "") {
            exit
        }
        else {
            Write-Host "Please enter a y or an n"
        }
    }
}
else {
    while ($true) {
        $answer = Read-Host "$name is enabled, would you like to disable it? y/n"
        if ($answer -like "y") {
            Set-ADComputer -Identity $comp -Enabled $false
            $desc = Read-Host "Add a description or hit ENTER to skip"
            if (-not $desc -eq "") {
                Set-ADComputer -Identity $comp -Description $desc
            }
            exit
        }
        elseif ($answer -like "n" -or $answer -like "") {
            exit
        }
        else {
            Write-Host "Please enter a y or an n"
        }
    }
}