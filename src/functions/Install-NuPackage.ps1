Function Install-NuPackage($package, $workingDir, $version = "") {
	Write-Host "Downloading package [$package] from [$nugetSource] to [$workingDir]...." -f cyan
	[regex]$regex = "(?i)`'$package ([\d\.]*)`'"

	$versionSection = ""
	if ($version) {
		$versionSection = "-v $version"
	}
	
	$nuGetInstallOutput = Iex "$nuget install $package $versionSection -s $nugetSource -nocache -OutputDirectory $workingDir"
	if (!$version) {
	 	$version = $nuGetInstallOutput |  % { $regex.Matches($_) } | % { $_.Groups[1].Value }
	}

	if(-not $version){
		throw "No package was installed. "
	}
 	
 	$packageDir = "$workingDir\$package.$version"
	Write-Host "Package [$package] has been downloaded to [$packageDir]." -f cyan
 	$packageDir
}
