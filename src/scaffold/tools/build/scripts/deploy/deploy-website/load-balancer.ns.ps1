param($config, $packageInfo, $installArgs, [ScriptBlock] $installAction)

$here = $MyInvocation.MyCommand.Path | Split-Path -Parent
. $here\load-balancer.fn.ns.ps1

$webSiteName = $config.siteName

if(-not $loadBalancerPollingDurationInSeconds){
    $loadBalancerPollingDurationInSeconds = 30
}

try{
    if(-not(Test-SuspendedFromLoadBalancer $websiteName)){
        Remove-FromLoadBalancer $websiteName
        Assert-SuspendedFromLoadBalancer $websiteName
        Trace-ProgressMsg "Wait $loadBalancerPollingDurationInSeconds second(s) for load balancer to suspend website[$websiteName]..."
        Start-Sleep -Seconds $loadBalancerPollingDurationInSeconds
    }
    & $installAction
    Add-ToLoadBalancer $websiteName
    Assert-AddedToLoadBalancer $websiteName
    Trace-ProgressMsg "Wait $loadBalancerPollingDurationInSeconds second(s) for load balancer to pick up website[$websiteName]..."
    Start-Sleep -Seconds $loadBalancerPollingDurationInSeconds
}catch{
    Write-Warning "Some error occured during the deployment, the website [$websiteName] is left out of loadbalancer."
    throw $_
}
