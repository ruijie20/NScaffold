# this script should be invoked under the root directory of the package. 
# the responsibility of install.ps1 is to provide $applyConfig, 
# $env.ps1 need define function Install-Website to take the installAction
param($sourcePath="WebSite", $configFile, $features=@(), [ScriptBlock] $applyConfig)

trap {
    throw $_
}

$packageRoot = (Get-Location).ProviderPath
$sourcePath = Join-Path $packageRoot $sourcePath
$root = $MyInvocation.MyCommand.Path | Split-Path -Parent
$folderName = ($MyInvocation.MyCommand.Path | Split-Path -Leaf).TrimEnd(".ns.ps1")
$featuresFolder = "$root\$folderName"

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
    & $applyConfig $config $sourcePath
}

# $sourcePath and $config is visible to script file due to the parent scope is this file
# so it is also visible to this action due to it's called by those scripts
$installAction = {
    param([switch]$renew)

    $webSiteName = $config.siteName
    $webSitePath = "IIS:\Sites\$webSiteName"
    $physicalPath = $config.physicalPath

    if(-not (Test-Path $webSitePath)) {
        throw "Website [$webSitePath] does not exists!"
    }

    $tempDir = "$($env:temp)\$((Get-Date).Ticks)"
    New-Item $tempDir -type Directory | Out-Null
    Set-ItemProperty $webSitePath physicalPath $tempDir
    Write-Host "Website [$webSiteName] is ready."
    SLEEP -second 2

    if($sourcePath -ne $physicalPath){
        Clear-Directory $physicalPath
        Copy-Item $sourcePath -destination $physicalPath -recurse
    }    
    Set-ItemProperty $webSitePath physicalPath $physicalPath
    Start-Website $webSiteName
    SLEEP -second 2
    Remove-Item $tempDir -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
}

$installClosure = Make-Closure $installAction

foreach ($feature in $features){
    if(Test-Path "$featuresFolder\$feature.ps1"){
        $installClosure = Make-Closure { 
            param($scriptFile, $c)
            & "$scriptFile" $config $packageInfo {Run-Closure $c}
        } "$featuresFolder\$feature.ps1", $installClosure
    }
}

Run-Closure $installClosure
