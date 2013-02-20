Function Skip-IfAlreadyDeployed ($root, $appConfig, [switch]$force, $scriptBlockToDeploy){    
    New-Item -itemtype directory $root -Force | Out-Null
    Function Register-SuccessDeployment($deployResult) {
        Remove-PreviousDeployment $root $appConfig.env $appConfig.server $appConfig.package
        try {
            Export-Clixml $lastDeploymentResult -InputObject $deployResult    
        } catch {
            Write-Warning $_
        }
        
        Copy-Item -Path $appConfig.config -Destination $lastDeploymentConfig
    }

    Function Test-AlreadyDeployed {
        (Test-Path $lastDeploymentConfig) -and (Test-ConfigFileEqual $lastDeploymentConfig $appConfig.config)
    }

    Function Convert-AppConfigToString {
        "package [$($appConfig.package)] version [$($appConfig.version)] on node [$($appConfig.server)] with config [$($appConfig.config)] of environment[$($appConfig.env)]"
    }

    Function Remove-PreviousDeployment{
        $fileNamePattern = @($appConfig.env, $appConfig.server, $appConfig.package, '*') -join '_'
        Get-ChildItem $root | %{ $_.name } | ? { $_ -like $fileNamePattern } | % { Remove-Item $root\$_ -Force }
    }

    Write-Host "Start deploying $(Convert-AppConfigToString $appConfig)" -f cyan
    $historyFilePrefix = @($appConfig.env, $appConfig.server, $appConfig.package, $appConfig.version) -join '_'
    $lastDeploymentConfig = "$root\$historyFilePrefix.ini"
    $lastDeploymentResult = "$root\$historyFilePrefix" + "_deployResult.xml"

    if((-not $force) -and (Test-AlreadyDeployed $appConfig)){
        Write-Host "$(Convert-AppConfigToString $appConfig) has ALREADY been deployed. Skip deployment." -f cyan
    }else{       
        $deployResult = (& $scriptBlockToDeploy)
        Register-SuccessDeployment $deployResult
        Write-Host "Succesfully deployed $(Convert-AppConfigToString $appConfig)." -f cyan
    }
    Import-Clixml $lastDeploymentResult
}

