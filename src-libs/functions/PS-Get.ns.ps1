Function PS-Get ($packageId, $version = "", [scriptblock] $postInstall){	
    Install-NuPackage $packageId "$toolsRoot\ps-gets" $version $postInstall
}