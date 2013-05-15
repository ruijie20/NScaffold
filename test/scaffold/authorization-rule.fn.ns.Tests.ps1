$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = "$here\..\.."
$tmp = "$root\tmp"
New-Item $tmp -Type Directory -ErrorAction SilentlyContinue|out-default
$tmp = resolve-path $tmp
$fixtures = "$TestDrive\test-fixtures"
. "$root\src\scaffold\tools\build\scripts\deploy\functions\Install-WindowsFeature.ns.ps1"
. "$root\src\scaffold\tools\build\scripts\deploy\functions\_user.ns.ps1"
. "$root\src\scaffold\tools\build\scripts\deploy\functions\ConvertTo-NameInfo.ns.ps1"
. "$root\src\scaffold\tools\build\scripts\deploy\deploy-website\authorization-rule.fn.ns.ps1"

Import-Module Servermanager
Import-Module Webadministration

Describe "Install Windows Authentication" {

    It "should success when install windows authentication" {
        Remove-WindowsFeature "Web-Windows-Auth"
        (Get-WindowsFeature "Web-Windows-Auth").Installed.should.be($False)
		
    	Install-WindowsAuthentication
        (Get-WindowsFeature "Web-Windows-Auth").Installed.should.be($True)
        $iisWindowsAuthenticationEnabled = (Get-WebConfigurationProperty -filter /system.WebServer/security/authentication/windowsAuthentication -name enabled).Value
        $iisWindowsAuthenticationEnabled.should.be($False)

    	Install-WindowsAuthentication
        (Get-WindowsFeature "Web-Windows-Auth").Installed.should.be($True)
        $iisWindowsAuthenticationEnabled = (Get-WebConfigurationProperty -filter /system.WebServer/security/authentication/windowsAuthentication -name enabled).Value
        $iisWindowsAuthenticationEnabled.should.be($False)
    }

    It "should ensure windows authentication disabled when reinstall windows authentication" {
    	Install-WindowsAuthentication
        (Get-WindowsFeature "Web-Windows-Auth").Installed.should.be($True)
        $iisWindowsAuthenticationEnabled = (Get-WebConfigurationProperty -filter /system.WebServer/security/authentication/windowsAuthentication -name enabled).Value
        $iisWindowsAuthenticationEnabled.should.be($False)
        
    	Set-WebConfigurationProperty -filter /system.WebServer/security/authentication/windowsAuthentication -name enabled -value false
        Install-WindowsAuthentication
        (Get-WindowsFeature "Web-Windows-Auth").Installed.should.be($True)
        $iisWindowsAuthenticationEnabled = (Get-WebConfigurationProperty -filter /system.WebServer/security/authentication/windowsAuthentication -name enabled).Value
        $iisWindowsAuthenticationEnabled.should.be($False)
    }

}

Describe "Install Url Authorization" {

    It "should success when install url authorization" {
        Remove-WindowsFeature "Web-Url-Auth"
        (Get-WindowsFeature "Web-Url-Auth").Installed.should.be($False)
        
        Install-UrlAuthorization
        (Get-WindowsFeature "Web-Url-Auth").Installed.should.be($True)
    }
}

Describe "Check IfUserExists" {
	It "should throw exception when users not exist." {
        try{
            iex "net user testUser /add" | out-null
            iex "net user testUser1 /add" | out-null
            Check-IfUserExists "$env:UserDomain\testUser3, $env:UserDomain\testUser1"
            $True.should.be($False)
        }catch{
            $exceptionMessage = $_.Exception.Message
        }finally{
            iex "net user testUser /delete" | out-null
            iex "net user testUser1 /delete" | out-null
        }
        $exceptionMessage.should.be("User $env:UserDomain\testUser3 not exist!")
    }

    It "should success when users all exist." {
        try{
            iex "net user testUser /add" | out-null
            iex "net user testUser1 /add" | out-null
            Check-IfUserExists "$env:UserDomain\testUser, $env:UserDomain\testUser1"
        }catch{
            $True.should.be($False)
        }finally{
            iex "net user testUser /delete" | out-null
            iex "net user testUser1 /delete" | out-null
        }
    }
}