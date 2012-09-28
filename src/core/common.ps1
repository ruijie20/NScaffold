Function Extract-PSFiles($folder) {
	Resolve-Path $folder\*.ps1 | 
    	? { -not ($_.ProviderPath.Contains(".Tests.")) } 
}
