Function Save-Location([ScriptBlock]$action) {
	Push-Location
	Try {
		& $action
	} Finally {
		Pop-Location
	}
}
