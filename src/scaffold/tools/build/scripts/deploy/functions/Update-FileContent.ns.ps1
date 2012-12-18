Function Update-FileContent($filePath, $needToReplace, $replaceTo) {
	(Get-Content $filePath) | % { $_ -Replace $needToReplace, $replaceTo } | Set-Content $filePath
}
