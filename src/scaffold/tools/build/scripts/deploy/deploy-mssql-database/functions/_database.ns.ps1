$here = $MyInvocation.MyCommand.Path | Split-Path -Parent
$scriptDir = "$here\db-scripts"
Function Invoke-SqlScript {
	param($server, $file, $variables = @{}, $database ="master")

	$commandLine = "sqlcmd -E -S `"$server`" -d $database -i `"$file`""
	$variables.GetEnumerator() | sort-object -Property Name | % {
		$commandLine += " -v $($_.Key) = `"$($_.Value)`""
	}
	Invoke-Expression $commandLine | Out-Default
	if ($LASTEXITCODE -ne 0) {
	    throw "Error when exec sql command `n$commandLine"
	}
}

Function Remove-Database {
	param($server, $database)

	Invoke-SqlScript -Server $server -File "$scriptDir\drop_db.ns.sql" `
		-Variables @{ DatabaseName = $database }
}

Function Remove-DbLoginUser {
	param($server, $dbLoginUser)

	if($dbLoginUser -like "*\*") {
		$dbLoginUser = Convert-WinNTUsername $dbLoginUser
	}
	Invoke-SqlCommand -server $server -database master -command "DROP LOGIN [$dbLoginUser]" | Out-Default
}

Function New-DBServerLogin {
	param($server, $winntUserName, $loginPassword)

	$username = Get-Username $winntUserName
	if($loginPassword -and (-not (Test-User $username))){
		New-LocalUser $username $loginPassword | Out-Null
		Set-LocalGroup $username "IIS_IUSRS" -add
	}
	
	Invoke-SqlScript -Server $server -File "$scriptDir\create_login.ns.sql" `
		-Variables @{ Name = $winntUserName }	
}

Function Remove-DBServerLogin {
	param($server, $login)

	$winntUserName = Convert-WinNTUsername $login
	Invoke-SqlScript -Server $server -File "$scriptDir\drop_login.ns.sql" `
		-Variables @{ Name = $winntUserName }
}

Function Grant-RWPermissions {
	param($server, $database, $winntUserName)
	Invoke-SqlScript -server $server -file "$scriptDir\give_rw_permissions.ns.sql" `
		-variables @{
			DatabaseName 	= $database
			Username 		= $winntUserName
		}	
}

Function Grant-DBAccess{
	param($server, $dbName, $username)
    Invoke-SqlScript -Server $server -File "$scriptDir\create_login.ns.sql" -Variables @{ Name = $username }
    New-DatabaseUser $server $dbName $username
    Grant-RWPermissions $server $dbName $username
}

Function New-DatabaseUser {
	param($server, $database, $winntUserName)
	Invoke-SqlScript -Server $server -File "$scriptDir\create_db_user.ns.sql" `
		-Variables @{ 
			ApplicationDatabaseName = $database
			Name = $winntUserName 
		}
}

Function Add-JobToRebuildIndex {
	param($server, $database)

	Invoke-SqlScript -Server $server -File "$scriptDir\job_to_rebuild_index.ns.sql" `
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
