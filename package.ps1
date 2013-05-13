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

if($Env:CRUISE_PIPELINE_COUNTER){
	$buildNumber = $Env:CRUISE_PIPELINE_COUNTER
}else{
	$buildNumber = 0
}
$version = "0.0.113.$buildNumber"
Write-Host "Create Package version $version"

$nuget = "$root\tools\nuget\NuGet.exe"
& $nuget pack .\src\nudeploy\nscaffold.nudeploy.nuspec -NoPackageAnalysis -o $packageDir -Version $version

if($LastExitCode -ne 0){
	throw "nuget push fail."
}