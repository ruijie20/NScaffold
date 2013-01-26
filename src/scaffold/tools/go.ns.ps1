# this file should not be changed, will be replaced after upgrade
# use go.ext.ps1 to extend
param(
    $target, 
    [string[]] $packageId= @(),
    $env="dev", 
    [string[]] $features
)

trap{
    write-host "Error found: $_" -f red
    Remove-Module psake -ea 'SilentlyContinue'
    Exit 1
}

$error.clear()
$LASTEXITCODE = 0

$codeBaseRoot = $MyInvocation.MyCommand.Path | Split-Path -parent


$toolsRoot = "$codeBaseRoot\build\tools"
$scriptRoot = "$codeBaseRoot\build\scripts"
$libsRoot = "$scriptRoot\libs"
$buildScriptRoot = "$codeBaseRoot\build\scripts\build"

$env:EnableNuGetPackageRestore = "true"

Get-ChildItem $libsRoot -Filter *.ps1 -Recurse | 
    ? { -not ($_.Name.Contains(".Tests.")) } | % {
        . $_.FullName
    }

$nuget = "$codeBaseRoot\.nuget\nuget.exe"

# register ps-get packages
PS-Get "psake" "4.2.0.1" | % {
    $psakeModule = Get-ChildItem $_ psake.psm1 -recurse
    Import-Module $psakeModule.FullName -Force
    $psake.use_exit_on_error = $true
}

PS-Get "NScaffold.NuDeploy" "0.0.107" | % {
    $nudeployModule = Get-ChildItem $_ nudeploy.psm1 -recurse
    Import-Module $nudeployModule.FullName -Force
}

PS-Get "yam" "0.0.7" -postInstall {
    param($pkgDir)
    . "$pkgDir\install.ps1" $codeBaseRoot
}

$codebaseConfig = & "$codeBaseRoot\codebaseConfig.ps1"
# extra ps-gets
if($codebaseConfig.extraPSGets) {
    $codebaseConfig.extraPSGets | % {
        PS-Get $_.packageId $_.version
    }    
}

$buildParmeters = @{ 
    "env" = "$env"
    "codeBaseRoot" = "$codeBaseRoot"
    "libsRoot" = "$libsRoot"
    "scriptRoot" = $scriptRoot
    "toolsRoot" = "$toolsRoot"
    "nuget" = $nuget
    "environmentsRoot" = "$buildScriptRoot\environments"
    "packageId" = $packageId
    "codebaseConfig" = $codebaseConfig
}

if (-not ($features -eq $null)) {
    $buildParmeters.Add("features", $features)
}

. Register-Extension $MyInvocation.MyCommand.Path


Invoke-Psake $scriptRoot\build\build.ns.ps1 $target -Framework "4.0x64" -parameters $buildParmeters

if(-not $psake.build_success) {
    write-host "============================= Environment: $env ==============================" -f yellow
    $buildParmeters | format-table | Out-String | write-host -f yellow
    throw "Failed to execute Task $target."
}
Remove-Module psake -ea 'SilentlyContinue'
Exit 0