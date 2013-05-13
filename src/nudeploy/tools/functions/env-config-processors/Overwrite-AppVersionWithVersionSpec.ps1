Function Overwrite-AppVersionWithVersionSpec($envConfig, $versionSpecPath){
    $versionSpec = Import-VersionSpec $versionSpecPath
    Apply-VersionSpec $envConfig $versionSpec
    Write-Host "Overwritten AppVersionWithVersionSpec:"
    $versionSpec | Out-Host
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
    $envConfig.apps | ? { -not $_.version } | % {
        $_.version = $versionSpec[$_.package]
        Write-Host "Set package[$($_.package)] as version[$($_.version)] from versionSpec"
    }
}