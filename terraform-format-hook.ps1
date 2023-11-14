param ([hashtable]$Context)

Write-Host "executing command:  terraform fmt -recursive $($Context.CurrentLocalRepoPath)" -ForegroundColor Green

terraform fmt -recursive $Context.CurrentLocalRepoPath
