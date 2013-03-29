Function Config-Authorization($webSiteName, $appPoolUser) {
	appcmd clear config "$webSiteName" /section:system.webServer/security/authorization
	appcmd set config "$webSiteName" /section:system.webServer/security/authorization /-"[roles='',users='*',verbs='']" 
	appcmd set config "$webSiteName" /section:system.webServer/security/authorization /+"[accessType='Allow',roles='$appPoolUser-group,services-group']"
	
	appcmd clear config "$webSiteName/health" /section:system.webServer/security/authorization /COMMIT:$webSiteName
	appcmd set config "$webSiteName/health" /section:system.webServer/security/authorization /+"[accessType='Allow',users='?']" /COMMIT:$webSiteName
	appcmd clear config "$webSiteName/ready.txt" /section:system.webServer/security/authorization /COMMIT:$webSiteName
	appcmd set config "$webSiteName/ready.txt" /section:system.webServer/security/authorization /+"[accessType='Allow',users='?']" /COMMIT:$webSiteName
}