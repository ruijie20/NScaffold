Function Pack-Node($node, $version, $packAction){
    if($node.prePackage){
    	Push-Location
    	Set-Location $node.spec.DirectoryName
    	try{
    		& $node.prePackage $node.spec.DirectoryName $version
    	} finally {
    		Pop-Location	
    	}
    }
    $fullSpecFile = New-PackageSpec $node.spec $node.type $packAction
    try {
        & $packAction $fullSpecFile
    } finally {
        Remove-Item $fullSpecFile
    }
}
