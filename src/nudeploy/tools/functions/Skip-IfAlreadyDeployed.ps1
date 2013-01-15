Function Skip-IfAlreadyDeployed ($root, $appConfig, $force, $scriptBlockToDeploy){    
    Write-Host "Start deploying $(Convert-AppConfigToString $appConfig)" -f cyan
    if((-not $force) -and (Test-AlreadyDeployed $root $appConfig)){
        Write-Host "$(Convert-AppConfigToString $appConfig) has ALREADY been deployed. Skip deployment." -f cyan
    }else{
        (& $scriptBlockToDeploy)
        Register-SuccessDeployment $root $appConfig
        Write-Host "Succesfully deployed $(Convert-AppConfigToString $appConfig)." -f cyan
    }
}

Function Register-SuccessDeployment($root, $appConfig){
	New-Item -itemtype directory $root -Force

	Remove-PreviousDeployment $root $appConfig.env $appConfig.server $appConfig.package

	$fileName = Get-DeploymentHistoryFileName $appConfig.env $appConfig.server $appConfig.package $appConfig.version
	$lastDeploymentConfig = "$root\$fileName"
	Copy-Item -Path $appConfig.config -Destination $lastDeploymentConfig
}

Function Test-AlreadyDeployed($root, $appConfig){
	$fileName = Get-DeploymentHistoryFileName $appConfig.env $appConfig.server $appConfig.package $appConfig.version
	$lastDeploymentConfig = "$root\$fileName"
	(Test-Path $lastDeploymentConfig) -and (Test-ConfigFileEqual $lastDeploymentConfig $appConfig.config)
}

Function Convert-AppConfigToString($appConfig){
	"package [$($appConfig.package)] version [$($appConfig.version)] on node [$($appConfig.server)] with config [$($appConfig.config)] of environment[$($appConfig.env)]"
}

Function Remove-PreviousDeployment($root, $env, $server, $app){
	$fileNamePattern = Get-DeploymentHistoryFileName $env $server $app '*'
	Get-ChildItem $root|%{ $_.name }|?{ $_ -like $fileNamePattern } | % { Remove-Item $root\$_ -Force }
}

Function Get-DeploymentHistoryFileName($env, $server, $app, $version){
	$fileName = @($env, $server, $app, $version) -join '_'
	"$fileName.ini"
}

Function Test-ConfigFileEqual($file1, $file2){
	$config1 = Import-Config $file1
	$config2 = Import-Config $file2
	if($config1.Count -eq $config2.Count){
		$configDiff = $config1.keys|? { -not ($config1[$_] -eq $config2[$_])}
		-not $configDiff
	}else{
		$false
	}
}

Function Import-Config($configFilePath) {
	$configFilePath = Resolve-Path $configFilePath
	$config = @{}
	$csv = import-csv $configFilePath -Delimiter '=' -header 'key','value'
	$csv | ? {$_.key} | % {
		$config[$_.key.trim()] = $_.value.trim()
	}
	$config
}
