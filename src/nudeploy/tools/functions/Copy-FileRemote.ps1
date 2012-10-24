Function Copy-FileRemote($server, $sourceFile, $destFile) {
	[byte[]]$content = Get-Content $sourceFile -Encoding byte
	invoke-command -computername $server -scriptblock {
		param($path, $content) Set-Content $path $content -Encoding byte
	} -ArgumentList $destFile, $content
}
