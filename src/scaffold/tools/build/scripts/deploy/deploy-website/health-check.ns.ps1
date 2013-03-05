param($config, $packageInfo, $installArgs, [ScriptBlock] $installAction)

$here = $MyInvocation.MyCommand.Path | Split-Path -Parent
. $here\health-check.fn.ns.ps1

& $installAction

if(-not (Test-WebsiteMatch $config $packageInfo)){
    throw "Site [$($config.siteName)] doesn't match package [$($packageInfo.packageId) $($packageInfo.version)]"
}
