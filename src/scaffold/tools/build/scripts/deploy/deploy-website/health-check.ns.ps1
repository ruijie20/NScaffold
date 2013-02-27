param($config, $packageInfo, $installArgs, [ScriptBlock] $installAction)

$webSiteName = $config.siteName
$webSitePath = "IIS:\Sites\$webSiteName"
$healthCheckPath = $config.healthCheckPath

Function Get-HealthCheckUrl(){
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
        if(-not $healthCheckPath){
            $healthCheckPath = "/health?check=all"
        }
    }
    "$($protocol)://$($hostName):$port$healthCheckPath"
}

Function Match-WebsiteWithPackage(){
    Write-Host "Source Package [ $($packageInfo.packageId) : $($packageInfo.version) ]"
    if(-not(Test-Path $webSitePath)) {
        $false
    } else {
        $healthCheckUrl = Get-HealthCheckUrl
        Write-Host "Target HealthCheckUrl: [$healthCheckUrl]"
        $healthCheckPage = Get-HealthCheckPage $healthCheckUrl
        Write-Host "HealthCheckPage `n$healthCheckPage"
        $match = $healthCheckPage -match "Version=$($packageInfo.version)\W"

        if(-not $match){
            $false
        } else {
            if($healthCheckPage -match ".+=Failure\s*") {
                Write-Warning "Health page reported there are some failures after the deployment!"
            }
            $true
        }
    }
}

Function Get-HealthCheckPage(){
    Skip-HTTSCertValidation
    Redo-OnException -RetryCount 3 -SleepSecond 3 -RedoActionScriptBlock {
        $healthCheckUrl = Get-HealthCheckUrl
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


# if(Match-WebsiteWithPackage){
#    Write-Host "Website [$webSiteName] already deployed to target version. Skip deployment."
#    Add-ToLoadBalancer $webSiteName
#    return
# }

& $installAction

if(-not (Match-WebsiteWithPackage)){
    throw "Site [$webSiteName] doesn't match package [$($packageInfo.packageId)]"
}
