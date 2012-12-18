Function PS-Require($folder) {
    if(Test-Path $folder){
        Get-ChildItem "$folder" -Filter *.ps1 -Recurse | 
            ? { -not ($_.Name.Contains(".Tests.")) } | % {
                . $_.FullName
            }            
    }
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