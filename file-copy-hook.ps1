param ([hashtable]$Context)


function Main {
    if (!(Test-Path -Path $Context.CurrentHook.Parameters.SourceFilePath)) {
        Display-Error "Source file does not exist: $($Context.CurrentHook.Parameters.SourceFilePath)"

        exit
    }

    $destinationFilePath = Join-Path `
        -Path $Context.CurrentLocalRepoPath `
        -ChildPath $Context.CurrentHook.Parameters.DestinationRelativePath

    # create destination directory if it doesn't already exist
    $destinationDir = Split-Path -Path $destinationFilePath -Parent
    if (!(Test-Path -Path $destinationDir)) {
        New-Item `
            -ItemType Directory `
            -Path $destinationDir `
            -Force
    }

    if (Test-Path -Path $destinationFilePath) {
        $sourceContent = Get-Content $($Context.CurrentHook.Parameters.SourceFilePath) -Raw
        $destinationContent = Get-Content $destinationFilePath -Raw

        if ($sourceContent -eq $destinationContent){
            exit
        }
    }

    Copy-Item `
        -Path $Context.CurrentHook.Parameters.SourceFilePath `
        -Destination $destinationFilePath `
        -Force

    Display "File copied from '$($Context.CurrentHook.Parameters.SourceFilePath)' to '$destinationFilePath'" -ForegroundColor Green
}


function Display-Error {
    param([string]$message)

    Write-Error (Format $message)
}


function Display {
    param ([string]$message)
    
    Write-Host (Format $message)
}


function Format {
    param ([string]$message)

    return "file-copy-hook:  $message"
}


# call main
Main