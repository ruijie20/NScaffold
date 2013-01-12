Function Set-DefaultAppConfigFile($envConfig){
    $envConfig.apps |? {-not $_.config}| % { 
        $_.config = Get-DefaultAppConfigFilePath $_ $envConfig
        if(Test-Path $_.config){
            Write-Host "Using default config file[$($_.config)] for app[$($_.package)]"
        }else{
            throw "default config file[$($_.config)] for app[$($_.package)] NOT exist"
        }
    }
}
Function Get-DefaultAppConfigFilePath($appConfig, $envConfig){
    $configFileName = $appConfig.package
    "$($envConfig.packageConfigFolder)\$configFileName.ini"
}