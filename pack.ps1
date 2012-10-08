$dir = Join-Path $(Split-Path -parent $MyInvocation.MyCommand.Definition) "tmp\pkgs\"
if(test-path .\tmp\pkgs\){
	remove-item .\tmp\pkgs\*.*
} else {
	mkdir .\tmp\pkgs\
}
.\tools\nuget\NuGet.exe pack .\src\ns-install\NScaffold.nuspec -NoPackageAnalysis -o $dir
$url = $dir.Replace("\", "/")
cinst NScaffold -source "file:///$url" -force