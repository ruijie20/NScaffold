Function Use-Directory ($dir, [scriptblock] scriptblock){
	if(-not (Test-Path $dir)){
        New-Item $dir -Type Directory
    }
    Set-Location $dir
    &scriptblock
    Pop-Location
}