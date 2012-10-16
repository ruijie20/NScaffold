Function Reset-AppPool($appPoolName, $username, $password){
    $appPoolPath = "IIS:\AppPools\$appPoolName"
    if(-not (Test-User $username)){
        New-LocalUser $username $appPoolPassword | Out-Null
        Set-LocalGroup $username "IIS_IUSRS" -add
    }    
    Write-Host "User [$username] is ready."

    if (-not (Test-Path $appPoolPath)) {
        $appPool = New-WebAppPool $appPoolName        
    }

    Set-ItemProperty $appPoolPath ProcessModel.Username $username
    Set-ItemProperty $appPoolPath ProcessModel.Password $password
    Set-ItemProperty $appPoolPath ProcessModel.IdentityType 3
    Set-ItemProperty $appPoolPath managedRuntimeVersion v4.0
    Write-Host "Application pool [$appPoolName] is ready."
}
