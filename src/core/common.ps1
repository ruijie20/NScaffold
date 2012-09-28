Function Include-PSFolder($folder) {
	Resolve-Path $folder\*.ps1 | 
    	? { -not ($_.ProviderPath.Contains(".Tests.")) } |
    	% { . $_.ProviderPath }
}
