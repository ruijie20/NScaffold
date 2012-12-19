param($config, $packageInfo, $installArgs, [ScriptBlock] $installAction)

$webSiteName = $config.siteName
$webSitePath = "IIS:\Sites\$webSiteName"

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

# if(Match-WebsiteWithPackage $websiteName $packageInfo $healthCheckPath){
#     Trace-ProgressMsg "Website [$websiteName] already deployed to target version. Skip deployment."
#     Add-ToLoadBalancer $websiteName
# } else {
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

# if(-not (Match-WebsiteWithPackage $websiteName $packageInfo $healthCheckPath)){
#     throw "Site [$webSiteName] doesn't match package [$($packageInfo.packageId)]"
# }
