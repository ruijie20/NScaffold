Function Set-DefaultAppVersionWithLatestVersion($envConfig) {
    $unversionPackages = $envConfig.apps | ? { -not $_.version }
    if(-not $unversionPackages) {return}

    $latestVersions = @{}
    $unversionPackages | % { $_.package } | Get-Unique | %{ $latestVersions[$_] = Resolve-LatestPackageVersion $_ $envConfig.nugetRepo }
    $unversionPackages | % {$_.version = $latestVersions[$_.package]}
    Write-Host "Resolved VersionSpec:"
    $latestVersions | Out-Host
}
Function Resolve-LatestPackageVersion($package, $nugetRepo){
    $nuget = "$PSScriptRoot\tools\nuget\nuget.exe"
    Write-Host "$nuget list $package -source $nugetRepo"
    if( (& $nuget list $package -source $nugetRepo | ? { 
        $_ -match "^$package (?<version>(?:\d+\.)*\d+(?:-(?:\w|-)*)?)" })){
        Write-Host "Found lastest version $($matches['version']) for package [$package]"
        return $matches['version']
    }else{
        throw "No version found for package [$package] in repo [$nugetRepo]"
    }
}