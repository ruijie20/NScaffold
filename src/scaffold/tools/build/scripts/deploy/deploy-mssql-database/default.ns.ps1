param($packageRoot, $installArgs)

$packageInfo = Get-PackageInfo $packageRoot

@{
    'packageInfo' = $packageInfo
    'installAction' = {
        param($config, $packageInfo, $installArgs)
        if($installArgs.migrate){
            Run-Closure $installArgs.migrate
        } else{
            throw "Please specify migrate action in installArgs as closure. "
        }
    }
}
