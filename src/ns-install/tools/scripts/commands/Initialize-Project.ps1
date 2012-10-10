Function Initialize-Project([string]$projectPath) {
	$localRepo =  Join-Path $env:appdata "NScaffold\scaffolds\"
	
	if(-not (Test-Path $projectPath)){
		throw "'$projectPath' is an invalid path. "	
	}
	
 	$scaffoldDir = Install-NuPackage "NScaffold.Scaffold" "$localRepo"
 	Clean-Scaffold $projectPath
	Apply-Scaffold $scaffoldDir $projectPath 	
}

Function Apply-Scaffold ($scaffoldDir, $projectPath) {
	Set-Location $scaffoldDir\tools\
 	Get-ChildItem . -Recurse | ? { -not $_.PSIsContainer} | Resolve-Path -Relative |
 		% {
 			$destFileFullPath = [System.IO.Path]::GetFullPath((Join-Path $projectPath (Resolve-Path $_ -Relative)))
 			if (Test-Path $destFileFullPath) {
 				Write-Host "Skipping $destFileFullPath" -f yellow
 			} else {
 				$destDir = Split-Path $destFileFullPath -Parent
 				if(-not (Test-Path $destDir)){
 					New-Item $destDir -Type Directory | Out-Null
 				}
				Copy-Item $_ $destDir
				Write-Host "Copying $_" -f yellow
 			} 			
 		}
 	Pop-Location
}

Function Clean-Scaffold([string]$projectPath){
	Remove-Item $projectPath\*.ns.ps1
    if (Test-Path "$projectPath\build") {
        Get-ChildItem "$projectPath\build" -filter *.ns.ps1 -Recurse | Remove-Item    
    }	
}