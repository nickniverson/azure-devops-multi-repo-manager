param (
    # workspace root is directory where you store your git repos... 
    [string]$WorkspaceRoot = "c:\code",
    [string]$ProjectName = "test-repo-powershell-script",
    [string]$BranchName = "nln/test-hook/main",
    [string]$AzureDevOpsOrganizationBaseUrl = "https://nick-niverson.visualstudio.com",
    [string[]]$ExcludedRepos = @("test-repo-powershell-script"),
    [hashtable[]]$ProcessingHooks = @(
        @{
            ScriptPath = ".\test-hook.ps1"
            Parameters = @{
                Message = "hello world"
            }
        },
        @{
            ScriptPath = "file-copy-hook.ps1"
            Parameters = @{
                SourceFilePath = Join-Path $PSScriptRoot "test.txt"
                DestinationRelativePath = "test\test.txt"
            }
            CommitMessage = "add test/test.txt"
        },
        @{
            ScriptPath = "file-copy-hook.ps1"
            Parameters = @{
                SourceFilePath = Join-Path $PSScriptRoot "test2.txt"
                DestinationRelativePath = "test\test2.txt"
            }
            CommitMessage = "add test\test2.txt"
        },
        @{
            ScriptPath = "file-copy-hook.ps1"
            Parameters = @{
                SourceFilePath = Join-Path $PSScriptRoot "test3.txt"
                DestinationRelativePath = "test\test3.txt"
            }
            CommitMessage = "add test\test3.txt"
        },
        @{
            ScriptPath = "regex-replacement-hook.ps1"
            Parameters = @{
                Filter = "*.txt"
                Pattern = "test"
                Replacement = "hello world"
            }
            CommitMessage = "testing regex hook"
        }
    )
)

function Main {
    # Get list of repositories
    $repos = az repos list `
        --project $ProjectName `
        --organization $AzureDevOpsOrganizationBaseUrl `
        | ConvertFrom-Json

    $excludedReposLower = $ExcludedRepos | ForEach-Object { $_.ToLower() }

    foreach ($repo in $repos) {
        # skip any excluded repos
        if ($repo.name.ToLower() -in $excludedReposLower) {
            Write-Warning "Skipping excluded repository: '$($repo.name)'"
            Write-Host ""
            Write-Host ""

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

        # checkout the branch if it already exists, else create it... 
        if (git branch --list $BranchName) {
            Write-Host "Branch '$BranchName' already exists in '$($repo.name)'...  switching to branch '$BranchName'..."

            $currentBranch = git branch --show-current

            if ($currentBranch -ne $BranchName) {
                git checkout $BranchName
            }
        } else {
            Write-Host "creating branch '$BranchName' in repo '$($repo.name)'"
            git checkout -b $BranchName
            git push --set-upstream origin $BranchName
        }

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
            if (git status --porcelain) {
                $commitMessage = "automated changes by bulk-repo-manager.ps1 script"
                if ($hook.CommitMessage) {
                    $commitMessage = "bulk-repo-manager.ps1: $($hook.CommitMessage)"
                }

                git add .
                git commit -m $commitMessage
                git push
            }
        }

        #     # Placeholder for actual pull request creation
        #     Write-Host "Creating pull request for $BranchName in $($repo.name)..."

        Pop-Location

        # blank line for readability
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