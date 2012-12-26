Function Verify-Config($config, $refConfig){
    $configTable = Import-Config $config
    $refConfigTable = Import-Config $refConfig

    $missing = $refConfigTable.Keys | ? { -not $configTable.ContainsKey($_) }
    $outdated = $configTable.Keys | ? { -not $refConfigTable.ContainsKey($_) }

    if ($outdated) {
        Write-Warning "Outdated configuration for $outdated. "
    }

    if ($missing) {
        throw "Missing configuration for $missing. "
    }
}
