$dir = Join-Path $(Split-Path -parent $MyInvocation.MyCommand.Definition) "tmp\pkgs\"
if(test-path .\tmp\pkgs\){
	remove-item .\tmp\pkgs\*.*
} else {
	mkdir .\tmp\pkgs\
}

.\tools\nuget\NuGet.exe pack .\src\ns-install\nscaffold.nuspec -NoPackageAnalysis -o $dir
.\tools\nuget\NuGet.exe pack .\src\scaffold\nscaffold.scaffold.nuspec -NoPackageAnalysis -o $dir


if(test-path $env:ChocolateyInstall\bin\NScaffold.bat){
	remove-item $env:ChocolateyInstall\bin\NScaffold.bat
	remove-item $env:ChocolateyInstall\lib\NScaffold* -Recurse
}

$url = $dir.Replace("\", "/")
cinst NScaffold -source "file:///$url" -force
"file:///$url"