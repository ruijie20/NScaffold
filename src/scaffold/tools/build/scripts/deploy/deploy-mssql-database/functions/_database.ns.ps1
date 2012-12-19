Function Invoke-SqlScript {
	param($server, $file, $variables = @{}, $database ="master")

	$commandLine = "sqlcmd -E -S `"$server`" -d $database -i `"$file`""
	$variables.GetEnumerator() | sort-object -Property Name | % {
		$commandLine += " -v $($_.Key)=`"$($_.Value)`""
	}
	Invoke-Expression $commandLine
	if ($LASTEXITCODE -ne 0) {
	    throw "Error when exec sql command `n$commandLine"
	}
}

Function Remove-Database {
	param($server, $database)

	Invoke-SqlScript -Server $server -File "$scriptDir\drop_db.sql" `
		-Variables @{ DatabaseName = $database }
}

Function Remove-DbLoginUser {
	param($server, $dbLoginUser)

	if($dbLoginUser -like "*\*") {
		$dbLoginUser = Convert-WinNTUsername $dbLoginUser
	}
	Invoke-SqlCommand -server $server -database master -command "DROP LOGIN [$dbLoginUser]"
}

Function New-DBServerLogin {
	param($server, $login, $loginPassword)

	$winntUserName = Convert-WinNTUsername $login
	$username = Get-Username $winntUserName
	if($loginPassword -and (-not (Test-User $username))){
		New-LocalUser $username $loginPassword | Out-Null
        Add-UserIntoGroup $username "IIS_IUSRS"
	}
	
	Invoke-SqlScript -Server $server -File "$scriptDir\create_login.sql" `
		-Variables @{ Name = $winntUserName }	
}

Function Remove-DBServerLogin {
	param($server, $login)

	$winntUserName = Convert-WinNTUsername $login
	Invoke-SqlScript -Server $server -File "$scriptDir\drop_login.sql" `
		-Variables @{ Name = $winntUserName }
}

Function Grant-RWPermissions {
	param($server, $database, $user)

	$winntUserName = Convert-WinNTUsername $user
	Invoke-SqlScript -server $server -file "$scriptDir\give_rw_permissions.sql" `
		-variables @{
			DatabaseName 	= $database
			Username 		= $winntUserName
		}	
}

Function Grant-DBAccess{
	param($server, $dbName, $user, $password)
	$user =	Convert-WinNTUsername $user
	New-DBServerLogin $server $user $password
	New-DatabaseUser $server $dbName $user
	Grant-RWPermissions $server $dbName $user
}

Function New-DatabaseUser {
	param($server, $database, $user)	

	$winntUserName = Convert-WinNTUsername $user
	Invoke-SqlScript -Server $server -File "$scriptDir\create_db_user.sql" `
		-Variables @{ 
			ApplicationDatabaseName = $database
			Name = $winntUserName 
		}
}

Function Add-JobToRebuildIndex {
	param($server, $database)

	Invoke-SqlScript -Server $server -File "$scriptDir\job_to_rebuild_index.sql" `
		-Variables @{ targetDBName = $database }
}

Function Invoke-SqlCommand {
	param($server, $database = "master", $command)

	$commandLine = "sqlcmd -E -S $server -d $database -Q `"$command`""
	
	Invoke-Expression $commandLine
	if ($LASTEXITCODE -ne 0) {
	    throw "Error when exec sql command `n$commandLine"
	}
}

Function Test-DBExisted($server, $database_name) {
	$output = Invoke-SqlCommand -server $server -database master -command "select count(name) from sysdatabases where name='$database_name'"
	return $output[2] -match "1" 
}

Function Test-TableExisted($server, $database_name ,$table_name) {
	$output = Invoke-SqlCommand -server $server -database $database_name -command "select count(name) from sys.tables where name = '$table_name'"
	return $output[2] -match "1" 
}


Function Get-Username ($username) {
    $tmp = $username.split('\')
    if(($tmp.Length -lt 1) -or ($tmp.Length -gt 2)) {
        throw "Parameter(username):$username must be format with 'username' or 'domain\username'!"
    }
    if($tmp.Length -eq 2) {
        $result = $tmp[1]
    }else{
        $result = $username;
    }
    return $result
}
