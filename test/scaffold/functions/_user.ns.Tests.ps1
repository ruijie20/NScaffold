$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = "$here\..\..\.."

. "$root\src\scaffold\tools\build\scripts\deploy\functions\_user.ns.ps1"

Describe "New-LocalUser" {
    $computerName = $env:computerName
    $computer = [ADSI]"WinNT://$computerName"
    $user = $computer.children.Find("TestUser", "user")
    if($user) {
        $computer.children.Remove($user)
    }
    
    It "should create local user with PasswordExpired false." {
        New-LocalUser -userName "TestUser" -password "special123$"
        
        $user = $computer.children.Find("TestUser", "user")
        $user.InvokeGet("PasswordExpired").Should.Be(0)
    }
}
