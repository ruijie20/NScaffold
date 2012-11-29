$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

Describe "Apply-Variables" {
    Setup -File "testconfig.ini" "apphost = [hostname]:[port]"

    It "return apply config with variables" {
        $variables = @{
            hostname = "localhost"
            port = "1234"
        }
        "TestDrive:\testconfig.ini".Should.Exist()
#        $reslut = Apply-Variables $variables "TestDrive:\testconfig.ini"
#        $content = Get-Content $reslut
#        $content.Should.Be('apphost = localhost:1234')

    }

    It "xxx" {
        "TestDrive:\testconfig.ini".Should.Exist()
        "1".Should.Be("0")
    }
}