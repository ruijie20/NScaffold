
Function Install-NuPackage($package, $workingDir, [string]$version = "", [scriptblock] $postInstall) {
    Write-Host "$(date): Downloading package [$package] from [$nugetSource] to [$workingDir]...." -f cyan
    
    if ($version) {
        $versionSection = "-version $version"
    }

    if($nugetSource){
        $sourceSection = "-source $nugetSource"
    }

    # need $nuget to be set, if not set, will search $root directory    
    if(!$nuget){
        throw "`$nuget need to be set. "
    }

    $packageInstalled = @(Iex "$nuget list $package -allversions -source $workingDir")

    if($packageInstalled -contains "$package $version"){ 
        write-host "Already installed [$package $version]" -f cyan
        return "$workingDir\$package.$version"
    }

    $cmd = "$nuget install $package $versionSection $sourceSection -OutputDirectory $workingDir 2>&1"
    Write-Host "Executing: $cmd"
    $nuGetInstallOutput = Iex "$cmd"

    if($LastExitCode -ne 0){
        throw "$nuGetInstallOutput"
    }    

    if($version){
        $installedVersion = $version
    } else {
        $installedVersion = "$nuGetInstallOutput" -match "(?i)\'$package (?<version>.*?)\'" | % { $matches.version }  
    }

    if ($nuGetInstallOutput -match "Unable") {
        throw "$nuGetInstallOutput"
    }

    if(-not $installedVersion){
        throw "$nuGetInstallOutput"
    }

    $packageDir = "$workingDir\$package.$installedVersion"
    Write-Host "Package [$package] has been downloaded to [$packageDir]." -f cyan
    if(($nuGetInstallOutput -match "Successfully installed") -or ($nuGetInstallOutput -match "already installed")){
        if($postInstall){
            &$postInstall $packageDir | Out-Null         
        }
    }
    $packageDir
}
