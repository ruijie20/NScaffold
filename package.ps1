trap {
    write-host "Error found: $_" -f red
    exit 1
}
$root = Split-Path -parent $MyInvocation.MyCommand.Definition
$packageDir = Join-Path $root "tmp\pkgs"

if(test-path .\tmp\pkgs\){
	remove-item .\tmp\pkgs\*.*
} else {
	mkdir .\tmp\pkgs\
}
$nuget = "$root\tools\nuget\NuGet.exe"
& $nuget pack .\src\nudeploy\nscaffold.nudeploy.nuspec -NoPackageAnalysis -o $packageDir


if($LastExitCode -ne 0){
	throw "nuget push fail."
}