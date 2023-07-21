param (
    [Parameter(Mandatory = $true)]
    [string]$ParentFolder,

    [Parameter(Mandatory = $true)]
    [string]$SearchString,

    [string]$FilterType = 'Both' # Options: 'Folders', 'Files', 'Both'
)


if ($ParentFolder.Contains(":")) {
    $ParentFolder = $ParentFolder.Replace("\\", "\")
    $sub = $ParentFolder.Substring(0, 1)
    $rest = $ParentFolder.Substring(2)
    switch ($sub) {
        "J" { $ParentFolder = "\\uscosf5101.icig.global\GroupShares\Departments" + $rest }
        "K" { $ParentFolder = "\\uscosf5101.icig.global\GroupShares\Shared" + $rest }
        "L" { $ParentFolder = "\\uscosf5101.icig.global\GroupShares\SFA" + $rest }
        "V" { $ParentFolder = "\\cp4boufs102.icig.global\f\departments" + $rest }
        "W" { $ParentFolder = "\\cp4boufs101.icig.global\f\Projects" + $rest }
        "X" { $ParentFolder = "\\cp4boufs101.icig.global\f\Projects\Vault" + $rest }
        Default { Write-Host "You do not need an access request for your U or C drives. If you think this is an error, please ensure that your path name is correct" }
    }
}

function Search-FilesAndFolders {
    param (
        [string]$FolderPath,
        [string]$SearchString,
        [string]$FilterType
    )

    $folderPattern = "*$SearchString*"
    $filePattern = "*$SearchString*"

    if ($FilterType -eq 'Folders') {
        Get-ChildItem -LiteralPath $FolderPath -Directory -Recurse | Where-Object { $_.Name -like $folderPattern }
    }
    elseif ($FilterType -eq 'Files') {
        Get-ChildItem -LiteralPath $FolderPath -File -Recurse | Where-Object { $_.Name -like $filePattern }
    }
    elseif ($FilterType -eq 'Both') {
        Get-ChildItem -LiteralPath $FolderPath -Recurse | Where-Object { $_.Name -like $folderPattern -or $_.Name -like $filePattern }
    }
    else {
        Write-Host "Invalid filter type. Please choose 'Folders', 'Files', or 'Both'."
    }
}

# Check if the parent folder exists
if (Test-Path $ParentFolder -PathType Container) {
    Write-Host "Searching for '$SearchString' in '$FilterType' within '$ParentFolder'..."

    $results = Search-FilesAndFolders -FolderPath $ParentFolder -SearchString $SearchString -FilterType $FilterType

    if ($results.Count -gt 0) {
        Write-Host "Found matching items:"
        $results | ForEach-Object { Write-Host $_.FullName }
    }
    else {
        Write-Host "No matching items found."
    }
}
else {
    Write-Host "The parent folder '$ParentFolder' does not exist."
}