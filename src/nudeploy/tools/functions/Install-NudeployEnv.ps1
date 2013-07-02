Function Install-NuDeployEnv{
    param(
       [Parameter(Mandatory=$true, Position=0)][string] $envPath,
       [string] $versionSpec,
       [string] $nugetRepoSource,
       [switch] $DryRun
    )
    Log-Progress "Start Install-NuDeployEnv"
    $envConfig = Get-DesiredEnvConfig $envPath $nugetRepoSource $versionSpec
    Initialize-Nodes $envConfig | Out-Default
    $envConfig.apps | % { Deploy-App $_ $envConfig $dryRun}
}

Function Get-EnvConfigFilePath($envPath){
    if(Test-Path -PathType Leaf $envPath){
        $envConfigFile = $envPath
    }elseif (Test-Path "$envPath\env.config.ps1") {
        $envConfigFile = "$envPath\env.config.ps1"
        Write-Host "Please provide the environment configuration file directly rather than as 'env.config.ps1' under \$envPath" -f yellow
    }else{
        throw "Please provide the environment configuration file directly or as '$envPath\env.config.ps1'"
    }
    Write-Host "Using environment definition at [$envConfigFile]..." -f cyan
    $envConfigFile
}

Function Get-EnvConfig($envPath){
    $envConfigPath = Get-EnvConfigFilePath $envPath
    $envConfig = & $envConfigPath
    $envConfig.configPath = $envConfigPath
    $envConfig
}

Function Set-DefaultConfigValue($envConfig, $key, $value){
    if(-not ($envConfig[$key])){
        $envConfig[$key] = $value
        Write-Host "Using default config [$key] = [$value]" -f cyan
    }
}

Function Overwrite-ConfigValue($envConfig, $key, $value){
    if($value){
        $envConfig[$key] = $value
        Write-Host "Overwrite config [$key] = [$value]" -f cyan
    }    
    if(-not $envConfig[$key]){
        throw "config [$key] has no value"
    }
}

Function Get-DesiredEnvConfig($envPath, $nugetRepoSource, $versionSpecPath) {
    $envConfig = Get-EnvConfig $envPath
    Set-DefaultConfigValue $envConfig 'nodeDeployRoot' "C:\deployment"
    Set-DefaultConfigValue $envConfig 'packageConfigFolder' "$($envConfig.configPath)\..\app-configs"
    Set-DefaultConfigValue $envConfig 'deploymentHistoryFolder' "$($envConfig.packageConfigFolder)\..\deployment-history"
    Set-DefaultAppConfigFile $envConfig
    Overwrite-AppPackageConfigFileWithGlobalVariables $envConfig
    Overwrite-ConfigValue $envConfig 'nugetRepo' $nugetRepoSource
    Overwrite-AppVersionWithVersionSpec $envConfig $versionSpecPath
    Set-DefaultAppVersionWithLatestVersion $envConfig
    Assert-AppConfigs $envConfig
    $envConfig
}

Function Assert-AppConfigs($envConfig) {
    if (-not $envConfig.apps) {
        throw "appEnvConfigs is not configured properly. "
    }
    $envConfig.apps | %{
        if(-not($_.server)){
            throw "Server of package $($_.package) is not found"
        }
        if(-not($_.version)){
            throw "Version of package $($_.package) is not found"
        }
        if(-not($_.config) -or (-not (Test-Path $_.config))){
            throw "Config of package $($_.package) is not found"
        }
    }
    if(-not $envConfig.variables.ENV){
        Write-Host 'Warning: Environment variables are not set in $envConfig.variables.ENV' -f yellow
    }
    Log-Progress "Start Assert-PackagesInRepo"
    Assert-PackagesInRepo $envConfig
    Log-Progress "End Assert-PackagesInRepo"
}

Function Deploy-App ($appConfig, $envConfig, $dryRun) {
    $appConfig.env = $envConfig.variables.ENV
    $features = $appConfig.features
    $forceRedeploy = $features -contains "forceRedeploy"

    Log-Progress "Start Deploy-App $($appConfig.package)"
    $appConfig.exports = Skip-IfAlreadyDeployed $envConfig.deploymentHistoryFolder $appConfig -force:$forceRedeploy -dryRun:$dryRun {
        $nugetRepo = $envConfig.nugetRepo
        $nodeDeployRoot = $envConfig.nodeDeployRoot 

        $packageConfig = Import-Config $appConfig.config

        Log-Progress "Start Run-RemoteScript for $($appConfig.package) in $($appConfig.server)"
        Run-RemoteScript $appConfig.server {
            param($nodeDeployRoot, $version, $package, $nugetRepo, $packageConfig, $features, $dryRun)
            $destAppPath = "$nodeDeployRoot\$package" 

            $nudeployModule = Get-ChildItem "$nodeDeployRoot\tools" "nudeploy.psm1" -Recurse

            Import-Module $nudeployModule.FullName -Force
            Install-NuDeployPackage -packageId $package -version $version -source $nugetRepo `
                -workingDir $destAppPath -co $packageConfig -features $features -ignoreInstall:$dryRun
        } -ArgumentList $nodeDeployRoot, $appConfig.version, $appConfig.package, $nugetRepo, `
            $packageConfig, $features, $dryRun
    }
    Log-Progress "end Deploy-App $($appConfig.package)"
    $appConfig
}
