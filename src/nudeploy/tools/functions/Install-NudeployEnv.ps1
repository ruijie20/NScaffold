Function Install-NuDeployEnv{
    param(
       [Parameter(Mandatory=$true, Position=0)][string] $envPath,
       [string] $versionSpec,
       [string] $nugetRepoSource,
       [string] $nugetExeUrl
    )
    $envGlobalConfig = Get-DesiredEnvConfig $envPath
    $versionConfig = Import-VersionSpec $versionSpec
    Resolve-AllPackageVersion $envGlobalConfig $versionConfig

    Prepare-AllNodes $envGlobalConfig
    Deploy-AllApps $envGlobalConfig
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

Function Get-DesiredEnvConfig($envPath) {
    $envConfigFile = Get-EnvConfigFilePath $envPath
    $envGlobalConfig = & $envConfigFile

    Set-PackageConfigFolder $envGlobalConfig $envConfigFile
    Set-DeploymentHistoryFolder $envGlobalConfig
    Set-NodeDeploymentRoot $envGlobalConfig
    Set-NugetRepo $envGlobalConfig $nugetRepoSource
    Assert-AppConfigs $envGlobalConfig
    $envGlobalConfig
}

Function Set-PackageConfigFolder($envGlobalConfig, $envConfigFile) {
    if(-not ($envGlobalConfig.packageConfigFolder)){
        $envGlobalConfig.packageConfigFolder = "$envConfigFile\..\app-configs"
    }
    Write-Host "Using package config folder at [$($envGlobalConfig.packageConfigFolder)]..." -f cyan
}

Function Set-DeploymentHistoryFolder($envGlobalConfig) {
    if(-not ($envGlobalConfig.deploymentHistoryFolder)){
        $envGlobalConfig.deploymentHistoryFolder = "$($envGlobalConfig.packageConfigFolder)\..\deployment-history"
    }
    Write-Host "Using deploymentHistoryFolder at [$($envGlobalConfig.deploymentHistoryFolder)]..." -f cyan
}

Function Set-NodeDeploymentRoot($envGlobalConfig) {
    if (-not $envGlobalConfig.nodeDeployRoot) {
        $envGlobalConfig.nodeDeployRoot = "C:\deployment"
    }
}

Function Set-NugetRepo($envGlobalConfig, $nugetRepoSource) {
    if($nugetRepoSource){
        $envGlobalConfig.nugetRepo = $nugetRepoSource
    }elseif(-not $envGlobalConfig.nugetRepo) {
        throw "nugetRepo is not configured properly. "  
    }    
}

Function Assert-AppConfigs($envGlobalConfig) {
    if (-not $envGlobalConfig.apps) {
        throw "appEnvConfigs is not configured properly. "
    }    
}

Function Import-VersionSpec($versionSpec) {
    if($versionSpec -and (Test-Path $versionSpec)) {
        $versionConfig = Import-Config $versionSpec
        Write-Host "Version spec is found:" 
        $versionConfig.GetEnumerator() | Sort-Object -Property Name | Out-Host
    }else{
        $versionConfig = @{}
    }
    $versionConfig
}

Function Resolve-LatestPackageVersion($package, $nugetRepo){
    $nuget = "$PSScriptRoot\tools\nuget\nuget.exe"
    Write-Host "$nuget list $package -source $nugetRepo"
    if( (& $nuget list $package -source $nugetRepo | ? { 
        $_ -match "^$package (?<version>(?:\d+\.)*\d+(?:-(?:\w|-)*)?)" })){
        Write-Host "Found lastest version $($matches['version']) for package [$package]"
        return $matches['version']
    }else{
        throw "No version found for package [$package] in repo [$nugetRepo]"
    }
}

Function Resolve-AllPackageVersion($envGlobalConfig, $versionConfig) {
    $unversionPackages = $envGlobalConfig.apps | ? { -not $_.version }
    if(-not $unversionPackages) {return}
    $latestVersionPackages = $unversionPackages | % { $_.package } | Get-Unique | ? { -not ($versionConfig.keys -contains $_) }
    if($latestVersionPackages){
        $latestVersionPackages | %{ $versionConfig[$_] = Resolve-LatestPackageVersion $_ $envGlobalConfig.nugetRepo }
    }
    
    $unversionPackages | % {$_.version = $versionConfig[$_.package]}
    Write-Host "Resolved VersionSpec:"
    $versionConfig | Out-Host
}

Function Prepare-AllNodes($envGlobalConfig){
    $targetNodes = $envGlobalConfig.apps | % { $_.server } | Get-Unique
    Add-HostAsTrusted $targetNodes
    $targetNodes | % { Prepare-Node $_ $envGlobalConfig.nugetRepo $envGlobalConfig.nodeDeployRoot $envGlobalConfig.nodeNuDeployVersion} | out-null
    
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
            & ".\nuget.exe" install $nuDeployPackageId -source $nuDeploySource -version $nodeNuDeployVersion
        }else{
            & ".\nuget.exe" install $nuDeployPackageId -source $nuDeploySource
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

Function Deploy-AllApps($envGlobalConfig){
    $envGlobalConfig.apps | % { Deploy-App $_ $envGlobalConfig }
}

Function Deploy-App ($appConfig, $envGlobalConfig) {
    $appConfig.config = Get-DesiredPackageConfigFile $appConfig $envGlobalConfig
    $appConfig.env = $envGlobalConfig.variables.ENV

    $features = Get-DesiredPackageFeatures $appConfig
    $forceRedeploy = $features -contains "forceRedeploy"

    Skip-IfAlreadyDeployed $envGlobalConfig.deploymentHistoryFolder $appConfig $forceRedeploy {
        $nugetRepo = $envGlobalConfig.nugetRepo
        $nodeDeployRoot = $envGlobalConfig.nodeDeployRoot 
        $remoteConfigFile = "$nodeDeployRoot\$configFileName.ini"
        Copy-FileRemote $appConfig.server $appConfig.config $remoteConfigFile | out-null
        Run-RemoteScript $appConfig.server {
            param($nodeDeployRoot, $version, $package, $nugetRepo, $remoteConfigFile, $features)
            $destAppPath = "$nodeDeployRoot\$package" 
            $nudeployModule = Get-ChildItem "$nodeDeployRoot\tools" "nudeploy.psm1" -Recurse
            Import-Module $nudeployModule.FullName -Force

            $script:deployAppResultDir = Install-NuDeployPackage -packageId $package -version $version -source $nugetRepo -workingDir $destAppPath -config $remoteConfigFile -features $features        
        } -ArgumentList $nodeDeployRoot, $appConfig.version, $appConfig.package, $nugetRepo, $remoteConfigFile, $features
    }
}

Function Get-DesiredPackageConfigFile($appConfig, $envGlobalConfig){
    $configFileName = Get-OriginalPackageConfigFileName $appConfig
    New-PackageConfigFile $configFileName $envGlobalConfig.packageConfigFolder $envGlobalConfig.variables
}

Function Get-OriginalPackageConfigFileName($appConfig) {
    $configFileName = $appConfig.config
    if(-not $configFileName){
        $configFileName = $appConfig.package
    }
    $configFileName
}

Function New-PackageConfigFile($configFileName, $packageConfigFolder, $variables){
    $appliedConfigsDir = "$packageConfigFolder\..\applied-app-configs"
    $packageConfig = Import-PackageConfig $packageConfigFolder $configFileName
    $finalPackageConfigFile = "$appliedConfigsDir\$configFileName.ini"
    Build-FinalPackageConfigFile $packageConfig $variables $finalPackageConfigFile | out-null
    $finalPackageConfigFile
}

Function Get-DesiredPackageFeatures($appConfig) {
    $features = $appConfig.features 
    if(-not $features) {
        $features = @()
    }
    $features
}

Function Get-DesiredPackageConfigFile($envConfig) {
    $configFileName = $envConfig.config
    if(-not $configFileName){
        $configFileName = $appConfig.package
    }
    $configFileName
}

Function Import-PackageConfig($packageConfigFolder, $configFileName) {
    $configFullPath = "$packageConfigFolder\$configFileName.ini"
    if (-not (Test-Path $configFullPath)) {
        throw "Config file [$configFullPath] does not exist. "
    }
    $configFullPath
}

Function Get-ResolvedPackageConfig($packageConfig) {
    $envVariables = $envGlobalConfig.variables
    if($envVariables){
        $packageConfig = Merge-HashTable $packageConfig $envVariables
    }
    Resolve-Variables $packageConfig
}