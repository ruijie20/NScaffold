param(
    [string] $configFile, 
    [string[]] $features
)

$packageRoot = $MyInvocation.MyCommand.Path | Split-Path -parent
if(-not $libsRoot) {
    $libsRoot = "$packageRoot\tools\libs"
}
Get-ChildItem $libsRoot -Filter *.ps1 -Recurse | 
    ? { -not ($_.Name.Contains(".Tests.")) } | % {
        . $_.FullName
    }    
. PS-Require "$packageRoot\tools\functions"


if (-not $configFile) {
    $configFile = "$packageRoot\config.ini"
}

$packageConfig = & "$packageRoot\tools\packageConfig.ps1" $packageRoot
if ($features -eq $null) {
    $features = $packageConfig.defaultFeatures
}

if (-not $packageConfig.type) {
    throw "If you want to use deployment plugin to install, please at least specify which plugin to use [type] in package config file. " 
}

Push-Location
Set-Location $packageRoot
try {
    & .\tools\deploy.ns.ps1 $configFile -type $packageConfig.type -features $features -installArgs $packageConfig.installArgs `
         -applyConfig $packageConfig.applyConfig
} finally {
    Pop-Location    
}
