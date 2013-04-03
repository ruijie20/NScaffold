Import-Module Webadministration

Function Config-Authorization($webSiteName, $authorizedUsers) {
	Install-WindowsAuthentication
	Install-UrlAuthorization
	Enable-WindowsAuthentication $webSiteName
	if($authorizedUsers){
		Check-IfUserExists $authorizedUsers
		Config-UrlAuthorization $webSiteName $authorizedUsers
	}
}

Function Config-UrlAuthorization($webSiteName, $authorizedUsers) {
	$appcmd = "$env:windir\System32\inetsrv\appcmd.exe"
	& $appcmd clear config "$webSiteName" /section:system.webServer/security/authorization
	& $appcmd set config "$webSiteName" /section:system.webServer/security/authorization /-"[roles='',users='*',verbs='']" 
	& $appcmd set config "$webSiteName" /section:system.webServer/security/authorization /+"[accessType='Allow',users='$authorizedUsers']"

	& $appcmd clear config "$webSiteName/health" /section:system.webServer/security/authorization /COMMIT:$webSiteName
	& $appcmd set config "$webSiteName/health" /section:system.webServer/security/authorization /+"[accessType='Allow',users='?']" /COMMIT:$webSiteName
	& $appcmd clear config "$webSiteName/ready.txt" /section:system.webServer/security/authorization /COMMIT:$webSiteName
	& $appcmd set config "$webSiteName/ready.txt" /section:system.webServer/security/authorization /+"[accessType='Allow',users='?']" /COMMIT:$webSiteName
}

Function Enable-WindowsAuthentication($webSiteName) {
	Set-WebConfigurationProperty -Filter /system.webServer/security/authentication/windowsAuthentication -name enabled -value true -location "$webSiteName"
}

Function Install-WindowsAuthentication() {
	Install-WindowsFeature "Web-Windows-Auth"
	Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/windowsAuthentication -name enabled -value false
}

Function Install-UrlAuthorization() {
	Install-WindowsFeature "Web-Url-Auth"
}

Function Check-IfUserExists($authorizedUsers) {
	$userList = $authorizedUsers.Split(",")
	$userList | %{
		$user = ConvertTo-NameInfo $_.trim()
		$existed = Test-DomainUser $user.prefix $user.name
		if(-not $existed) {
			throw "User $_ not exist!"
		}
	}
}