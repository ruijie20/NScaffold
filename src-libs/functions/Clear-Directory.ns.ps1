Function Clear-Directory($dir){
	if(Test-Path $dir){
        Remove-Item "$dir\*" -Recurse -Force
        Get-Item $dir
    } else {
        New-Item $dir -Type Directory | Out-Null
    }
}