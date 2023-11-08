param ([hashtable]$Context)

terraform fmt $Context.CurrentLocalRepoPath -recursive
