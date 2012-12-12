Function Install-NuDeployEnv{
    param(
       [Parameter(Mandatory=$true, Position=0)][string] $envPath,
       [string] $versionSpec,
       [string] $nugetRepoSource
    )

    $envGlobalConfig = Get-DesiredEnvConfig $envPath
    $nodeDeployRoot = Get-DesiredNodeDeploymentRoot $envGlobalConfig
    $nugetRepo = Get-DesiredNugetRepo $envGlobalConfig $nugetRepoSource
    $appEnvConfigs = Get-DesiredAppConfigs $envGlobalConfig
    $versionConfig = Import-VersionSpec $versionSpec

    $targetNodes = $appEnvConfigs | % { $_.server } | Get-Unique
    Add-HostAsTrusted $targetNodes
    $targetNodes | % { Prepare-Node $_ $nugetRepo $nodeDeployRoot}
    $appEnvConfigs | % { Deploy-App $_ $versionConfig $nugetRepo $nodeDeployRoot $envPath }
}

Function Get-DesiredEnvConfig($envPath) {
    if (-not (Test-Path "$envPath\env.config.ps1")) {
        throw "Please make sure 'env.config.ps1' exists under $envPath"
    }
    Write-Host "Using environment definition at [$envPath]..." -f cyan
    & "$envPath\env.config.ps1"
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

Function Prepare-Node($server, $nugetRepo, $nodeDeployRoot){
    Write-Host "Preparing to deploy on node [$server]...." -f cyan

    Run-RemoteScript $server {
        param($nodeDeployRoot)
        Remove-Item $nodeDeployRoot -r -Force -ErrorAction silentlycontinue
        New-Item $nodeDeployRoot -type directory -ErrorAction silentlycontinue
        New-Item "$nodeDeployRoot\tools" -type directory -ErrorAction silentlycontinue
        New-Item "$nodeDeployRoot\nupkgs" -type directory -ErrorAction silentlycontinue
    } -argumentList $nodeDeployRoot | out-null

    $nuget = "$PSScriptRoot\tools\nuget\nuget.exe"
    Copy-FileRemote $server "$nuget" "$nodeDeployRoot\tools\nuget.exe" | out-null

    $nuDeployPackageId = 'NScaffold.NuDeploy'
    $nuDeploySource = Prepre-NudeploySource $nugetRepo

    Run-RemoteScript $server {
        param($nodeDeployRoot, $nuDeployPackageId, $nuDeploySource)
        Push-Location
        Set-Location "$nodeDeployRoot\tools"
        & ".\nuget.exe" install $nuDeployPackageId -source $nuDeploySource
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

Function Deploy-App ($envConfig, $versionConfig, $nugetRepo, $nodeDeployRoot, $envPath) {
    $server = $envConfig.server
    $package = $envConfig.package
    $version = Get-DesiredPackageVersion $package $envConfig $versionConfig
    $features = Get-DesiredPackageFeatures $envConfig
    $configFileName = Get-DesiredPackageConfigFileName $envConfig

    $packageConfig = Import-PackageConfig $envPath $configFileName
    $finalPackageConfigFile = "$envPath\applied-app-configs\$configFileName.ini"
    Build-FinalPackageConfigFile $packageConfig $envGlobalConfig.variables $finalPackageConfigFile
    $remoteConfigFile = "$nodeDeployRoot\$configFileName.ini"
    Copy-FileRemote $server $finalPackageConfigFile $remoteConfigFile | out-null

    Run-RemoteScript $server {
        param($nodeDeployRoot, $version, $package, $nugetRepo, $remoteConfigFile, $features)
        $destAppPath = "$nodeDeployRoot\$package" 
        $nudeployModule = Get-ChildItem "$nodeDeployRoot\tools" "nudeploy.psm1" -Recurse
        Import-Module $nudeployModule.FullName -Force
        Install-NuDeployPackage -packageId $package -version $version -source $nugetRepo -workingDir $destAppPath -config $remoteConfigFile -features $features        
    } -ArgumentList $nodeDeployRoot, $version, $package, $nugetRepo, $remoteConfigFile, $features

    Write-Host "Package [$package] has been deployed to node [$server] succesfully.`n" -f cyan
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

Function Get-DesiredPackageConfigFileName($envConfig) {
    $configFileName = $envConfig.config
    if(-not $configFileName){
        $configFileName = $envConfig.package
    }
    $configFileName
}

Function Import-PackageConfig($envPath, $configFileName) {
    $configFullPath = "$envPath\app-configs\$configFileName.ini"
    if (-not (Test-Path $configFullPath)) {
        throw "Config file [$configFullPath] does not exist. "
    }
    Import-Config $configFullPath    
}

Function Build-FinalPackageConfigFile($packageConfig, $envVariables, $fileName) {
    if($envVariables){
        $packageConfig = Merge-HashTable $packageConfig $envVariables
    }
    $packageConfig = Resolve-Variables $packageConfig
    New-Item -Type File $fileName -Force
    $packageConfig.GetEnumerator() | % { "$($_.key) = $($_.value)" } | Set-Content $fileName
}