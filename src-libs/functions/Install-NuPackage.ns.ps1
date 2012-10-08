Function Install-NuPackage($package, $workingDir, [string]$version = "", [scriptblock] $postInstall) {
	Write-Host "Downloading package [$package] from [$nugetSource] to [$workingDir]...." -f cyan
	[regex]$regex = "(?i)\'$package (?<version>.*)\'"
	if ($version) {
		$versionSection = "-v $version"
	}

	if($nugetSource){
		$sourceSection = "-s $nugetSource"
	}
	
	# 'xunit 1.9.1' already installed.
	# Successfully installed 'xunit 1.9.1'.

	$nuget = "$toolsRoot\nuget\nuget.exe"	
	$cmd = "$nuget install $package $versionSection $sourceSection -nocache -OutputDirectory $workingDir"
	$nuGetInstallOutput = Iex "$cmd"
	
	if($version){
		$installedVersion = $version
	} else {
		$installedVersion = $nuGetInstallOutput -match $regex | % { $matches.version }	
	}

	if ($nuGetInstallOutput -match "Unable") {
		Write-Host "$cmd" -f yellow
	    throw "$nuGetInstallOutput"
	}

	if(-not $installedVersion){
		Write-Host "$cmd" -f yellow
		throw "$nuGetInstallOutput"
	}

 	$packageDir = "$workingDir\$package.$installedVersion"
	Write-Host "Package [$package] has been downloaded to [$packageDir]." -f cyan
	if($nuGetInstallOutput -match "Successfully installed"){
		if($postInstall){
			&$postInstall $packageDir			
		}
	}
 	$packageDir
}
