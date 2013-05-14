Function Pack-Node($node, $packAction){
    if($node.prePackage){
    	Push-Location
    	Set-Location $node.spec.DirectoryName
    	try{
    		& $node.prePackage $node.spec.DirectoryName	
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
