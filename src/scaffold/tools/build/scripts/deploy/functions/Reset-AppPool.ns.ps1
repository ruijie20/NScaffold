Function Reset-AppPool($appPoolName, $username, $password, $loadUserProfile){
    $appPoolPath = "IIS:\AppPools\$appPoolName"
    if (-not (Test-Path $appPoolPath)) {
        $appPool = New-WebAppPool $appPoolName
    }

    if (-not $username) {
        Set-ItemProperty $appPoolPath ProcessModel.IdentityType 4
    } else{
        if((-not (Test-IsDomain)) -and (-not (Test-User $username))){
            New-LocalUser $username $password | Out-Null
            Set-LocalGroup $username "IIS_IUSRS" -add
        }
        Write-Host "User [$username] is ready."
        Set-ItemProperty $appPoolPath ProcessModel.Username $username
        Set-ItemProperty $appPoolPath ProcessModel.Password $password
        Set-ItemProperty $appPoolPath ProcessModel.IdentityType 3

        if($loadUserProfile) {
            Set-ItemProperty $appPoolPath ProcessModel.loadUserProfile $loadUserProfile
        }
    }
    Set-ItemProperty $appPoolPath managedRuntimeVersion v4.0
    Set-ItemProperty $appPoolPath -Name recycling.periodicrestart.time -Value 0
    $thirtyDays = [TimeSpan]::FromMinutes(43200)
    Set-ItemProperty $appPoolPath -Name processModel.idleTimeout -Value $thirtyDays
    Write-Host "Application pool [$appPoolName] is ready."
}
