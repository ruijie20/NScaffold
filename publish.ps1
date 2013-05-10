trap {
    write-host "Error found: $_" -f red
    exit 1
}
$root = Split-Path -parent $MyInvocation.MyCommand.Definition
$packageDir = Join-Path $root "tmp\pkgs"

Function Publish-Package($packageFileName, $repoPath){
	$sourceFilePath = "$packageDir\$packageFileName"
	$destFilePath = "$repoPath\NScaffold.NuDeploy"
	if(-not(Test-Path $sourceFilePath)){
		throw "package file not found $sourceFilePath"
	}
	if(Test-Path $destFilePath){
		throw "Package[$packageFileName] already existed in repository[$repoPath]"
	}
write-host "Copy-Item $sourceFilePath $destFilePath"
	Copy-Item $sourceFilePath $destFilePath
write-host "1"
}

$package = "NScaffold.NuDeploy"
[regex]$regex = "NScaffold.NuDeploy.([\d\.]*)\.nupkg"
$nupackagePath = Get-ChildItem $packageDir | ? {$_.Name -like "$package*"} | Select-Object -First 1
$version = $nupackagePath.FullName |  % { $regex.Matches($_) } | % { $_.Groups[1].Value }
$packageFileName = "$package.$version.nupkg"

$tempRepoFolder = "\\10.18.7.148\nuget-servers\nuget-pkgs-tmp"
$integrationRepoFolder = "\\10.18.7.148\nuget-servers\nuget-pkgs-integration"

Publish-Package $packageFileName $tempRepoFolder
Publish-Package $packageFileName $integrationRepoFolder

