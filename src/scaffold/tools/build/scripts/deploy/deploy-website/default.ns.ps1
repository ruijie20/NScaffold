param($packageRoot, $installArgs)

# import WebAdministration module
if([IntPtr]::size -ne 8){
    throw "'WebAdministration' module can only run in 64 bit powershell"
}
Get-Module -ListAvailable -Name "WebAdministration" | % {
    if(-not(Test-ServiceStatus "W3SVC")) {
        Set-Service -Name WAS -Status Running -StartupType Automatic
        Set-Service -Name W3SVC -Status Running -StartupType Automatic
    }    
    Import-Module WebAdministration
}
$packageInfo = Get-PackageInfo $packageRoot
$webConfigFile = Get-ChildItem $packageRoot -Recurse -Filter "web.config" | select -first 1 
$sourcePath = Split-Path $webConfigFile.FullName -Parent
$packageInfo.Add("sourcePath", $sourcePath)

@{
    'packageInfo' = $packageInfo
    'installAction' = {
        param($config, $packageInfo, $installArgs)
        
        $sourcePath = $packageInfo.sourcePath
        $webSiteName = $config.siteName
        $webSitePath = "IIS:\Sites\$webSiteName"
        $physicalPath = $config.physicalPath

        if(-not (Test-Path $webSitePath)) {
            throw "Website [$webSitePath] does not exists!"
        }

        $tempDir = "$($env:temp)\$((Get-Date).Ticks)"
        New-Item $tempDir -type Directory | Out-Default
        Set-ItemProperty $webSitePath physicalPath $tempDir
        Write-Host "Website [$webSiteName] is ready."
        SLEEP -second 2

        if($sourcePath -ne $physicalPath){
            Clear-Directory $physicalPath | Out-Null
            Copy-Item "$sourcePath\*" -Destination $physicalPath -Recurse
        }    
        Set-ItemProperty $webSitePath physicalPath $physicalPath
        Start-Website $webSiteName
        SLEEP -second 2
        Remove-Item $tempDir -Force -Recurse -ErrorAction SilentlyContinue | Out-Default

        $website = Get-Item $webSitePath

        @{
            "name" = $website.Name
            "bindings" = $website.bindings.collection | % {
                @{
                    'protocol' = $_.protocol
                    'bindingInformation' = $_.bindingInformation
                }
            }
        }
    }
}
