Function Use-Directory ($dir, [ScriptBlock]$action){
	if(-not (Test-Path $dir)){
        New-Item $dir -Type Directory
    }
    Set-Location $dir
    & $action
    Pop-Location
}