$here = $MyInvocation.MyCommand.Path | Split-Path -Parent
. $here\website.fn.ns.ps1

Function Get-HealthCheckUrl($webSiteName, $healthCheckPath){
    if(-not $healthCheckPath){
        $healthCheckPath = "/health?check=all"
    }
    Get-UrlForSite $webSiteName $healthCheckPath
}
Function Test-DependencyFailure($healthCheckPage){
    $healthCheckPage -match ".+=Failure\s*"
}
Function Test-MatchPackage($healthCheckPage, $config){
    $artifactMatch = $healthCheckPage -match "Name=$($config.packageId)\W"
    $versionMatch = $healthCheckPage -match "Version=$($config.version)\W"
    if(-not ($artifactMatch -and $versionMatch)){
        $false
    } else {
        if(Test-DependencyFailure $healthCheckPage) {
            Write-Warning "Health page reported there are some failures after the deployment!"
        }
        $true
    }
}
Function Test-WebsiteMatch($config){
    Write-Host "Source Package [ $($config.packageId) : $($config.version) ]"
    $webSiteName = $config.siteName
    $healthCheckPath = $config.healthCheckPath
    if(-not(Test-SiteExisted $webSiteName)) {
        $false
    } else {
        $healthCheckUrl = Get-HealthCheckUrl $webSiteName $healthCheckPath
        Write-Host "Target HealthCheckUrl: [$healthCheckUrl]"
        $healthCheckPage = Get-UrlContent $healthCheckUrl
        Write-Host "HealthCheckPage `n$healthCheckPage"
        Test-MatchPackage $healthCheckPage $config
    }
}
