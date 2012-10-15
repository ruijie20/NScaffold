Function Reset-AppPool($appPoolName, $username, $password){
    $appPoolPath = "IIS:\AppPools\$appPoolName"
    if (Test-Path $appPoolPath) {
        Remove-WebAppPool $appPoolName
    }
    if(Test-UserExist $username){
        Remove-LocalUser $username
    }

    New-LocalUser $appPoolUser $appPoolPassword | Out-Null
    Set-LocalGroup $appPoolUser "IIS_IUSRS" -add
    Write-Debug "User [$appPoolUser] is ready."
    
    $appPool = New-WebAppPool $appPoolName
    Set-ItemProperty $appPoolPath ProcessModel.Username $username
    Set-ItemProperty $appPoolPath ProcessModel.Password $password
    Set-ItemProperty $appPoolPath ProcessModel.IdentityType 3
    Write-Debug "Application pool [$appPoolName] is ready."
}
