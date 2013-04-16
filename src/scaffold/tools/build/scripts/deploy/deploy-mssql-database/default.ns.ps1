param($packageRoot, $installArgs)

$packageInfo = Get-PackageInfo $packageRoot

@{
    'packageInfo' = $packageInfo
    'installAction' = {
        param($config, $packageInfo, $installArgs)

        if(-not (Test-DBExisted $config.server $config.dbName)){
            Write-Host  "Create database [$($config.dbName)]" -f green
            Invoke-SqlCommand -server $config.server -command "CREATE DATABASE [$($config.dbName)]" 
            if ($installArgs.baseline) {
                Invoke-SqlScript -server $config.server -database $config.dbName -file "$($installArgs.baseline)"
            }
            else {
                Write-Host  "No baseline schema. Restore baseline skiped." -f green
            }
        }

        if($installArgs.migrate){
            Run-Closure $installArgs.migrate $config | Out-Default
        } else{
            throw "Please specify migrate action in installArgs as closure. "
        }

        if($config.userName){
            Write-Host  "Processing DB user access" -f green
            if ($config.userName -like '*IIS AppPool*') {
                Import-Module WebAdministration
            }
            $config.userName.Split(",") | % { 
                ConvertTo-NameInfo $_.trim()
            } | % {
                $winUserPrefix = $_.prefix
                $winUserName = $_.name
                $isVirtualAccount = $winUserPrefix -eq "IIS AppPool"
                if ($isVirtualAccount) {
                    $appPoolPath = "IIS:\AppPools\$winUserName"
                    if (-not (Test-Path $appPoolPath)) {
                        New-WebAppPool $winUserName
                        Set-ItemProperty $appPoolPath ProcessModel.IdentityType 4
                    }
                } else{
                    if($config.password -and ($winUserPrefix -eq $env:COMPUTERNAME)){
                        if (-not (Test-DomainUser $winUserPrefix $winUserName)) {
                            New-LocalUser $winUserName $config.password | Out-Null
                            Set-LocalGroup $winUserName "IIS_IUSRS" -add
                        }
                    }
                    if (-not (Test-DomainUser $winUserPrefix $winUserName)) {
                        throw "Error: Windows user $($winUserPrefix)\$winUserName not found. Check the name again."
                    }
                }
                Grant-DBAccess $config.server $config.dbName "$($winUserPrefix)\$winUserName"
            }
        }
    }
    'export' = {
        param($config, $packageInfo, $installArgs)
        @{
            'server' = $config.server 
            'dbName' = $config.dbName
        }
    }
}
