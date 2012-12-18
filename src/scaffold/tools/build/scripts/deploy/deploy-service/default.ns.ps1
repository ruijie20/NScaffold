param($packageRoot, $installArgs)

$executablePath = $installArgs.executablePath
$exeFile = Get-ChildItem $packageRoot -Recurse -Filter "$executablePath" | select -first 1 
$sourcePath = Split-Path $exeFile.FullName -Parent
$packageInfo = Get-PackageInfo $packageRoot
$packageInfo.Add("sourcePath", $sourcePath)

@{
    'packageInfo' = $packageInfo
    'installAction' = {
        param($config, $packageInfo, $installArgs)
        $sourcePath = $packageInfo.sourcePath
        $executablePath = $installArgs.executablePath
        $name = $config.ServiceName
        $installPath = $config.ServicePath

        for($i = 0; $i < 5; $i++){
            if(Test-ServiceStatus $name "Running"){
                Write-Host "Service[$name] is running. Start stop it." 
                Stop-Service $name
            }            
        }

        if (Test-Path $installPath) {
            Remove-Item $installPath -Force -Recurse
        }

        Write-Host "start copy $sourcePath to $installPath" -f green
        Copy-Item $sourcePath $installPath -Recurse

        if(-not(Test-ServiceStatus $name)){
            Write-Host "Create Service[$name] for $installPath\$executablePath"             
            New-Service -Name $name -BinaryPathName "$installPath\$executablePath" -Description $name -DisplayName $name -StartupType Automatic
        }else{
            Write-Host "Service[$name] already exists" -f green
        }

        Start-Service -Name $name

        if(-not (Test-ServiceStatus $name "Running")){
            throw "Service[$name] is NOT running after installation."
        }
    }
}
