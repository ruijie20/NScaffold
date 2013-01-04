param($packageRoot, $installArgs)

$packageInfo = Get-PackageInfo $packageRoot

@{
    'packageInfo' = $packageInfo
    'installAction' = {
        param($config, $packageInfo, $installArgs)
        if($installArgs.migrate){
            if(Test-DBExisted $config.server $config.dbName) {
                Run-Closure $installArgs.migrate $config
            }
            else {
                throw "Database [$($config.dbName)] does not exist in server [$($config.server)]. "
            }
        } else{
            throw "Please specify migrate action in installArgs as closure. "
        }
    }
}
