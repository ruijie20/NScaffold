param($config, $packageInfo, $installArgs, [ScriptBlock] $installAction)
Write-Host "Clean database" -f green
Remove-Database -server $config.server -database $config.dbName

& $installAction