$dir = Join-Path $(Split-Path -parent $MyInvocation.MyCommand.Definition) "tmp\pkgs\"
remove-item .\tmp\pkgs\*.*

nuget\NuGet.exe pack .\src\install\NScaffold.nuspec -NoPackageAnalysis -o $dir
$url = $dir.Replace("\", "/")
cinst NScaffold -source "file:///$url" -force