
function Initialize-Project([string]$projectPath) {

	$nuget = $config.nuget
	$nugetSource = $config.scaffoldSource

	if(-not (Test-Path $projectPath)){
		throw "'$projectPath' is an invalid path. "	
	}
	
 	$scaffoldDir = Install-Package "NScaffold.Scaffold" "$localRepo"
 	copy-item "$scaffoldDir\*" "$projectPath" -force -recurse -verbose
}

Function Install-Package($package, $workingDir) {
	Write-Host "Downloading package [$package] from [$nugetSource] to [$workingDir]...." -f cyan
	[regex]$regex = "(?i)`'$package ([\d\.]*)`'"
	$versionSection = Get-VersionSection
	$nuGetInstallOutput = Iex "$nuget install $package $versionSection -s $nugetSource -nocache -OutputDirectory $workingDir"
	if (!$version) {
	 	$version = $nuGetInstallOutput |  % { $regex.Matches($_) } | % { $_.Groups[1].Value }
	}

	if(-not $version){
		throw "no package found"
	}
 	
 	$packageDir = "$workingDir\$package.$version"
	Write-Host "Package [$package] has been downloaded to [$packageDir]." -f cyan
 	$packageDir
}

Function Get-VersionSection {
	$versionSection = ""
	if ($version) {
		$versionSection = "-v $version"
	}
	$versionSection
}