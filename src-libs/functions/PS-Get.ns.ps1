Function PS-Get ($package, $version = "", [scriptblock] $after){	
	$dir = Install-NuPackage $package "$toolsRoot\ps-gets" $version
	if($after){
		&$after $dir
	}	
}