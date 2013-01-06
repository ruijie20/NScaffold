Function Install-NuDeployEnv{
    param(
       [Parameter(Mandatory=$true, Position=0)][string] $envPath,
       [string] $versionSpec,
       [string] $nugetRepoSource,
       [string] $nugetExeUrl
    )
    $envGlobalConfig = Get-DesiredEnvConfig $envPath
    $nodeDeployRoot = Get-DesiredNodeDeploymentRoot $envGlobalConfig
    $nugetRepo = Get-DesiredNugetRepo $envGlobalConfig $nugetRepoSource
    $nodeNuDeployVersion = $envGlobalConfig.nodeNuDeployVersion
    $appEnvConfigs = Get-DesiredAppConfigs $envGlobalConfig
    $versionConfig = Import-VersionSpec $versionSpec
    $targetNodes = $appEnvConfigs | % { $_.server } | Get-Unique
    Add-HostAsTrusted $targetNodes
    $targetNodes | % { Prepare-Node $_ $nugetRepo $nodeDeployRoot $nodeNuDeployVersion} | out-null
    $allResult = @()
    $appEnvConfigs | % { 
        $deployAppResultVersion = Deploy-App $_ $versionConfig $nugetRepo $nodeDeployRoot $envGlobalConfig.packageConfigFolder
        $result = @{}
        $result["package"] = $_.package
        $result["version"] = $deployAppResultVersion
        $allResult = $allResult + $result
    }
    return $allResult
}

Function Get-DesiredEnvConfig($envPath) {
    if(Test-Path -PathType Leaf $envPath){
        $envConfigFile = $envPath
    }elseif (Test-Path "$envPath\env.config.ps1") {
        $envConfigFile = "$envPath\env.config.ps1"
        Write-Host "Please provide the environment configuration file directly rather than as 'env.config.ps1' under \$envPath" -f yellow
    }else{
        throw "Please provide the environment configuration file directly or as '$envPath\env.config.ps1'"
    }
    Write-Host "Using environment definition at [$envConfigFile]..." -f cyan

    $envGlobalConfig = & $envConfigFile
    if(-not ($envGlobalConfig.packageConfigFolder)){
        $envGlobalConfig.packageConfigFolder = "$envConfigFile\..\app-configs"
    }
    Write-Host "Using package config folder at [$($envGlobalConfig.packageConfigFolder)]..." -f cyan

    $envGlobalConfig
}

Function Get-DesiredNodeDeploymentRoot($envGlobalConfig) {
    $nodeDeployRoot = $envGlobalConfig.nodeDeployRoot
    if (-not $nodeDeployRoot) {
        $nodeDeployRoot = "C:\deployment"
    }
    $nodeDeployRoot
}

Function Get-DesiredNugetRepo($envGlobalConfig, $nugetRepoSource) {
    $nugetRepo = $envGlobalConfig.nugetRepo
    if (-not $nugetRepo) {
        $nugetRepo = $nugetRepoSource
        if (-not $nugetRepo) {
            throw "nugetRepo is not configured properly. "    
        }
    }    
    $nugetRepo
}

Function Get-DesiredAppConfigs($envGlobalConfig) {
    $appEnvConfigs = $envGlobalConfig.apps
    if (-not $appEnvConfigs) {
        throw "appEnvConfigs is not configured properly. "
    }    
    $appEnvConfigs
}

Function Import-VersionSpec($versionSpec) {
    if($versionSpec -and (Test-Path $versionSpec)) {
        $versionConfig = Import-Config $versionSpec
        Write-Host "Version spec is found:" 
        $versionConfig.GetEnumerator() | Sort-Object -Property Name | Out-Host
    }
    $versionConfig
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

Function Deploy-App ($envConfig, $versionConfig, $nugetRepo, $nodeDeployRoot, $packageConfigFolder) {
    $server = $envConfig.server
    $package = $envConfig.package
    $version = Get-DesiredPackageVersion $package $envConfig $versionConfig
    $features = Get-DesiredPackageFeatures $envConfig
    $configFileName = Get-DesiredPackageConfigFile $envConfig

    $packageConfig = Import-PackageConfig $packageConfigFolder $configFileName
    $appliedConfigsDir = "$packageConfigFolder\..\applied-app-configs"
    $finalPackageConfigFile = "$appliedConfigsDir\$configFileName.ini"

    $resolvedPackageConfig = Get-ResolvedPackageConfig $packageConfig
    
    $deployAppResultDir = Run-RemoteScript $server {
        param($nodeDeployRoot, $version, $package, $nugetRepo, $resolvedPackageConfig, $features)
        $destAppPath = "$nodeDeployRoot\$package" 
        $nudeployModule = Get-ChildItem "$nodeDeployRoot\tools" "nudeploy.psm1" -Recurse
        Import-Module $nudeployModule.FullName -Force
        Install-NuDeployPackage -packageId $package -version $version `
            -source $nugetRepo -workingDir $destAppPath -co $resolvedPackageConfig -features $features
    } -ArgumentList $nodeDeployRoot, $version, $package, $nugetRepo, $resolvedPackageConfig, $features

    Write-Host "Package [$package] has been deployed to node [$server] succesfully.`n" -f cyan
    
    if($deployAppResultDir -match ".*$package\.(\d.*)") {
        $deployAppResultVersion = $matches[1]
    }
    return $deployAppResultVersion
}

Function Get-DesiredPackageVersion($package, $envConfig, $versionConfig) {
    $version = $envConfig.version
    if ((-not $version) -and $versionConfig -and ($versionConfig[$package])){
        $version = $versionConfig[$package]
    }
    if ($version) {
        Write-Host "Deploying package [$package] with version [$version] to node [$server]...." -f cyan
    }else{
        Write-Host "Deploying package [$package] with version [LATEST] to node [$server]...." -f cyan
    }
    $version
}

Function Get-DesiredPackageFeatures($envConfig) {
    $features = $envConfig.features 
    if(-not $features) {
        $features = @()
    }
    $features
}

Function Get-DesiredPackageConfigFile($envConfig) {
    $configFileName = $envConfig.config
    if(-not $configFileName){
        $configFileName = $envConfig.package
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