param(
	[string] $config_path
)

$packageRoot = $MyInvocation.MyCommand.Path | Split-Path -parent
$deploymentConfig = "$packageRoot\deployment.config.ini"
New-Item -Type File $deploymentConfig -Force
(Get-Content $config_path) | Set-Content $deploymentConfig

