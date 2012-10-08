# this file should not be changed, will be replaced after upgrade
# use go.ext.ps1 to extend
param(
    $target, 
    $env="dev"
)

trap{
    write-host "Error found: $_" -f red
    exit 1
}
$error.clear()

$codeBaseRoot = $MyInvocation.MyCommand.Path | Split-Path -parent
$scriptRoot = "$codeBaseRoot\build\scripts"
if(!$libsRoot){
  $libsRoot = "$scriptRoot\libs"
}

if(!$toolsRoot){
    $toolsRoot = "$codeBaseRoot\build\tools"
}

$env:EnableNuGetPackageRestore = "true"

Resolve-Path "$libsRoot\*.ps1" | 
    ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
    % { . $_.ProviderPath }

. PSRequire "$libsRoot\functions\"

# register ps-get packages
PS-Get "psake" "4.2.0.1" | % {
    $psakeModule = get-childitem $_ psake.psm1 -recurse
    Import-Module $psakeModule.FullName -Force
    $psake.use_exit_on_error = $true
}

PS-Get "yam" -postInstall {
    param($pkgDir)
    . "$pkgDir\install.ps1" $codeBaseRoot
}

Import-Module WebAdministration -Force

$buildParmeters = @{ 
    "codeBaseRoot" = "$codeBaseRoot"
    "libsRoot" = "$libsRoot"
    "toolsRoot" = "$toolsRoot"
}

. $codeBaseRoot\build\environment\$env.ps1
$mergedParams = Merge-Hashtable $buildParmeters $envParameters

. Register-Extension $MyInvocation.MyCommand.Path
Invoke-Psake $scriptRoot\build.ns.ps1 $target -Framework "4.0x64" -parameters $mergedParams

if(!$psake.build_success) {
    write-host "============================= Environment: $env ==============================" -f yellow
    $mergedParams | format-table | Out-String | write-host -f yellow
    throw "Failed to execute Task $target."
}

Exit 0
