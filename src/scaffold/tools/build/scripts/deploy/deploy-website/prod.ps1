param($websiteName, $packageInfo, [ScriptBlock] $installAction)

Function Get-PhysicalPath($iisPath){
    $physicalPath = $(Get-ItemProperty $iisPath).physicalPath
    Write-Host "PhysicalPath for site [$iisPath] is [$physicalPath]"
    if(-not $physicalPath){
        throw "IIS path [$iisPath] doesn't have physicalPath"
    }
    return [System.Environment]::ExpandEnvironmentVariables($physicalPath)
}

Function Get-ReadyPagePath ($websiteName){
    $webSitePath = "IIS:\Sites\$websiteName"
    $sitePhysicalPath = Get-PhysicalPath($webSitePath)
    "$sitePhysicalPath\ready.txt"
}

Function Assert-SuspendedFromLoadBalancer($websiteName) {
    Trace-Progress "Assert-SuspendedFromLoadBalancer for site [$websiteName]" {
        if(Test-Path "IIS:\Sites\$websiteName"){
            $readyPagePath = Get-ReadyPagePath $websiteName
            if(Test-Path $readyPagePath) {
                throw "Found file [$readyPagePath]. Website [$websiteName] is not suspended from load balancer!"
            }
        }
    }
}

Function Remove-FromLoadBalancer($websiteName) {
    if(Test-Path "IIS:\Sites\$websiteName"){
        Trace-Progress "Remove-FromLoadBalancer for site $websiteName" {
            $readyPagePath = Get-ReadyPagePath $websiteName
            Remove-Item $readyPagePath -ErrorAction SilentlyContinue
        }
    }
}

Function Add-ToLoadBalancer($websiteName) {
    Trace-Progress "Add-ToLoadBalancer for site $websiteName" {
        if(-not(Test-Path "IIS:\Sites\$websiteName")){
            throw "Site doesn't exist $websiteName"
        }
        $readyPagePath = Get-ReadyPagePath $websiteName
        if(-not (Test-Path $readyPagePath)){
            New-Item $readyPagePath -type File | Out-Null    
        }
    }
}

Function Match-WebsiteWithPackage($websiteName, $packageInfo, $healthCheckPath){

    Write-Host "Source Package [ $($packageInfo.packageId) : $($packageInfo.version) ]"

    if(-not(Test-Path "IIS:\Sites\$websiteName")) {
        $false
    } else {
        $healthCheckUrl = Get-HealthCheckUrl $websiteName $healthCheckPath
        Write-Host "Target HealthCheckUrl: [$healthCheckUrl]"
        $healthCheckPage = Get-HealthCheckPage $healthCheckUrl
        Write-Host "HealthCheckPage `n$healthCheckPage"
        $match = $healthCheckPage -match "Version=$($packageInfo.version)\W"

        if(-not $match){
            $false
        } else {
            if($healthCheckPage -match ".+=Failure\s*`$") {
                Write-Warning "Health page reported there are some failures after the deployment!"
            }
            $true
        }
    }
}

Function Test-Website($websiteName) {
    Test-Path "IIS:\Sites\$websiteName"
}

Function Get-HealthCheckUrl($websiteName, $healthCheckPath){
    $iisPath = "IIS:\Sites\$websiteName"
    $firstBinding = $(Get-ItemProperty $iisPath).Bindings.Collection[0]
    $protocol = $firstBinding.protocol
    $bindingInformation = $firstBinding.bindingInformation
    $ip, $port, $host = $bindingInformation -split ':'
    if($ip -eq "*"){
        $ip = 'localhost'
    }
    if(-not $healthCheckPath){
        $healthCheckPath = "/health?check=all"
    }
    "$($protocol)://$($ip):$port$healthCheckPath"
}

Function Get-HealthCheckPage($healthCheckUrl){
    Skip-HTTSCertValidation
    Redo-OnException -RetryCount 3 -SleepSecond 3 -RedoActionScriptBlock {
        (New-Object System.Net.WebClient).DownloadString($healthCheckUrl)
    }
}

Function Skip-HTTSCertValidation{
    $SetSuccessValidatorSrc = @'
    public static void SetSuccessValidator()
    {
        System.Net.ServicePointManager.ServerCertificateValidationCallback = delegate { return true;} ;
    }
'@
    Add-Type -Namespace PSUtils -Name CSRunner -MemberDefinition $SetSuccessValidatorSrc
    [PSUtils.CSRunner]::SetSuccessValidator()
}

Function Redo-OnException($RetryCount = 3, $SleepSecond = 0, $RedoActionScriptBlock){
    for ($i=0; $true; $i++){
        try{
            return (& $RedoActionScriptBlock)
        }catch{
            if($i -lt $RetryCount){
                Write-Host "Error and retry: $_"
                sleep $SleepSecond
            }else{
                throw $_
            }
        }
    }
}

Function New-Mark($ignore = 7) {
    $stack = Get-PSCallStack
    $num = $stack.Count - $ignore
    if ($num -lt 1) {
        $num = 1
    }
    $mark = ">" * $num
    return $mark
}

Function Trace-ProgressMsg($msg) {
    $mark = New-Mark
    Write-Host "$mark $msg" -f green
}

Function Trace-Progress($msg, $block, $ignoreTrackProgress=7) {
    $mark = New-Mark $ignoreTrackProgress
    Write-Host "$mark Step $msg started..." -f green
    $start = Get-Date
    & $block
    $end = Get-Date
    $durationMS = ($end - $start).TotalMilliseconds
    Write-Host "$mark Step $msg done. ($durationMS ms)" -f green
}

if(Match-WebsiteWithPackage $websiteName $packageInfo $healthCheckPath){
    Trace-ProgressMsg "Website [$websiteName] already deployed to target version. Skip deployment."
    Add-ToLoadBalancer $websiteName
} else {
    if(-not $loadBalancerPollingDurationInSeconds){
        $loadBalancerPollingDurationInSeconds = 30
    }
    try{
        Remove-FromLoadBalancer $websiteName
        Trace-ProgressMsg "Wait $loadBalancerPollingDurationInSeconds second(s) for load balancer to suspend website..."
        Start-Sleep -Seconds $loadBalancerPollingDurationInSeconds
        Assert-SuspendedFromLoadBalancer $websiteName
        & $installAction
        Add-ToLoadBalancer $websiteName
    }catch{
        Write-Warning "Some error occured during the deployment, the website [$websiteName] is left out of loadbalancer."
        throw $_
    }
}   
