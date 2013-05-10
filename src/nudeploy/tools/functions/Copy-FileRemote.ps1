Function Copy-FileRemote($server, $sourceFile, $destFile) {
	Write-Host "Start Copy-FileRemote from $sourceFile to $server : $destFile"
	
	$parentFolder = Split-Path $destFile
	invoke-command -ErrorVariable ice -computername $server -scriptblock {
		param($folder) 
		New-Item $folder -Type Directory
	} -ArgumentList $parentFolder
	if($ice){throw $ice}

	[byte[]]$content = [System.IO.File]::ReadAllBytes( $(resolve-path $sourceFile) ) 
	invoke-command -ErrorVariable ice -computername $server -scriptblock {
		param($path, $content) 
		[System.IO.File]::WriteAllBytes($Path, $content)
	} -ArgumentList $destFile, $content
	if($ice){throw $ice}

	Write-Host "End Copy-FileRemote from $sourceFile to $server : $destFile"
}
