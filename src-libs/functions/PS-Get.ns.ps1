Function PS-Get ($packageId, $version = "", [scriptblock] $postInstall){	
    $dir = Install-NuPackage $packageId "$toolsRoot\ps-gets" $version $postInstall
}