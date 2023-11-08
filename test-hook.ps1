param([hashtable]$Context)


function Main {
    Write-Host "test-hook:  $($Context.CurrentHook.Parameters.Message)"

    # $context | ConvertTo-Json 
}


# call main
Main