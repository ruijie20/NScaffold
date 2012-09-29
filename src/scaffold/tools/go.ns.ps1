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

$root = $MyInvocation.MyCommand.Path | Split-Path -parent
$scriptRoot = "$root\build\scripts"
if(!$libsRoot){
  $libsRoot = "$scriptRoot\libs"
}

if(!$toolsRoot){
    $toolsRoot = "$root\build\tools"
}

$env:EnableNuGetPackageRestore = "true"

Resolve-Path "$libsRoot\*.ps1" | 
    ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
    % { . $_.ProviderPath }

. PSRequire "$libsRoot\functions\"

# register ps-get packages
PS-Get "psake" "4.2.0.1" {
    param($pkgDir)        
    $psakeModule = get-childitem $pkgDir psake.psm1 -recurse
    Import-Module $psakeModule.FullName -Force
    $psake.use_exit_on_error = $true
}


Import-Module WebAdministration -Force

$buildParmeters = @{ 
    "codeBaseRoot" = "$root"
}

. $root\build\environment\$env.ps1
$mergedParams = Merge-Hashtable $buildParmeters $envParameters

. Register-Extension $MyInvocation.MyCommand.Path
Invoke-Psake $scriptRoot\build.ns.ps1 $target -Framework "4.0x64" -parameters $mergedParams

if(!$psake.build_success) {
    write-host "============================= Environment: $env ==============================" -f yellow
    $mergedParams | format-table | Out-String | write-host -f yellow
    throw "Failed to execute Task $target."
}