param($sourcePath, $config)

$root = $MyInvocation.MyCommand.Path | Split-Path -Parent

# include libs
Get-ChildItem "$root\libs" -Filter *.ps1 -Recurse | 
    ? { -not ($_.Name.Contains(".Tests.")) } | % {
        . $_.FullName
    }    
# include functions
. PS-Require ".\functions"

if([IntPtr]::size -ne 8){
    throw "this script can not run in a $expected bit powershell";
}
# import WebAdministration module
Get-Module -ListAvailable -Name "WebAdministration" | % {
    Import-Module WebAdministration
}

Function Invoke-WebSiteDeploymentProcedure($webSiteName, $packageRoot, $LoadBalancerPollingDurationInSeconds, $scriptBlockForDeployment, $healthCheckPath){
    if(Test-WebsiteMatch -webSiteName $webSiteName -PackageRoot $packageRoot -healthCheckPath $healthCheckPath){
        Trace-ProgressMsg "Website [$webSiteName] already deployed to target version. Skip deployment."
        Add-ToLoadBalancer $webSiteName
        return
    }

    Suspend-Website -webSiteName $webSiteName `
        -loadBalancerPollingDurationInSeconds $LoadBalancerPollingDurationInSeconds `
        -scriptBlockDuringSuspension {        
            & $scriptBlockForDeployment
            Assert-WebsiteMatch -webSiteName $webSiteName -PackageRoot $packageRoot -healthCheckPath $healthCheckPath
        }
}

Function Install-ToWebsite($sourcePath, $iisConfig) {
    if((-not $sourcePath) -or (-not $iisConfig)){
        throw "Parameters Could Not Null!"
    }
    Trace-ProgressMsg "Install-ToWebsite from $sourcePath to site:"
    Write-Hashtable $iisConfig

    $webSiteName = $iisConfig.SiteName
    $physicalPath = $iisConfig.PhysicalPath
    $appPoolName = $iisConfig.AppPoolName
    $appPoolUser = $iisConfig.AppPoolUser
    $appPoolPassword = $iisConfig.AppPoolPassword
    $webSitePath = "IIS:\Sites\$webSiteName"
    $appPoolPath = "IIS:\AppPools\$appPoolName"

    $canCreateWebsite = [Boolean] $iisConfig.Port
    $canCreateAppPool = [Boolean] $appPoolUser -and [Boolean] $appPoolPassword
    
    if(-not $iisConfig.SiteName){
        throw "Parameter(iisConfig.siteName) Could Not Null!"
    }
    if(-not $iisConfig.PhysicalPath){
        throw "Parameter(iisConfig.physicalPath) Could Not Null!"
    }

    if(-not $iisConfig.AppPoolName) {
        throw "Parameter(iisConfig.appPoolName) Could Not Null!"
    }

    if((-not (Test-Path $webSitePath)) -and (-not $canCreateWebsite)) {
        throw "Website [$webSiteName] does not exist. In order to create the website, specify the Parameter(iisConfig.port)!"
    }
    
    if(-not (Test-Path $appPoolPath) -and (-not $canCreateAppPool)) {
        throw "AppPool [$appPoolName] does not exist. In order to create the app pool, specify the Parameter(iisConfig.AppPoolUser and iisConfig.AppPoolPassword)!"
    }

    Trace-Progress "Deploy website $webSiteName" {
        if ($appPoolUser -and (-not (Test-UserExist $appPoolUser))) {
            New-LocalUser $appPoolUser $appPoolPassword | Out-Null
            Add-UserIntoGroup $appPoolUser "IIS_IUSRS"
            Trace-ProgressMsg "User [$appPoolUser] is ready."
        }

        $appPoolPath = "IIS:\AppPools\$appPoolName"
        Reset-AppPool $appPoolName $appPoolUser $appPoolPassword
        
        Trace-ProgressMsg "Application pool [$appPoolName] is ready."

        $tempDir = "$($env:temp)\$((Get-Date).Ticks)"
        New-Item $tempDir -type Directory | Out-Null

        if(-not (Test-Path $webSitePath)) {
            New-Website -Name $webSiteName -Port $iisConfig.Port -PhysicalPath $tempDir | Out-Null
        } else {
            Assert-SuspendedFromLoadBalancer $webSiteName
        }
        Trace-ProgressMsg "Website [$webSiteName] is ready."

        if($sourcePath -ne $physicalPath){
            Set-ItemProperty $webSitePath physicalPath $tempDir
            SLEEP -second 2
            Remove-IfExist $physicalPath 
            Copy-Item $sourcePath -destination $physicalPath -recurse
        }
        Set-ItemProperty $webSitePath physicalPath $physicalPath
        Set-ItemProperty $webSitePath applicationPool $appPoolName
        Start-Website $webSiteName

        SLEEP -second 2
        Remove-Item $tempDir -force -recurse -ErrorAction SilentlyContinue | Out-Null
    }
}

Function Install-WebApplication($sourcePath, $iisConfig){
    $appPoolName = $iisConfig.AppPoolName
    $webSiteName = $iisConfig.SiteName
    $alias       = $iisConfig.Alias
    $physicalPath = $iisConfig.PhysicalPath
    $applicationPath = "IIS:\Sites\$webSiteName\$alias"
    $webSitePath = "IIS:\Sites\$webSiteName"
    $appPoolPath = "IIS:\AppPools\$appPoolName"

    if((-not $sourcePath) -or (-not $iisConfig)){
        throw "Parameters Could Not Null!"
    }
    if(-not $webSiteName){
        throw "Parameter(iisConfig.siteName) Could Not Null!"
    }
    if(-not $alias){
        throw "Parameter(iisConfig.alias) Could Not Null!"
    }
    if(-not $physicalPath){
        throw "Parameter(iisConfig.physicalPath) Could Not Null!"
    }

    if(-not $appPoolName) {
        throw "Parameter(iisConfig.appPoolName) Could Not Null!"
    }

    if(-not (Test-Path $appPoolPath)) {
        throw "AppPool:$appPoolName is not exist,Please create AppPool before deploy Application!"
    }

    if (-not (Test-Path $webSitePath)){
         throw "Website:$webSiteName is not exist,Please create Website before deploy Application!"
    }
    Trace-ProgressMsg "Install-WebApplication from $sourcePath to site:"
    Write-Hashtable $iisConfig

    Assert-SuspendedFromLoadBalancer $webSiteName

    Trace-Progress "Deploy web application $webSiteName\$Alias" {
        if (-not (Test-Path $applicationPath)) {
            New-WebApplication -Name $alias -Site $webSiteName | Out-Null
        }
        if($sourcePath -ne $physicalPath){
            Set-ItemProperty $applicationPath physicalPath "c:\notexistfolder"
            SLEEP -second 2
            Remove-IfExist $physicalPath 
            Copy-Item $sourcePath -destination $physicalPath -recurse
        }
        Set-ItemProperty $applicationPath physicalPath $physicalPath
        Set-ItemProperty $applicationPath applicationPool $appPoolName
        Start-Website $webSiteName   
    }
}

# ========================= app pool ============================
Function Reset-AppPool($appPoolName, $username, $password){
    if(-not $appPoolName){
        throw "Parameter(appPoolName) Could Not Null!"
    }
    if($username -and (-not $password)){
        throw "Parameter(password) Could Not Null When Provide Parameter(username)!"
    }
    if($username -and (-not (Test-UserExist $username))) {
        throw "User:$username is not exist,Please create User before prepare appPool!"
    }
    Trace-Progress "Reset-AppPool" {
        $appPoolPath = "IIS:\AppPools\$appPoolName"
        if(-not(Test-IISServiceStatus)) {
            Start-IISServices
        }
        if ((Test-Path $appPoolPath) -eq $false) {
            New-WebAppPool $appPoolName | Out-Null
            Set-ItemProperty $appPoolPath ProcessModel.IdentityType 2
        }
        if($username -ne $null){
            Set-ItemProperty $appPoolPath ProcessModel.Username $username
            Set-ItemProperty $appPoolPath ProcessModel.Password $password
            Set-ItemProperty $appPoolPath ProcessModel.IdentityType 3
        }
        Set-ItemProperty $appPoolPath managedRuntimeVersion v4.0
    }
}

Function Test-IISServiceStatus {
    Test-ServiceStatus "W3SVC"
}

# ========================= misc ============================
Function Reset-WebVirtualDirectory($dirName, $deployPath, $webSiteName = "Default Web Site"){
    Trace-Progress "Reset-WebVirtualDirectory: $dirName" {  
        $webSitePath = "IIS:\Sites\$webSiteName\$dirName"
        if (Test-Path $webSitePath) {Remove-Item $webSitePath -r} 
        New-WebVirtualDirectory -Name $dirName -Site $webSiteName -PhysicalPath $deployPath | Out-Null
    }
}

Function Start-IISServices($name) {
    Set-Service -Name WAS -Status Running -StartupType Automatic
    Set-Service -Name W3SVC -Status Running -StartupType Automatic
}

Function Test-Website($websiteName) {
    Test-Path "IIS:\Sites\$websiteName"
}
