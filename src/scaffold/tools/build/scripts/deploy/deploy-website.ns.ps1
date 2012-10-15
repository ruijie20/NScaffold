# this script should be invoked under the root directory of the package. 
# $configFile will override the default settings of .\config.ini 
# the responsibility of install.ps1 is to provide $applyConfig, 
# so that the package could be configed properly before installed

# $env.ps1 need define function Install-Website to take the installAction
param($env="dev", $sourcePath="WebSite", $configFile, [ScriptBlock] $applyConfig)

$packageRoot = (Get-Location).ProviderPath
$root = $MyInvocation.MyCommand.Path | Split-Path -Parent
$folderName = ($MyInvocation.MyCommand.Path | Split-Path -Leaf).TrimEnd(".ns.ps1")

# include libs
Get-ChildItem "$root\libs" -Filter *.ps1 -Recurse | 
    ? { -not ($_.Name.Contains(".Tests.")) } | % {
        . $_.FullName
    }

# include functions
. PS-Require ".\functions"
. PS-Require "$root\functions"

if([IntPtr]::size -ne 8){
    throw "'WebAdministration' module can only run in 64 bit powershell"
}

Function Get-PackageInfo ($packageRoot) {
    $packageDirName = Split-Path $packageRoot -Leaf
    if($packageDirName -match "(?<id>.+?)\.(?<version>(?:\d+\.)*\d(?:-(?:\w|-)*)?)") {
        @{
            'packageId' = $matches.id
            'version' = $matches.version
        }        
    } else {
        @{
            'packageId' = $packageDirName
        }
    }
}

Function Generate-Config ($packageRoot, $packageId) {
    @{
        'siteName' = "$packageId-site"
        'physicalPath' = "$packageRoot\$sourcePath"
        'appPoolName' = "$packageId-app"
        'appPoolUser' = "$packageId-user"
        'appPoolPassword' = "$packageId-password"
    }
}

$packageInfo = Get-PackageInfo $packageRoot

# get config
$config = Import-Config $configFile | 
    Patch-Config -p (Import-Config ".\config.ini") |
    Patch-Config -p (Generate-Config $packageRoot $packageInfo.packageId)

# verify config
$webSiteName = $config.SiteName
$appPoolName = $config.AppPoolName
$webSitePath = "IIS:\Sites\$webSiteName"
$appPoolPath = "IIS:\AppPools\$appPoolName"

if((-not (Test-Path $webSitePath)) -and (-not $config.Port)) {
    throw "Website [$webSiteName] does not exist. In order to create new website, specify the port!"
}

if(-not (Test-Path $appPoolPath) -and (-not ($config.appPoolUser -and $config.appPoolPassword))) {
    throw "AppPool [$appPoolName] does not exist. In order to create the app pool, specify the AppPoolUser and AppPoolPassword!"
}


# import WebAdministration module
Get-Module -ListAvailable -Name "WebAdministration" | % {
    Import-Module WebAdministration
}

if($applyConfig){
    & $applyConfig
}

# nupkg folder (?<id>.+?)\.(?<version>(?:\d+\.)*\d(?:-(?:\w|-)*)?)
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
        if(-not(Test-ServiceStatus "W3SVC")) {
            Set-Service -Name WAS -Status Running -StartupType Automatic
            Set-Service -Name W3SVC -Status Running -StartupType Automatic
        }
        if (-not (Test-Path $appPoolPath)) {
            New-WebAppPool $appPoolName | Out-Null
            Set-ItemProperty $appPoolPath ProcessModel.IdentityType 2
        }
        if(-not $username){
            Set-ItemProperty $appPoolPath ProcessModel.Username $username
            Set-ItemProperty $appPoolPath ProcessModel.Password $password
            Set-ItemProperty $appPoolPath ProcessModel.IdentityType 3
        }
        Set-ItemProperty $appPoolPath managedRuntimeVersion v4.0
    }
}

Function Test-ServiceStatus($name, $status="Running") {
    (Get-Service -Name $name | ? {$_.Status -eq $status} | Measure-Object).Count -eq 1
}

Import-Module . "$folderName\$env.psm"    
Install-Website $config.WebsiteName $packageRoot {
    Install-ToWebsite $sourcePath, $config
}
