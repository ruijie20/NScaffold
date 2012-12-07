$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path

. "$rootDir\src-libs\functions\Install-NuPackage.ns.ps1"
. "$rootDir\src-libs\functions\Use-Directory.ns.ps1"

trap {
    write-host "Error found: $_" -f red
    exit 1
}

$nuget = "$rootDir\tools\nuget\nuget.exe"
$pesterDir = Install-NuPackage "pester" "$rootDir\tools" "1.0.7-alpha-0"
$pester = (Get-ChildItem "$pesterDir" pester.psm1 -recurse).FullName


Use-Directory  "$rootDir\src" { 
    & Powershell -noprofile -NonInteractive -command "Import-Module $pester; Invoke-Pester -EnableExit"
    if ($LASTEXITCODE -ne 0) {
        throw "Job run powershell test failed."
    }
} 
