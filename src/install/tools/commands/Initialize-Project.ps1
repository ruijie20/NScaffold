
function Initialize-Project([string]$projectPath) {
	$nuget = $config.nuget
	$nugetSource = $config.scaffoldSource
	$localRepo =  Join-Path $env:appdata "NScaffold\scaffolds\"
	
	if(-not (Test-Path $projectPath)){
		throw "'$projectPath' is an invalid path. "	
	}
	
 	$scaffoldDir = Install-NuPackage "NScaffold.Scaffold" "$localRepo"
 	copy-item "$scaffoldDir\*" "$projectPath" -force -recurse -verbose
}