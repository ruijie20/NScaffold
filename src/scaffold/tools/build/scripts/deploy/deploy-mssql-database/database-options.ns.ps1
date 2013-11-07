param($config, $packageInfo, $installArgs, [ScriptBlock] $installAction)

& $installAction

Write-Host "Enable DB User Options: Transaction isolation level" -f green
Invoke-SqlCommand -server $config.server -database $config.dbName "ALTER DATABASE [$($config.dbName)] SET READ_COMMITTED_SNAPSHOT ON" 