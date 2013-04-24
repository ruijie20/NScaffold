Function Overwrite-AppVersionWithVersionSpec($envConfig, $versionSpecPath){
    $versionSpec = Import-VersionSpec $versionSpecPath
    Assert-VersionSpec $versionSpec $envConfig.nugetRepo
    Apply-VersionSpec $envConfig $versionSpec
    Write-Host "Overwritten AppVersionWithVersionSpec:"
    $versionSpec | Out-Host
}

Function Test-PackageExisted($package, $version, $nugetRepo){
    Write-Host "$nuget list $package -source $nugetRepo"
    $allVersions = & $nuget list $package -source $nugetRepo -AllVersions 
    if($allVersions -match "^$package $version$"){
        $true
    }else{
        $false
    }
}

Function Assert-VersionSpec($versionSpec, $nugetRepo){
    $nuget = "$PSScriptRoot\tools\nuget\nuget.exe"
    $versionSpec.keys |%{
        $package = $_
        $version = $versionSpec[$_]
        if(-not (Test-PackageExisted $package $version $nugetRepo)){
            throw "Package[$package] with version[$version] not found in repository[$nugetRepo]"
        }
    }
}

Function Import-VersionSpec($versionSpecPath) {
    $versionSpec= @{}
    if($versionSpecPath -and (Test-Path $versionSpecPath)) {
        Get-Content $versionSpecPath | % {
            if($_ -match "(?<id>.+?)\.(?<version>(?:\d+\.)*\d+(?:-(?:\w|-)*)?)") {
                $key = $matches.id
                $value = $matches.version
                $versionSpec[$key] = $value
            }
        }
    }
    $versionSpec
}

Function Apply-VersionSpec($envConfig, $versionSpec){
    $envConfig.apps | ? { -not $_.version } | % {$_.version = $versionSpec[$_.package]}
}