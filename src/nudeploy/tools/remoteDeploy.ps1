param(
	[Parameter(Mandatory=$true,  Position = 1)]
	[string]
	$env,
	[Parameter(Mandatory=$true, Position = 2, ParameterSetName = "deploy")]
	[string]
	$nugetRepo, 
	[Parameter(Mandatory=$true, Position = 2, ParameterSetName = "scaffold")]
	[switch]
	$scaffold,
	$versionSpec,
	$configRootPath = "$(Get-Location)\config", 
	$nodeDeployRoot = "C:\deployment"

)
trap{
	$_ | Out-String | Write-Host -f red
	exit 1
}

$rootPath = $MyInvocation.MyCommand.Path | Split-Path -parent
Get-ChildItem "$rootPath\functions" -Filter *.ps1 -Recurse | 
    ? { -not ($_.Name.Contains(".Tests.")) } | % {
        . $_.FullName
    }

$envPath = "$configRootPath\$env"

if($PsCmdlet.ParameterSetName -eq 'scaffold' -and $scaffold) {
	New-EnvironmentConfig $envPath	
	Exit 0
}


if (-not (Test-Path "$envPath\env.config.ps1")) {
    throw "Please make sure 'env.config.ps1' exists under $envPath"
}

Write-Host "Using environment definition at [$envPath] for env[$env]..." -f cyan
. "$envPath\env.config.ps1"

if (-not $appEnvConfigs) {
    throw "appEnvConfigs is not configed properly. "
}
$appEnvConfigs | Out-String | Write-Debug

if($versionSpec -and (Test-Path $versionSpec)) {
	$versionConfig = Import-Config $versionSpec
	Write-Host "Version spec is found:"	
	$versionConfig.GetEnumerator() | Sort-Object -Property Name | Out-Host
}

# check whether nudeploy is in repo
$nudeployPackageId = 'NScaffold.NuDeploy'
$nuget = "$rootPath\tools\nuget\nuget.exe"
$isNudeployInRepo = [boolean](& $nuget list $nudeployPackageId -source $nugetRepo | ? { 
	$_ -match "^$nudeployPackageId (?<version>(?:\d+\.)*\d+(?:-(?:\w|-)*)?)" })

Function Prepare-Node($server){
	Write-Host "Preparing to deploy on node [$server]...." -f cyan

	Run-RemoteScript $server {
		param($nodeDeployRoot)
		Remove-Item $nodeDeployRoot -r -Force -ErrorAction silentlycontinue
		New-Item $nodeDeployRoot -type directory -ErrorAction silentlycontinue
		New-Item $nodeDeployRoot\tools -type directory -ErrorAction silentlycontinue
	} -argumentList $nodeDeployRoot | out-null

	Copy-FileRemote $server "$nuget" "$nodeDeployRoot\tools\nuget.exe" | out-null

	$nuDeploySource = Prepre-NudeploySource

	Run-RemoteScript $server {
		param($nodeDeployRoot, $nudeployPackageId, $nuDeploySource)
		Push-Location
		Set-Location "$nodeDeployRoot\tools"
		& "nuget.exe" install $nudeployPackageId -source $nuDeploySource
	    $nudeployModule = Get-ChildItem "$nodeDeployRoot\tools" "nudeploy.psm1" -Recurse
    	Import-Module $nudeployModule.FullName -Force
		Pop-Location
	} -argumentList $nodeDeployRoot, $nudeployPackageId, $nuDeploySource | out-null
	Write-Host "Node [$server] is now ready for deployment.`n" -f cyan
}

Function Prepre-NudeploySource {
	if(-not $isNudeployInRepo){
		$nupkg = Get-Item "$rootPath\..\*.nupkg"
		Copy-FileRemote $server $nupkg.FullName "$nodeDeployRoot\tools\$($nupkg.Name)" | out-null
		"$nodeDeployRoot\tools\"
	} else {
		$nugetRepo	
	}
}

Function Deploy-App ($envConfig, $versionConfig) {
	$package    = $envConfig.package
	$server     = $envConfig.server
	$version    = $envConfig.version
	$appConfig = $envConfig.config

	if($envConfig.features) {
		$features = $envConfig.features	
	} else {
		$features = @()
	}
	
	if ((-not $version) -and $versionConfig -and ($versionConfig[$package])){
		$version = $versionConfig[$package]
	}
	if ($version) {
		Write-Host "Deploying package [$package] with version [$version] to node [$server]...." -f cyan
	}else{
		Write-Host "Deploying package [$package] with version [LATEST] to node [$server]...." -f cyan
	}

	$appConfigRootPath = "$envPath\app-configs"
	if($appConfig){
		$configFileName = $appConfig
	} else {
		$configFileName = $package
	}

	$configFullPath = "$appConfigRootPath\$configFileName.ini"
	if (-not (Test-Path $configFullPath)) {
	    throw "Config file [$configFullPath] does not exist. "
	}
	Copy-FileRemote $server "$configFullPath" "$nodeDeployRoot\$configFileName.ini" | out-null

	Run-RemoteScript $server {
		param($nodeDeployRoot, $version, $package, $nugetRepo, $remoteConfigFile, $features)
		$destAppPath = "$nodeDeployRoot\$package" 
		& "nudeploy" -packageId $package -version $version -source $nugetRepo -workingDir $destAppPath -config $remoteConfigFile -features $features		
	} -ArgumentList $nodeDeployRoot, $version, $package, $nugetRepo, "$nodeDeployRoot\$configFileName.ini", $features

	Write-Host "Package [$package] has been deployed to node [$server] succesfully.`n" -f cyan
}

$targetNodes = $appEnvConfigs | % { $_.server } | Get-Unique
& winrm set winrm/config/client "@{TrustedHosts=`"$($targetNodes -join ",")`"}" | Out-Null
$targetNodes | % { Prepare-Node $_ }
$appEnvConfigs | % { Deploy-App $_ $versionConfig }
