Function Overwrite-AppPackageConfigFileWithGlobalVariables($envConfig){
    $envConfig.apps | % { 
        $_.config = New-PackageConfigFile $_ $envConfig
        Write-Host "Overwritten config file[$($_.config)] for package[$($_.package)] on server[$($_.server)]"
    }
}

Function Write-NewConfigFile($appConfig, $appPackageconfig, $envConfig){
    $appliedConfigsFolder = "$($envConfig.packageConfigFolder)\..\applied-app-configs"
    $configFileName = "$($appConfig.package)-$($appConfig.version)-$((Get-Date).Ticks).ini"
    $newPackageConfigPath = "$appliedConfigsFolder\$configFileName"
    New-Item -Type File $newPackageConfigPath -Force | Out-Null
    $appPackageconfig.GetEnumerator() | % { "$($_.key) = $($_.value)" } | Set-Content $newPackageConfigPath 
    $newPackageConfigPath
}

Function New-PackageConfigFile($appConfig, $envConfig){
    $appPackageconfig = Import-Config $appConfig.config
    $appPackageconfig = Resolve-Variables $appPackageconfig $envConfig.variables
    Write-NewConfigFile $appConfig $appPackageconfig $envConfig
}