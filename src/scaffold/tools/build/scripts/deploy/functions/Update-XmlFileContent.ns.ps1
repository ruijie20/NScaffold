Function Update-XmlFileContent($fullName, [ScriptBlock] $update){	
	[xml]$_ = Get-Content $fullName
	& $update
	$_.Save($fullName)
}
