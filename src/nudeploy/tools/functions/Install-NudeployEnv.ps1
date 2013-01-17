Function Install-NuDeployEnv{
    param(
       [Parameter(Mandatory=$true, Position=0)][string] $envPath,
       [string] $versionSpec,
       [string] $nugetRepoSource,
       [string] $nugetExeUrl
    )
    $envConfig = Get-DesiredEnvConfig $envPath $nugetRepoSource $versionSpec
    Prepare-AllNodes $envConfig | Out-Null
    Deploy-AllApps $envConfig | Out-Null
    ,$envConfig.apps
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
    Overwrite-ConfigValue $envConfig 'nugetRepo' $nugetRepoSource
    Overwrite-AppVersionWithVersionSpec $envConfig $versionSpecPath
    Set-DefaultAppVersionWithLatestVersion $envConfig
    Set-DefaultAppConfigFile $envConfig
    Overwrite-AppPackageConfigFileWithGlobalVariables $envConfig
    Assert-AppConfigs $envConfig
    $envConfig
}

Function Assert-AppConfigs($envConfig) {
    if (-not $envConfig.apps) {
        throw "appEnvConfigs is not configured properly. "
    }    
    $envConfig.apps | %{
        if(-not($_.server)){
            throw "Server of package $_.package is not found"
        }
        if(-not($_.version)){
            throw "Version of package $_.package is not found"
        }
        if(-not($_.config) -or (-not (Test-Path $_.config))){
            throw "Config of package $_.package is not found"
        }
    }
    if(-not $envConfig.variables.ENV){
        Write-Host 'Warning: Environment variables are not set in $envConfig.variables.ENV' -f yellow
    }
}

Function Prepare-AllNodes($envConfig){
    $targetNodes = $envConfig.apps | % { $_.server } | Get-Unique
    Add-HostAsTrusted $targetNodes
    $targetNodes | % { Prepare-Node $_ $envConfig.nugetRepo $envConfig.nodeDeployRoot $envConfig.nodeNuDeployVersion} | out-null
    
}
Function Add-HostAsTrusted($targetNodes) {
    winrm set winrm/config/client "@{TrustedHosts=`"$($targetNodes -join ",")`"}" | Out-Null
}
Function Prepare-Node($server, $nugetRepo, $nodeDeployRoot, $nodeNuDeployVersion){
    Write-Host "Preparing to deploy on node [$server]...." -f cyan

    Run-RemoteScript $server {
        param($nodeDeployRoot)
        Remove-Item $nodeDeployRoot -r -Force -ErrorAction silentlycontinue
        New-Item $nodeDeployRoot -type directory -ErrorAction silentlycontinue
        New-Item "$nodeDeployRoot\tools" -type directory -ErrorAction silentlycontinue
        New-Item "$nodeDeployRoot\nupkgs" -type directory -ErrorAction silentlycontinue
    } -argumentList $nodeDeployRoot | out-null

    $nuget = "$PSScriptRoot\tools\nuget\nuget.exe"
    if(-not $nugetExeUrl){
        Copy-FileRemote $server "$nuget" "$nodeDeployRoot\tools\nuget.exe" | out-null
    } else {
        Run-RemoteScript $server {
            param($nugetExeUrl, $nodeDeployRoot)
            $webClient = new-object System.Net.WebClient
            $webClient.DownloadFile($nugetExeUrl, "$nodeDeployRoot\tools\nuget.exe")
        } -argumentList $nugetExeUrl, $nodeDeployRoot | out-null        
    }    

    $nuDeployPackageId = 'NScaffold.NuDeploy'
    $nuDeploySource = Prepre-NudeploySource $nugetRepo

    Run-RemoteScript $server {
        param($nodeDeployRoot, $nuDeployPackageId, $nuDeploySource)
        Push-Location
        Set-Location "$nodeDeployRoot\tools"
        if($nodeNuDeployVersion) {
            & ".\nuget.exe" install $nuDeployPackageId -source $nuDeploySource -version $nodeNuDeployVersion -NoCache
        }else{
            & ".\nuget.exe" install $nuDeployPackageId -source $nuDeploySource -NoCache
        }
        if(-not($LASTEXITCODE -eq 0)){
            throw "Setup nuDeployPackage failed"
        }
        Pop-Location
    } -argumentList $nodeDeployRoot, $nuDeployPackageId, $nuDeploySource | out-null
    Write-Host "Node [$server] is now ready for deployment.`n" -f cyan
}
Function Prepre-NudeploySource($nugetRepo) {
    $nuDeployPackageId = 'NScaffold.NuDeploy'
    $nuget = "$PSScriptRoot\tools\nuget\nuget.exe"
    $isNudeployInRepo = [boolean](& $nuget list $nuDeployPackageId -source $nugetRepo | ? { 
        $_ -match "^$nuDeployPackageId (?<version>(?:\d+\.)*\d+(?:-(?:\w|-)*)?)" })

    if(-not $isNudeployInRepo){
        $nupkg = Get-Item "$PSScriptRoot\..\*.nupkg"
        Copy-FileRemote $server $nupkg.FullName "$nodeDeployRoot\nupkgs\$($nupkg.Name)" | out-null
        "$nodeDeployRoot\nupkgs\"
    } else {
        $nugetRepo  
    }
}

Function Deploy-AllApps($envConfig){
    $envConfig.apps | % { Deploy-App $_ $envConfig }
}
Function Deploy-App ($appConfig, $envConfig) {
    $appConfig.env = $envConfig.variables.ENV
    $features = $appConfig.features
    $forceRedeploy = $features -contains "forceRedeploy"

    Skip-IfAlreadyDeployed $envConfig.deploymentHistoryFolder $appConfig $forceRedeploy {
        $nugetRepo = $envConfig.nugetRepo
        $nodeDeployRoot = $envConfig.nodeDeployRoot 

        $packageConfig = Import-Config $appConfig.config
        Run-RemoteScript $appConfig.server {
            param($nodeDeployRoot, $version, $package, $nugetRepo, $packageConfig, $features)
            $destAppPath = "$nodeDeployRoot\$package" 

            $nudeployModule = Get-ChildItem "$nodeDeployRoot\tools" "nudeploy.psm1" -Recurse

            Import-Module $nudeployModule.FullName -Force
            Install-NuDeployPackage -packageId $package -version $version -source $nugetRepo -workingDir $destAppPath -co $packageConfig -features $features        

        } -ArgumentList $nodeDeployRoot, $appConfig.version, $appConfig.package, $nugetRepo, $packageConfig, $features
    }
}