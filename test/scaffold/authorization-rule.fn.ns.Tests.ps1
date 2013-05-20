$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = "$here\..\.."
$tmp = "$root\tmp"
New-Item $tmp -Type Directory -ErrorAction SilentlyContinue|out-default
$tmp = resolve-path $tmp
$fixtures = "$TestDrive\test-fixtures"
. "$root\src\scaffold\tools\build\scripts\deploy\functions\_user.ns.ps1"
. "$root\src\scaffold\tools\build\scripts\deploy\functions\ConvertTo-NameInfo.ns.ps1"
try{
    . "$root\src\scaffold\tools\build\scripts\deploy\deploy-website\authorization-rule.ns.ps1" -installAction {}    
} catch{

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