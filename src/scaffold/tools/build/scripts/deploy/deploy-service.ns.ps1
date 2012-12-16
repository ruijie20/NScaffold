# this script should be invoked under the root directory of the package. 
param([Parameter(Position = 0, Mandatory = $true, ParameterSetName = "configFile")]
    [string]$configFile, 
    [Parameter(Position = 0, Mandatory = $true, ParameterSetName = "configObject")]
    [hashtable]$configObject, 
    [string]$executablePath, 
    [string]$packageRoot = (Get-Location).ProviderPath, 
    $features=@(), 
    [ScriptBlock] $applyConfig)

trap {
    throw $_
}

$root = $MyInvocation.MyCommand.Path | Split-Path -Parent
$folderName = ($MyInvocation.MyCommand.Path | Split-Path -Leaf).TrimEnd(".ns.ps1")
$featuresFolder = "$root\$folderName"
$appConfigFile = Get-ChildItem $packageRoot -Recurse -Filter "*.config" | select -first 1 
$sourcePath = Split-Path $appConfigFile.FullName -Parent

# include libs
if(-not $libsRoot) {
    $libsRoot = "$root\libs"
}
Get-ChildItem $libsRoot -Filter *.ps1 -Recurse | 
    ? { -not ($_.Name.Contains(".Tests.")) } | % {
        . $_.FullName
    }

. PS-Require "$root\functions"

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

if($applyConfig){
    & $applyConfig $config $sourcePath $packageInfo
}

$installAction = {
    param($sourcePath, $config, $executablePath)
    $name = $config.ServiceName
    $installPath = $config.ServicePath

    Function Test-ServiceExisted($name) {
        (Get-Service | Where-Object {$_.Name -eq $name} | Measure-Object).Count -eq 1
    }

    while(Test-ServiceStatus $name "Running"){
        Write-Host "Service[$name] is running. Start stop it." 
        Stop-Service $name
        SLEEP -second 2
    }
    if (Test-Path $installPath) {
        Remove-Item $installPath    
    }

    Write-Host "start copy $sourcePath to $installPath" -f green
    Copy-Item $sourcePath $installPath -Recurse

    if(-not(Test-ServiceExisted $name)){
        Write-Host "Create Service[$name] for $installPath\$executablePath"             
        New-Service -Name $name -BinaryPathName "$installPath\$executablePath" -Description $name -DisplayName $name -StartupType Automatic
    }else{
        Write-Host "Service[$name] already exists" -f green
    }

    Start-Service -Name $name

    if(-not (Test-ServiceStatus $name "Running")){
        throw "Service[$name] is NOT running after installation."
    }
}

$installClosure = Make-Closure $installAction $sourcePath, $config, $executablePath
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
