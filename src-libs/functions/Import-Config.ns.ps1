Function Import-Config($configFile) {
	$config = @{}
    if($configFile -and (Test-Path $configFile)){
        $csv = import-csv $configFile -Delimiter '=' -header 'key','value'
        $csv | ? {$_.key} | % {
            $config[$_.key.trim()] = $_.value.trim()
        }        
    }
	$config
}
