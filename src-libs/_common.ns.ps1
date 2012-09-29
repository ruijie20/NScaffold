Function PSRequire($folder) {
	Resolve-Path $folder\*.ps1 | 
    	? { -not ($_.ProviderPath.Contains(".Tests.")) } | 
    	% { . $_.ProviderPath }
}

Function Register-Extension ($hostFile){
	$extPath = "$($hostFile.trimend(".ns.ps1")).ext.ps1"
	if(test-path $extPath){
		. $extPath
	}
}