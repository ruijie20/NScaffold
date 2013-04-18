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
            if($_ -match "(.*?)\.(\d+((\.\d+)((\.\d+)(\.\d+)?)?)?)") {
                $key = $($matches[1])
                $value = $($matches[2])
                $versionSpec[$key] = $value
            }
        }
    }
    $versionSpec
}

Function Apply-VersionSpec($envConfig, $versionSpec){
    $envConfig.apps | ? { -not $_.version } | % {$_.version = $versionSpec[$_.package]}
}