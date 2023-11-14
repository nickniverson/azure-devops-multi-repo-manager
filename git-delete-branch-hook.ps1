param ([hashtable]$Context)


function Main {
    Write-Host "processing hook:  $($Context.CurrentHook.DisplayName)" 

    $branchToDelete = $Context.CurrentHook.Parameters.BranchToDelete
    
    if ([string]::IsNullOrWhiteSpace($branchToDelete)) {
        Write-Error "'BranchToDelete' parameter is required"
    
        exit
    }
    
    if ($branchToDelete.ToLower() -eq "master") {
        Write-Error "hey dummy!!! you almost deleted the 'master' branch... pay attention to what you're doing!!!... exiting"
    
        exit
    }
    
    if ($branchToDelete.ToLower() -eq "main") {
        Write-Error "hey dummy!!! you almost deleted the 'main' branch... pay attention to what you're doing!!!... exiting"
    
        exit
    }
    
    $currentBranch = (git branch --show-current)
    
    # can't delete the branch we're currently on... So, we need to switch over to a different branch... but might as well switch to 'master'
    if ($currentBranch -eq $branchToDelete) {
        $mainBranchName = (git branch --list master)
    
        if ([string]::IsNullOrEmpty($mainBranchName)) {
            $mainBranchName = (git branch --list main)
        }
        
        if ([string]::IsNullOrEmpty($mainBranchName)) {
            Write-Error "unable to determine main branch... exiting"
        
            exit
        }
    
        git checkout $mainBranchName.Trim()
    }
    
    Write-Host "deleting remote branch" -ForegroundColor Green
    Write-Host "executing command: git push origin --delete $branchToDelete" -ForegroundColor Green
    
    # delete remote branch
    git push origin --delete $branchToDelete
    
    Write-Host "deleting local branch" -ForegroundColor Green
    Write-Host "executing command: git branch -D $branchToDelete" -ForegroundColor Green
    
    # delete local branch
    git branch -D $branchToDelete
}


# call main
Main