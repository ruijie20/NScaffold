Function PS-Get ($packageId, $version = "", [scriptblock] $after){	
    $dir = "$toolsRoot\ps-gets\$packageId.$version"
    if (-not (Test-Path $dir)) {
        $dir = Install-NuPackage $packageId "$toolsRoot\ps-gets" $version    
    } 
	if($after){
		&$after $dir
	}	
}