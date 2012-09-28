
function Initialize-Project([string]$projectPath) {
	$localRepo =  Join-Path $env:appdata "NScaffold\scaffolds\"
	
	if(-not (Test-Path $projectPath)){
		throw "'$projectPath' is an invalid path. "	
	}
	
 	$scaffoldDir = Install-NuPackage "NScaffold.Scaffold" "$localRepo"
 	copy-item "$scaffoldDir\*" "$projectPath" -force -recurse -verbose
}