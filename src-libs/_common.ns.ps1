Function PSRequire($folder) {
	Resolve-Path $folder\*.ps1 | 
    	? { -not ($_.ProviderPath.Contains(".Tests.")) } | 
    	% { . $_.ProviderPath }
}

Function PS-Include ($path) {
    $callingDir = $MyInvocation.ScriptName | Split-Path -parent
    $targetScript = Join-Path $callingDir $path
    if (Test-Path $targetScript) {
        $targetScript = Resolve-Path $targetScript        
        . $targetScript
    } else{
        throw "Link error: $targetScript not found! Don't forget to use '. include'"
    }    
}

Function Register-Extension ($hostFile){
	$extPath = "$($hostFile.trimend(".ns.ps1")).ext.ps1"
	if(test-path $extPath){
		. $extPath
	}
}