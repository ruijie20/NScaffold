Function Use-Directory ($dir, [ScriptBlock]$action){
	if(-not (Test-Path $dir)){
        New-Item $dir -Type Directory | Out-Null
    }
    
    Set-Location $dir
    try{
        & $action
    } 
    finally{
        Pop-Location
    }
    
}