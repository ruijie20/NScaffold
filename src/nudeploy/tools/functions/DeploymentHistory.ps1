
Function Convert-AppConfigToString {
    "package [$($appConfig.package)] version [$($appConfig.version)] on node [$($appConfig.server)] with config [$($appConfig.config)] of environment[$($appConfig.env)]"
}
Function Get-DeploymentHistoryFilePrefix($appConfig){
	@($appConfig.env, $appConfig.server, $appConfig.package, $appConfig.version) -join '_'
}
Function Get-DeploymentHistoryConfigFilePath($appConfig){
	$prefix = Get-DeploymentHistoryFilePrefix $appConfig
    "$historyRoot\$prefix.ini"
}
Function Get-DeploymentHistoryResultFilePath($appConfig){
	$prefix = Get-DeploymentHistoryFilePrefix $appConfig
    "$historyRoot\$($prefix)_deployResult.xml"
}
Function Clear-AllDeploymentHistory($historyRoot){
	if(Test-Path $historyRoot){
		remove-item $historyRoot -recurse
	}
}
Function Test-LastDeploymentMatch($lastDeploymentConfig, $appConfig) {
    (Test-Path $lastDeploymentConfig) -and (Test-ConfigFileEqual $lastDeploymentConfig $appConfig.config)
}
Function Remove-PreviousDeployment($historyRoot, $appConfig){
    $fileNamePattern = @($appConfig.env, $appConfig.server, $appConfig.package, '*') -join '_'
    Get-ChildItem $historyRoot | %{ $_.name } | ? { $_ -like $fileNamePattern } | % { Remove-Item $historyRoot\$_ -Force }
}


Function Save-LastDeploymentResult($historyRoot, $appConfig, $deployResult){
    Write-Host "Saving DeploymentHistory for $(Convert-AppConfigToString $appConfig)" -f cyan
    New-Item -itemtype directory $historyRoot -Force | Out-Null

    $lastDeploymentConfig = Get-DeploymentHistoryConfigFilePath $appConfig
    $lastDeploymentResult = Get-DeploymentHistoryResultFilePath $appConfig

    Remove-PreviousDeployment $historyRoot $appConfig
    Copy-Item -Path $appConfig.config -Destination $lastDeploymentConfig
    try {
    	write-host "export $lastDeploymentResult"
        Export-Clixml $lastDeploymentResult -InputObject $deployResult    
    } catch {
        Write-Warning $_
    }
}
Function Load-LastMatchingDeploymentResult($historyRoot, $appConfig){
    $lastDeploymentConfig = Get-DeploymentHistoryConfigFilePath $appConfig
    $lastDeploymentResult = Get-DeploymentHistoryResultFilePath $appConfig

    if(Test-LastDeploymentMatch $lastDeploymentConfig $appConfig){
    	if(Test-Path $lastDeploymentResult){
	    	$lastDeploymentResult = Import-Clixml $lastDeploymentResult
	    }
	    if(-not $lastDeploymentResult){
	    	@{result = "dummy deployment result"}
	    }
	    $lastDeploymentResult
	}
}