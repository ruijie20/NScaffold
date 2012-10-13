Function Clear-Directory($dir){
	if(Test-Path $dir){
        Remove-Item "$dir\*" -Recurse -Force
    } else {
        New-Item $dir -Type Directory
    }
}