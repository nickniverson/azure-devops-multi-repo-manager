param ([hashtable]$Context)

function Main {
    Write-Host "processing hook:  $($Context.CurrentHook.DisplayName)" 

    $filter = "*" # assume all files are fair game if no filter provided
    
    if ($Context.CurrentHook.Parameters.Filter) { 
        $filter = $Context.CurrentHook.Parameters.Filter
    }
    
    $files = Get-ChildItem -Path $Context.CurrentLocalRepoPath -Recurse -Filter $filter
    
    foreach ($file in $files) {
        Write-Verbose "regex-replacement-hook - processing file:  $($file.FullName)"
    
        $originalFileContent = (Get-Content -Path $file.FullName -Raw)
    
        # skip empty files
        if ([string]::IsNullOrWhiteSpace($originalFileContent)) {
            continue
        }
    
        $modifiedFileContent = $originalFileContent -replace $($Context.CurrentHook.Parameters.Pattern), $($Context.CurrentHook.Parameters.Replacement)
    
        if ($originalFileContent.Trim() -eq $modifiedFileContent.Trim()){
            continue
        }   
    
        $modifiedFileContent | Set-Content -Path $file.FullName -NoNewline
    
        Write-Verbose "regex-replacement-hook - processed file:  $($file.FullName)" -ForegroundColor Green
    }
}


# call main
Main