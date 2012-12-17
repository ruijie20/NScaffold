# this script should be invoked under the root directory of the package. 
param([Parameter(Position = 0, Mandatory = $true, ParameterSetName = "configFile")]
    [string]$configFile, 
    [Parameter(Position = 0, Mandatory = $true, ParameterSetName = "configObject")]
    [hashtable]$configObject, 
    [string]$type,
    [string]$packageRoot = (Get-Location).ProviderPath, 
    $features=@(),     
    [ScriptBlock] $applyConfig,
    [hashtable]$installArgs)

trap {
    throw $_
}

$root = $MyInvocation.MyCommand.Path | Split-Path -Parent
# include libs
if(-not $libsRoot) {
    $libsRoot = "$root\libs"
}
Get-ChildItem $libsRoot -Filter *.ps1 -Recurse | 
    ? { -not ($_.Name.Contains(".Tests.")) } | % {
        . $_.FullName
    }

. PS-Require "$root\functions"


$featuresFolder = "$root\deploy-$type"
if (-not (Test-Path "$featuresFolder\default.ns.ps1")) {
    throw "Deploy [$type] is not supported. "
}
$defaultFeature = & "$featuresFolder\default.ns.ps1" $packageRoot $installArgs

$packageInfo = $defaultFeature.packageInfo

# get config
if($PsCmdlet.ParameterSetName -eq 'configFile') {
    $config = Import-Config $configFile | 
        Patch-Config -p (Generate-PackageConfig $packageInfo)
} elseif ($PsCmdlet.ParameterSetName -eq 'configObject') {
    $config = $configObject | 
        Patch-Config -p (Generate-PackageConfig $packageInfo)
} else {
    $config = Generate-PackageConfig $packageInfo
}

if($applyConfig){
    & $applyConfig $config $packageInfo
}

$installClosure = Make-Closure $defaultFeature.installAction $config, $packageInfo, $installArgs
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
