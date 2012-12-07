$dir = Join-Path $(Split-Path -parent $MyInvocation.MyCommand.Definition) "tmp\pkgs\"
if(test-path .\tmp\pkgs\){
	remove-item .\tmp\pkgs\*.*
} else {
	mkdir .\tmp\pkgs\
}

.\tools\nuget\NuGet.exe pack .\src\nudeploy\nscaffold.nudeploy.nuspec -NoPackageAnalysis -o $dir

$package = "NScaffold.NuDeploy"
[regex]$regex = "NScaffold.NuDeploy.([\d\.]*)\.nupkg"
$nupackagePath = Get-ChildItem $dir | ? {$_.Name -like "$package*"} | Select-Object -First 1
$version = $nupackagePath.FullName |  % { $regex.Matches($_) } | % { $_.Groups[1].Value }

Set-Content "$dir\version.txt" $version

Copy-Item "$dir\NScaffold.NuDeploy.$version.nupkg" "\\10.18.1.28\nuget-packages\"