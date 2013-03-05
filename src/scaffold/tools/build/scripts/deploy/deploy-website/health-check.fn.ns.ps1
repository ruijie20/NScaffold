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
Function Test-MatchPackage($healthCheckPage, $packageInfo){
    $artifactMatch = $healthCheckPage -match "Name=$($packageInfo.packageId)\W"
    $versionMatch = $healthCheckPage -match "Version=$($packageInfo.version)\W"
    if(-not ($artifactMatch -and $versionMatch)){
        $false
    } else {
        if(Test-DependencyFailure $healthCheckPage) {
            Write-Warning "Health page reported there are some failures after the deployment!"
        }
        $true
    }
}
Function Test-WebsiteMatch($config, $packageInfo){
    Write-Host "Source Package [ $($packageInfo.packageId) : $($packageInfo.version) ]"
    $webSiteName = $config.siteName
    $healthCheckPath = $config.healthCheckPath
    if(-not(Test-SiteExisted $webSiteName)) {
        $false
    } else {
        $healthCheckUrl = Get-HealthCheckUrl $webSiteName $healthCheckPath
        Write-Host "Target HealthCheckUrl: [$healthCheckUrl]"
        $healthCheckPage = Get-UrlContent $healthCheckUrl
        Write-Host "HealthCheckPage `n$healthCheckPage"
        Test-MatchPackage $healthCheckPage $packageInfo
    }
}
