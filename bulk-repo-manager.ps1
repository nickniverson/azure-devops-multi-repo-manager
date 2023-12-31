param (
    # workspace root is directory where you store your git repos... 
    [string]$WorkspaceRoot = "c:\code",
    [string]$ProjectName = "test-repo-powershell-script",
    [string]$BranchName = "nln/test-hook/main",
    [string]$AzureDevOpsOrganizationBaseUrl = "https://nick-niverson.visualstudio.com",
    [string[]]$IncludedRepos = @("repo-1", "repo-2", "repo-3"),
    [hashtable[]]$ProcessingHooks = @(
        # @{
        #     DisplayName = "git: status"
        #     ScriptPath = "git-status-hook.ps1"
        # },
        # @{
        #     DisplayName = "git: delete branch"
        #     ScriptPath = "git-delete-branch-hook.ps1"
        #     Parameters = @{
        #         BranchToDelete = "nln/test-hook/main"
        #     }
        #     SkipCommit = $true
        # },
        # @{
        #     DisplayName = "test hook"
        #     ScriptPath = "test-hook.ps1"
        #     Parameters = @{
        #         Message = "hello world"
        #     }
        # },
        # @{
        #     DisplayName = "copy test1.txt to root folder"
        #     ScriptPath = "file-copy-hook.ps1"
        #     Parameters = @{
        #         SourceFilePath = Join-Path $PSScriptRoot "test1.txt"
        #         DestinationRelativePath = "test1.txt"
        #     }
        #     CommitMessage = "add test1.txt"
        # },
        # @{
        #     DisplayName = "copy test1.txt to sub folder"
        #     ScriptPath = "file-copy-hook.ps1"
        #     Parameters = @{
        #         SourceFilePath = Join-Path $PSScriptRoot "test1.txt"
        #         DestinationRelativePath = "test\test1.txt"
        #     }
        #     CommitMessage = "add test\test1.txt"
        # },
        # @{
        #     DisplayName = "copy test2.txt to sub folder"
        #     ScriptPath = "file-copy-hook.ps1"
        #     Parameters = @{
        #         SourceFilePath = Join-Path $PSScriptRoot "test2.txt"
        #         DestinationRelativePath = "test\test2.txt"
        #     }
        #     CommitMessage = "add test\test2.txt"
        # },
        # @{
        #     DisplayName = "copy test3.txt to sub folder"
        #     ScriptPath = "file-copy-hook.ps1"
        #     Parameters = @{
        #         SourceFilePath = Join-Path $PSScriptRoot "test3.txt"
        #         DestinationRelativePath = "test\test3.txt"
        #     }
        #     CommitMessage = "add test\test3.txt"
        # },
        # @{
        #     DisplayName = "replace 'test' with 'hello world'"
        #     ScriptPath = "regex-replacement-hook.ps1"
        #     Parameters = @{
        #         Filter = "test1.txt"
        #         Pattern = "test"
        #         Replacement = "hello world"
        #     }
        #     CommitMessage = "testing regex hook"
        # }
    )
)


function Main {
    # Get list of repositories
    $repos = az repos list `
        --project $ProjectName `
        --organization $AzureDevOpsOrganizationBaseUrl `
        | ConvertFrom-Json

    $includedReposLower = $IncludedRepos | ForEach-Object { $_.ToLower() }

    foreach ($repo in $repos) {
        # skip any excluded repos
        if ($repo.name.ToLower() -notin $includedReposLower) {
            Write-Verbose "Skipping excluded repository: '$($repo.name)'"
            Write-Verbose ""
            Write-Verbose ""

            continue
        }

        DisplayHeader -Content "processing git repository: '$($repo.name)'"

        $localRepoPath = Join-Path $WorkspaceRoot -ChildPath (Join-Path $ProjectName $repo.name)

        if (!(Test-Path -Path $localRepoPath)) {
            # Placeholder for actual cloning command
            Write-Host "Cloning '$($repo.name)' to '$localRepoPath'"
            git clone $repo.remoteUrl $localRepoPath
        }
        else {
            Write-Host "repo '$($repo.name)' already exists... skipping clone"
        }

        Push-Location -Path $localRepoPath

        # make sure local copy is up-to-date 
        git fetch

        $remoteBranchExists = (git ls-remote --heads origin $BranchName)
        $localBranchExists = (git branch --list $BranchName)

        # checkout the branch if it already exists, else create it... 
        if ($localBranchExists -or $remoteBranchExists) {
            Write-Host "Branch '$BranchName' already exists in '$($repo.name)'...  switching to branch '$BranchName'..."

            $currentBranch = (git branch --show-current)

            if ($currentBranch -ne $BranchName) {
                git checkout $BranchName
            }
        } else {
            Write-Host "creating branch '$BranchName' in repo '$($repo.name)'"
            git checkout -b $BranchName
            git push --set-upstream origin $BranchName
        }

        $pushChanges = $false

        # Invoke processing hooks
        foreach ($hook in $ProcessingHooks) {
            $context = [ordered]@{
                # script parameters
                WorkspaceRoot = $WorkspaceRoot
                ProjectName = $ProjectName
                BranchName = $BranchName
                AzureDevOpsOrganizationBaseUrl = $AzureDevOpsOrganizationBaseUrl
                ExcludedRepos = $ExcludedRepos

                # general
                ScriptRootPath = $PSScriptRoot

                # loop locals
                CurrentRepo = $Repo
                CurrentLocalRepoPath = $localRepoPath
                CurrentHook = $hook
            }

            $scriptPath = Join-Path $PSScriptRoot $hook.ScriptPath

            if (Test-Path -Path $scriptPath) {
                & $scriptPath -Context $context
            } else {
                Write-Warning "Processing hook script not found: $scriptPath"

                continue
            }
            
            # Stage, commit, and push changes
            if ((-not $hook.SkipCommit) -and (git status --porcelain)) {
                $commitMessage = "automated changes by bulk-repo-manager.ps1 script"
                if ($hook.CommitMessage) {
                    $commitMessage = "bulk-repo-manager.ps1: $($hook.CommitMessage)"
                }

                git add .
                git commit -m $commitMessage

                # if any processing hook commits changes, then we need to push
                $pushChanges = $true
            }
        }

        if ($pushChanges){
            git push
        }

        Pop-Location

        # blank lines for readability
        Write-Host ""
        Write-Host ""
    }
}


function DisplayHeader {
    param ([string] $Content)

    $line = "".PadLeft($Content.Length, '-')

    Write-Host $line
    Write-Host $Content
    Write-Host $line
}


# call main
Main