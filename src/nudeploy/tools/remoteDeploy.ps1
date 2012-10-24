param(
	[string]
	$env="local",
	[Parameter(Mandatory=$true)]
	[string]
	$nugetRepo, 
	$versionSpec,
	$configRootPath = "$(Get-Location)\config", 
	$nodeDeployRoot = "C:\deployment"
)

trap{
	write-host "Error found: $_" -f red
	exit 1
}

$rootPath = $MyInvocation.MyCommand.Path | Split-Path -parent

<#
config
	$env
		env.config.ps1
		app-configs
			package1-config.ini
			package2-config.ini
#>

$envPath = "$configRootPath\$env"

Write-Host "Using environment definition at [$envPath] for env[$env]...`n" -f cyan
. "$envPath\env.config.ps1"

if (-not $appEnvConfigs) {
    throw "appEnvConfigs is not configed properly. "
}
$appEnvConfigs | Out-String | Write-Debug

$appConfigRootPath = "$envPath\app-configs"

if($versionSpec -and (Test-Path $versionSpec)) {
	$versionConfig = Import-Config $versionSpec
	Write-Host "Version spec is found:"	
	$versionConfig.GetEnumerator() | Sort-Object -Property Name | Out-Host
}

Function Run-RemoteDeploy {
	$targetNodes = $appEnvConfigs | % { $_.server } | Get-Unique
	Prepare-PSRemoting $targetNodes
	$targetNodes | % { Pre-Deploy $_ }
	$appEnvConfigs | % {	
	   	Deploy-App $_ $versionConfig
	}
}

Function Prepare-PSRemoting($trustedHosts) {
	winrm set winrm/config/client "@{TrustedHosts=`"$($trustedHosts -join ",")`"}" | Out-Null
}

Function Run-RemoteCommand($server, $command) {
	if($server -eq "localhost") {
		Save-Location {
			Invoke-Command -scriptblock {param($command) iex $command} -ArgumentList $command
		}
	}
	else {
		Invoke-Command -ComputerName $server -scriptblock {
			param($command) 
			iex $command
		} -ArgumentList $command
	}
}

Function Run-RemoteScript($server, [ScriptBlock]$scriptblock, $argumentList) {
	if($server -eq "localhost") {
		Save-Location {
			Invoke-Command -scriptblock $scriptblock -ArgumentList $argumentList
		}
	}
	else {
		Invoke-Command -ComputerName $server -scriptblock $scriptblock -ArgumentList $argumentList
	}
}

Function Run-CopyFileRemote($server, $sourceFile, $destFile) {
	[byte[]]$content = Get-Content $sourceFile -Encoding byte
	invoke-command -computername $server -scriptblock {
		param($path, $content) Set-Content $path $content -Encoding byte
	} -ArgumentList $destFile, $content
}

Function Pre-Deploy($server){
	Write-Host "Preparing to deploy on node [$server]...." -f cyan

	Run-RemoteScript $server {
		param($nodeDeployRoot)
		Remove-Item $nodeDeployRoot -r -Force -ErrorAction silentlycontinue
		New-Item $nodeDeployRoot -type directory -ErrorAction silentlycontinue
		New-Item $nodeDeployRoot\tools -type directory -ErrorAction silentlycontinue
	} -argumentList $nodeDeployRoot | out-null

	$nupkg = (Get-Item "$rootPath\..\*.nupkg").FullName
	Run-CopyFileRemote $server $nupkg "$nodeDeployRoot\tools\$nupkg" | out-null
	Run-CopyFileRemote $server "$rootPath\tools\nuget\nuget.exe" "$nodeDeployRoot\tools\nuget.exe" | out-null

	Run-RemoteScript $server {
		param($nodeDeployRoot)
		Push-Location
		Set-Location "$nodeDeployRoot\tools"
		& "nuget.exe" install "NScaffold.NuDeploy" -source "$nodeDeployRoot\tools\"
	    $nudeployModule = Get-ChildItem "$nodeDeployRoot\tools" "nudeploy.psm1" -Recurse
    	Import-Module $nudeployModule.FullName -Force
		Pop-Location
	} -argumentList $nodeDeployRoot | out-null
	Write-Host "Node [$server] is now ready for deployment.`n" -f cyan
}

Function Deploy-App ($envConfig, $versionConfig) {
	$package    = $envConfig.package
	$server     = $envConfig.server
	$version    = $envConfig.version
	$appConfig = $envConfig.config

	if($envConfig.features) {
		$features 	= $envConfig.features	
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

	if($appConfig){
		$configFileName = $appConfig
	} else {
		$configFileName = $package
	}

	Run-CopyFileRemote $server "$appConfigRootPath\$configFileName.ini" "$nodeDeployRoot\$configFileName.ini" | out-null

	Run-RemoteScript $server {
		param($nodeDeployRoot, $version, $package, $nugetRepo, $remoteConfigFile, $features)
		$destAppPath = "$nodeDeployRoot\$package" 
		& "nudeploy" -packageId $package -version $version -source $nugetRepo -workingDir $destAppPath -config $remoteConfigFile -features $features		
	} -ArgumentList $nodeDeployRoot, $version, $package, $nugetRepo, "$nodeDeployRoot\$configFileName.ini", $features

	Write-Host "Package [$package] has been deployed to node [$server] succesfully.`n" -f cyan
}

Run-RemoteDeploy

