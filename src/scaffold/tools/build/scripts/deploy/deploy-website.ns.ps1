# this script should be invoked under the root directory of the package. 
param([Parameter(Position = 0, Mandatory = $true, ParameterSetName = "configFile")]
    [string]$configFile, 
    [Parameter(Position = 0, Mandatory = $true, ParameterSetName = "configObject")]
    [hashtable]$configObject, 
    [string]$packageRoot = (Get-Location).ProviderPath, 
    $features=@(), 
    [ScriptBlock] $applyConfig)

trap {
    throw $_
}


$root = $MyInvocation.MyCommand.Path | Split-Path -Parent
$folderName = ($MyInvocation.MyCommand.Path | Split-Path -Leaf).TrimEnd(".ns.ps1")
$featuresFolder = "$root\$folderName"
$webConfigFile = Get-ChildItem $packageRoot -Recurse -Filter "web.config" | select -first 1 
$sourcePath = Split-Path $webConfigFile.FullName -Parent

# include libs
if(-not $libsRoot) {
    $libsRoot = "$root\libs"
}
Get-ChildItem $libsRoot -Filter *.ps1 -Recurse | 
    ? { -not ($_.Name.Contains(".Tests.")) } | % {
        . $_.FullName
    }

. PS-Require "$root\functions"

if([IntPtr]::size -ne 8){
    throw "'WebAdministration' module can only run in 64 bit powershell"
}

$packageInfo = Get-PackageInfo $packageRoot

# get config
if($PsCmdlet.ParameterSetName -eq 'configFile') {
    $config = Import-Config $configFile | 
        Patch-Config -p (Generate-Config $sourcePath $packageInfo.packageId)
} elseif ($PsCmdlet.ParameterSetName -eq 'configObject') {
    $config = $configObject | 
        Patch-Config -p (Generate-Config $sourcePath $packageInfo.packageId)
} else {
    $config = Generate-Config $sourcePath $packageInfo.packageId
}

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
        Copy-Item "$sourcePath\*" -Destination $physicalPath -Recurse
    }    
    Set-ItemProperty $webSitePath physicalPath $physicalPath
    Start-Website $webSiteName
    SLEEP -second 2
    Remove-Item $tempDir -Force -Recurse -ErrorAction SilentlyContinue | Out-Null
}

$installClosure = Make-Closure $installAction

foreach ($feature in $features){
    if(Test-Path "$featuresFolder\$feature.ps1"){
        $featureScript = "$featuresFolder\$feature.ps1"
    } elseif(Test-Path "$featuresFolder\$feature.ns.ps1") {
        $featureScript = "$featuresFolder\$feature.ns.ps1"
    }
    if($featureScript){
        $installClosure = Make-Closure { 
            param($scriptFile, $c)
            & "$scriptFile" $config $packageInfo {Run-Closure $c}
        } "$featureScript", $installClosure
    }
}

Run-Closure $installClosure
