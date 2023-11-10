param ([hashtable]$Context)

$filter = "*" # assume all files are fair game if no filter provided

if ($Context.CurrentHook.Parameters.Filter) { 
    $filter = $Context.CurrentHook.Parameters.Filter
}

$files = Get-ChildItem -Path $Context.CurrentLocalRepoPath -Recurse -Filter $filter

foreach ($file in $files) {
    Write-Host "regex-replacement-hook - processing file:  $($file.FullName)" -ForegroundColor Green

    $originalFileContent = (Get-Content -Path $file.FullName)

    $modifiedFileContent = $originalFileContent -replace $($Context.CurrentHook.Parameters.Pattern), $($Context.CurrentHook.Parameters.Replacement)

    if ($originalFileContent -eq $modifiedFileContent){
        continue
    }   

    $modifiedFileContent | Set-Content -Path $file.FullName
}
