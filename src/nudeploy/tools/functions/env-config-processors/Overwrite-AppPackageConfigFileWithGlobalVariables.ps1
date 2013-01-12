Function Overwrite-AppPackageConfigFileWithGlobalVariables($envConfig){
    $envConfig.apps | % { 
        $_.config = New-PackageConfigFile $_.config $envConfig
        Write-Host "Overwritten config file[$($_.config)] for package[$($_.package)] on server[$($_.server)]"
    }
}

Function Merge-Config($packageConfig, $variables){
    if($variables){
        $packageConfig = Merge-HashTable $packageConfig $variables
    }
    Resolve-Variables $packageConfig
}

Function Write-NewConfigFile($packageConfig, $envConfig){
    $appliedConfigsFolder = "$($envConfig.packageConfigFolder)\..\applied-app-configs"
    $configFileName = (Get-Date).Ticks
    $newPackageConfigPath = "$appliedConfigsFolder\$configFileName.ini"
    New-Item -Type File $newPackageConfigPath -Force | Out-Null
    $packageConfig.GetEnumerator() | % { "$($_.key) = $($_.value)" } | Set-Content $newPackageConfigPath 
    $newPackageConfigPath
}

Function New-PackageConfigFile($packageConfigPath, $envConfig){
    $packageConfig = Import-Config $packageConfigPath
    $packageConfig = Merge-Config $packageConfig $envConfig.variables
    Write-NewConfigFile $packageConfig $envConfig
}