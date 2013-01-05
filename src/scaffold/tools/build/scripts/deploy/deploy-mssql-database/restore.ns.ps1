param($config, $packageInfo, $installArgs, [ScriptBlock] $installAction)
Write-Host "Clean database" -f green

$dir = $MyInvocation.MyCommand.Path | Split-Path -Parent
$scriptDir = "$dir\functions\db-scripts"
Remove-Database -server $config.server -database $config.dbName

if(-not (Test-DBExisted $config.server $config.dbName)){
	Write-Host  "Restore database [$($config.dbName)]" -f green
	Invoke-SqlCommand -server $config.server -command "CREATE DATABASE [$($config.dbName)]"	
    if ($installArgs.baseline) {
        Invoke-SqlScript -server $config.server -database $config.dbName -file "$($installArgs.baseline)"
    }
    else {
        Write-Host  "No baseline schema. Restore baseline skiped." -f green
    }
}



if($config.userName){
    if ($config.userName -like '*IIS AppPool*') {
        Import-Module WebAdministration
    }
	$config.userName.Split(",") | % { 
        ConvertTo-NameInfo $_.trim()
    } | % { 
        if ($_.prefix -eq $env:COMPUTERNAME) {
            if($config.password -and (-not (Test-User $_.name))){
                New-LocalUser $_.name $config.password | Out-Null
                Set-LocalGroup $_.name "IIS_IUSRS" -add
            }
        }
        if ($_.prefix -eq "IIS AppPool") {
            $appPoolPath = "IIS:\AppPools\$($_.name)"
            if (-not (Test-Path $appPoolPath)) {
                New-WebAppPool $_.name
                Set-ItemProperty $appPoolPath ProcessModel.IdentityType 4
            }
        }
        Grant-DBAccess $config.server $config.dbName "$($_.prefix)\$($_.name)"
    }
}

& $installAction