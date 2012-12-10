$rootDir = Split-Path -Parent $MyInvocation.MyCommand.Path

trap {
    write-host "Error found: $_" -f red
    exit 1
}

$nuget = "$rootDir\tools\nuget\nuget.exe"
iex "$nuget install pester -version 1.0.7-alpha-0 -nocache -OutputDirectory $rootDir\tools"
$pesterDir = "$rootDir\tools\Pester.1.0.7-alpha-0"
$pester = (Get-ChildItem "$pesterDir" pester.psm1 -recurse).FullName

& Powershell -noprofile -NonInteractive -command "Import-Module $pester; Invoke-Pester '.\src*' -EnableExit"
if ($LASTEXITCODE -ne 0) {
    throw "Job run powershell test failed."
}