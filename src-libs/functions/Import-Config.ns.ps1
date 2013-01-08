Function Import-Config($configFile) {
	$config = @{}
    if($configFile -and (Test-Path $configFile)){
    	Get-Content $configFile | % {
    		$index = $_.indexOf("=")
    		if($index -gt 0){
    			$key = $_.substring(0, $index).trim()
    			$value = $_.substring($index + 1).trim()
    			$config[$key] = $value
    		}
    	}
    }
	$config
}
