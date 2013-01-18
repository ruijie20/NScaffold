
Function Test-ConfigFileEqual($configFile1, $configFile2){
	$config1 = Import-Config $configFile1
	$config2 = Import-Config $configFile2
	if($config1.Count -eq $config2.Count){
		$configDiff = $config1.keys|? { -not ($config1[$_] -eq $config2[$_])}
		-not $configDiff
	}else{
		$false
	}
}