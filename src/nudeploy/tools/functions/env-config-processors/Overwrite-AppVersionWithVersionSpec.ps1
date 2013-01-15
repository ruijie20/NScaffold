Function Overwrite-AppVersionWithVersionSpec($envConfig, $versionSpecPath){
    $versionSpec = Import-VersionSpec $versionSpecPath
    Apply-VersionSpec $envConfig $versionSpec
    Write-Host "Overwritten AppVersionWithVersionSpec:"
    $versionSpec | Out-Host
}

Function Import-VersionSpec($versionSpecPath) {
    if($versionSpecPath -and (Test-Path $versionSpecPath)) {
        $versionSpec = Import-Config $versionSpecPath
    }else{
        $versionSpec = @{}
    }
    $versionSpec
}

Function Apply-VersionSpec($envConfig, $versionSpec){
    $envConfig.apps | ? { -not $_.version } | % {$_.version = $versionSpec[$_.package]}
}