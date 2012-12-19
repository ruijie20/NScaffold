param($config, $packageInfo, $installArgs, [ScriptBlock] $installAction)
Write-Host "Clean database" -f green

$dir = $MyInvocation.MyCommand.Path | Split-Path -Parent
$scriptDir = "$dir\functions\db-scripts"
Remove-Database -server $config.server -database $config.dbName

if(!(Test-DBExisted $config.server $config.dbName)){
	Write-Host  "Restore database [$($config.dbName)]" -f green
	Invoke-SqlCommand -server $config.server -command "CREATE DATABASE [$($config.dbName)]"	
	Invoke-SqlScript -server $config.server -database $config.dbName -file "$($installArgs.baseline)"
}Else{
	Write-Host  "Database already exists,restore canceled." -f green
}

if($config.userName){
	$userNames = $config.userName.Split(",")
	$userNames | %{
		Grant-DBAccess $config.server $config.dbName $_ $config.password
	}
}

& $installAction