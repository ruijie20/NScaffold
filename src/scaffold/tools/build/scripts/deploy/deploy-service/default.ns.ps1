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
        $retryCount = 60
        $retryIntervalInSec = 10
        $sourcePath = $packageInfo.sourcePath
        $executablePath = $installArgs.executablePath
        $name = $config.ServiceName
        $installPath = $config.ServicePath

        for($i = 0; $i -lt $retryCount; $i++){
            if(Test-ServiceStatus $name "Running"){
                Write-Host "Service[$name] is running. Start to stop it." 
                Stop-Service $name
                Sleep $retryIntervalInSec
            }            
        }
        if(Test-ServiceStatus $name "Running"){
            throw "Not able to stop service $name"
        }

        if (Test-Path $installPath) {
            Remove-Item $installPath -Force -Recurse
        }

        Write-Host "Start to copy $sourcePath to $installPath" -f green
        Copy-Item $sourcePath $installPath -Recurse
        
        $serviceBinPath = "$installPath\$executablePath"
        if(-not(Test-ServiceStatus $name)){
            Write-Host "Create Service[$name] for $serviceBinPath"             
            New-Service -Name $name -BinaryPathName "$serviceBinPath" -Description $name -DisplayName $name -StartupType Automatic
        }else{
            Write-Host "Service[$name] already exists,change BinaryPathName to $serviceBinPath" -f green
            iex "SC.exe CONFIG $name binPath= $serviceBinPath"
            Set-Service $name -StartupType Automatic
        }

        Start-Service -Name $name

        if(-not (Test-ServiceStatus $name "Running")){
            throw "Service[$name] is NOT running after installation."
        }
        Write-Host "Service started. " -f green
    }
}
