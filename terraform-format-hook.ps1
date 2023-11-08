param ([hashtable]$Context)

Write-Host "executing command:  terraform fmt $($Context.CurrentLocalRepoPath) -recursive" -ForegroundColor Green

terraform fmt $Context.CurrentLocalRepoPath -recursive
