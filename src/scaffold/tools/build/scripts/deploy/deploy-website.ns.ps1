# this script should be invoked under the root directory of the package. 
# the responsibility of install.ps1 is to provide $applyConfig, 
# $env.ps1 need define function Install-Website to take the installAction
param($env="dev", $sourcePath="WebSite", $configFile, [ScriptBlock] $applyConfig)
$packageRoot = (Get-Location).ProviderPath
$sourcePath = Join-Path $packageRoot $sourcePath
$root = $MyInvocation.MyCommand.Path | Split-Path -Parent
$folderName = ($MyInvocation.MyCommand.Path | Split-Path -Leaf).TrimEnd(".ns.ps1")

# include libs
Get-ChildItem "$root\libs" -Filter *.ps1 -Recurse | 
    ? { -not ($_.Name.Contains(".Tests.")) } | % {
        . $_.FullName
    }
. PS-Require "$root\functions"

if([IntPtr]::size -ne 8){
    throw "'WebAdministration' module can only run in 64 bit powershell"
}

$packageInfo = Get-PackageInfo $packageRoot
# get config
$config = Import-Config $configFile | 
    Patch-Config -p (Import-Config ".\config.ini") |
    Patch-Config -p (Generate-Config $packageRoot $packageInfo.packageId)

# import WebAdministration module
Get-Module -ListAvailable -Name "WebAdministration" | % {
    if(-not(Test-ServiceStatus "W3SVC")) {
        Set-Service -Name WAS -Status Running -StartupType Automatic
        Set-Service -Name W3SVC -Status Running -StartupType Automatic
    }    
    Import-Module WebAdministration
}

if($applyConfig){
    & $applyConfig $config
}

. "$folderName\$env.ps1" $config.siteName $packageInfo {
    param([switch]$force)

    $webSiteName = $config.siteName
    $webSitePath = "IIS:\Sites\$webSiteName"
    $physicalPath = $config.physicalPath

    $tempDir = "$($env:temp)\$((Get-Date).Ticks)"
    New-Item $tempDir -type Directory | Out-Null
    if ($force) {
        # rebuild website
        if (-not $config.Port) {
            throw "In order to create new website, please specify the port first!"
        }
        Remove-Website $webSiteName
        Reset-AppPool $config.appPoolName $config.appPoolUser $config.appPoolPassword
        New-Website -Name $webSiteName -Port $config.Port -ApplicationPool $config.appPoolName -PhysicalPath $tempDir | Out-Null
    } else{
        # check website
        if(-not (Test-Path $webSitePath)) {
            throw "Website [$webSitePath] does not exists!"
        }
        Set-ItemProperty $webSitePath physicalPath $tempDir
    }

    Write-Debug "Website [$webSiteName] is ready."
    SLEEP -second 2

    if($sourcePath -ne $physicalPath){
        Clear-Directory $physicalPath
        Copy-Item $sourcePath -destination $physicalPath -recurse
    }    
    Set-ItemProperty $webSitePath physicalPath $physicalPath
    Start-Website $webSiteName
    SLEEP -second 2
    Remove-Item $tempDir -force -recurse -ErrorAction SilentlyContinue | Out-Null
}
