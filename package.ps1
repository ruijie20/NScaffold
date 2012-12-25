trap {
    write-host "Error found: $_" -f red
    exit 1
}
$root = Split-Path -parent $MyInvocation.MyCommand.Definition
$dir = Join-Path $root "tmp\pkgs"

if(test-path .\tmp\pkgs\){
	remove-item .\tmp\pkgs\*.*
} else {
	mkdir .\tmp\pkgs\
}
$nuget = "$root\tools\nuget\NuGet.exe"
& $nuget pack .\src\nudeploy\nscaffold.nudeploy.nuspec -NoPackageAnalysis -o $dir

$package = "NScaffold.NuDeploy"
[regex]$regex = "NScaffold.NuDeploy.([\d\.]*)\.nupkg"
$nupackagePath = Get-ChildItem $dir | ? {$_.Name -like "$package*"} | Select-Object -First 1
$version = $nupackagePath.FullName |  % { $regex.Matches($_) } | % { $_.Groups[1].Value }

Set-Content "$dir\version.txt" $version

& $nuget push "$dir\NScaffold.NuDeploy.$version.nupkg" -source "http://10.18.7.148/nuget-server-tmp" "01634e7b-0c29-4c1d-b06f-d991b0730124"

if($LastExitCode -ne 0){
	throw "nuget push fail."
}