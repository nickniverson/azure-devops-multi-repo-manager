param([hashtable]$Context)


function Main {
    Write-Host "processing hook:  $($Context.CurrentHook.DisplayName)" 

    Write-Host "test-hook:  $($Context.CurrentHook.Parameters.Message)"

    # $context | ConvertTo-Json 
}


# call main
Main