param($config, $packageInfo, [ScriptBlock] $installAction)
Write-Host "Clean database" -f green

$dir = $MyInvocation.MyCommand.Path | Split-Path -Parent
$scriptDir = "$dir\functions\db-scripts"
Remove-Database -server $config.server -database $config.dbName


if(!(Test-DBExisted $config.server $config.dbName)){
	Write-Host  "Restore database [$($config.dbName)]" -f green
	Invoke-SqlScript -server $config.server -file $sqlFolder\create-db_WORKING.sql -Variables @{ 
		dbName = $config.dbName
	}
	Invoke-SqlScript -server $config.server -database $config.dbName -file $sqlFolder\create-baseline-tables.sql
}Else{
	Write-Host  "Database already exists,restore canceled." -f green
}

if($config.userName){
	$userNames = $config.userName.Split(",")
	$userNames | %{
		Grant-DBAccess $config.server $config.dbName $_ $config.password
	}
}

