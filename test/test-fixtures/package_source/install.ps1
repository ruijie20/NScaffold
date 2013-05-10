param(
    [string] $configFile, 
    [string[]] $features = @("default")
)
$packageRoot = $MyInvocation.MyCommand.Path | Split-Path -parent

if (-not $configFile) {
    $configFile = "$packageRoot\config.ini"
}
$deploymentConfig = "$packageRoot\deployment.config.ini"
New-Item -Type File $deploymentConfig -Force | Out-Null
(Get-Content $configFile) | Set-Content $deploymentConfig

$fixturesSpy = "$packageRoot\features.txt"
New-Item -Type File $fixturesSpy -Force | Out-Null
$features | Set-Content $fixturesSpy

$configFileSpy = "$packageRoot\config.txt"
Copy-Item $configFile $configFileSpy

Set-Content "$packageRoot\fileGeneratedByInstall.txt" "fileGeneratedByInstall"