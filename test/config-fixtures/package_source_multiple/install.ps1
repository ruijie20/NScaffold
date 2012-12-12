param(
    [string] $configFile, 
    [string[]] $features = @("default")
)
$packageRoot = $MyInvocation.MyCommand.Path | Split-Path -parent

if (-not $configFile) {
    $configFile = "$packageRoot\config.ini"
}

$deploymentConfig = "$packageRoot\deployment.config.ini"
New-Item -Type File $deploymentConfig -Force
(Get-Content $configFile) | Set-Content $deploymentConfig

$fixturesSpy = "$packageRoot\features.txt"
New-Item -Type File $fixturesSpy -Force
$features | Set-Content $fixturesSpy

