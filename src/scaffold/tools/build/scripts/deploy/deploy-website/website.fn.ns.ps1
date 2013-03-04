Import-Module 'WebAdministration'

Function Get-UrlContent($url){
    Skip-HTTSCertValidation
    Redo-OnException -RetryCount 3 -SleepSecond 3 -RedoActionScriptBlock {
        Trace-Progress "Get content from url[$url]" {
            (New-Object System.Net.WebClient).DownloadString($url)
        }
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

Function Get-UrlForSite($websiteName, $subPath){
    $webSitePath = "IIS:\Sites\$websiteName"
    $firstBinding = $(Get-ItemProperty $webSitePath).Bindings.Collection[0]
    $protocol = $firstBinding.protocol
    $bindingInformation = $firstBinding.bindingInformation
    $ip, $port, $hostName = $bindingInformation -split ':'
    if(-not($hostName)){
        if($ip -eq "*"){
            $hostName = 'localhost'
        }else{
            $hostName = $ip
        }
    }
    "$($protocol)://$($hostName):$port$subPath"
}
Function Get-PhysicalPathForSite($websiteName, $subPath){
    $webSitePath = "IIS:\Sites\$websiteName"
    $physicalPath = $(Get-ItemProperty $webSitePath).physicalPath
    Write-Host "PhysicalPath for site [$webSitePath] is [$physicalPath]"
    if(-not $physicalPath){
        throw "IIS path [$webSitePath] doesn't have physicalPath"
    }
    $physicalPath = [System.Environment]::ExpandEnvironmentVariables($physicalPath)
    "$physicalPath\$subPath"
}
Function Test-SiteExisted($websiteName){
    Test-Path "IIS:\Sites\$websiteName"
}
