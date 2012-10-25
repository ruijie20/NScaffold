function New-EnvironmentConfig ($envPath) {
    if (-not (Test-Path "$envPath")) {
        New-Item "$envPath" -Type Directory | Out-Null
@"
throw 'Remove this line after properly configured. '
`$appEnvConfigs = @(
    @{
        'package' = 'foo'
        'server' = 'Node1'
        'version' = '1.0.0'
        'appConfig' = 'somePathToConfig'
        'features' = @()
    }, 
    @{
        'package' = 'bar'
        'server' = 'Node2'
        'version' = '1.0.0'
        'appConfig' = 'somePathToConfig'
        'features' = @()
    }
)
"@ |    Set-Content "$envPath\env.config.ps1"
        New-Item "$envPath\app-configs" -Type Directory | Out-Null
        New-Item "$envPath\app-configs\foo.ini" -Type File | Out-Null
        New-Item "$envPath\app-configs\bar.ini" -Type File | Out-Null
        Write-Host "The scaffold of environment $env has already been set up. Please config it properly. " -f cyan      
    } else {
        Write-Host "Already exists. " -f cyan    
    }
}