param ([hashtable]$Context)

function Main {
    Write-Host "processing hook:  $($Context.CurrentHook.DisplayName)" 

    Write-Host "executing command:  terraform fmt -recursive $($Context.CurrentLocalRepoPath)" -ForegroundColor Green
    
    terraform fmt -recursive $Context.CurrentLocalRepoPath
}


# call main
Main