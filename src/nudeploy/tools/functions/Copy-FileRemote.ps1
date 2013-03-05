Function Copy-FileRemote($server, $sourceFile, $destFile) {
	Write-Host "Start Copy-FileRemote from $sourceFile to $server : $destFile"
	[byte[]]$content = [System.IO.File]::ReadAllBytes( $(resolve-path $sourceFile) ) 
	invoke-command -ErrorVariable ice -computername $server -scriptblock {
		param($path, $content) 
		[System.IO.File]::WriteAllBytes($Path, $content)
	} -ArgumentList $destFile, $content
	if($ice){throw $ice}
	Write-Host "End Copy-FileRemote from $sourceFile to $server : $destFile"
}
