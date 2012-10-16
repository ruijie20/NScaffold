param($config, $packageInfo, [ScriptBlock] $installAction)

$webSiteName = $config.siteName
$webSitePath = "IIS:\Sites\$webSiteName"
$tempDir = "$($env:temp)\$((Get-Date).Ticks)"
New-Item $tempDir -type Directory | Out-Null

if (-not $config.Port) {
    throw "In order to create new website, please specify the port first!"
}
if(Test-Path $webSitePath) {
    Remove-Website $webSiteName
}
Reset-AppPool $config.appPoolName $config.appPoolUser $config.appPoolPassword
New-Website -Name $webSiteName -Port $config.Port -ApplicationPool $config.appPoolName -PhysicalPath $tempDir | Out-Null

& $installAction

Remove-Item $tempDir -Force -Recurse -ErrorAction SilentlyContinue | Out-Null