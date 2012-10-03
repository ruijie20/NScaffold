Function Install-NuPackage($package, $workingDir, $version = "") {
	Write-Host "Downloading package [$package] from [$nugetSource] to [$workingDir]...." -f cyan
	[regex]$regex = "(?i)`'$package ([\d\.]*)`'"

	if ($version) {
		$versionSection = "-v $version"
	}

	if($nugetSource){
		$sourceSection = "-s $nugetSource"
	}

	$nuget = "$toolsRoot\nuget\nuget.exe"	
	$cmd = "$nuget install $package $versionSection $sourceSection -nocache -OutputDirectory $workingDir"
	$nuGetInstallOutput = Iex "$cmd"
	if (!$version) {
	 	$version = $nuGetInstallOutput |  % { $regex.Matches($_) } | % { $_.Groups[1].Value }
	}

	if ($nuGetInstallOutput -contains "Unable") {
		Write-Host "$cmd" -f yellow
	    throw "Package not found. "
	}

	if(-not $version){
		Write-Host "$cmd" -f yellow
		throw "No package was installed. "
	}
 	
 	$packageDir = "$workingDir\$package.$version"
	Write-Host "Package [$package] has been downloaded to [$packageDir]." -f cyan
 	$packageDir
}
