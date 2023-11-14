param ([hashtable]$Context)


function Main {
    Write-Host "processing hook:  $($Context.CurrentHook.DisplayName)" 

    Write-Host "executing command: git status" -ForegroundColor Green
    
    git status
}


# call main
Main