Function Test-PackageExisted($package, $version, $nugetRepo){
    Write-Host "$nuget list $package -source $nugetRepo"
    $allVersions = & $nuget list $package -source $nugetRepo -AllVersions 
    if($allVersions -match "^$package $version$"){
        $true
    }else{
        $false
    }
}

Function Assert-PackagesInRepo($nugetRepo, $apps){
    $nuget = "$PSScriptRoot\tools\nuget\nuget.exe"
    $apps | %{
        $package = $_.package
        $version = $_.version
        "$package $version"
    } | sort| Get-Unique| % {
        $package_version = $_ -split " "
        $package = $package_version[0]
        $version = $package_version[1]
        if(-not (Test-PackageExisted $package $version $nugetRepo)){
            throw "Package[$package] with version[$version] not found in repository[$nugetRepo]"
        }
    }
}