$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

Describe "Resolve-Varialbes" {

    It "should resolve variables when no place holder is present" {
        Setup -File "testconfig.ini" "apphost = hostname:port"
        $variables = @{
            "apphost" = "hostname:port"
            "hostname" = "localhost"
            "port" = "1234"
        }
        $appliedVarabiles = Resolve-Variables $variables
        $appliedVarabiles.should.equal(@{
            "apphost" = "hostname:port"
            "hostname" = "localhost"
            "port" = "1234"
        })
    }

    It "return resolve variables to their values" {
        Setup -File "testconfig.ini" "apphost = [hostname]:[port]"
        $variables = @{
            "protocol" = "http://"
            "hostname" = "localhost"
            "port" = "1234"
            "apphost" = "[hostname]:[port]"
            "baseUri" = "[protocol][apphost]/baseUri"
        }
        $appliedVarabiles = Resolve-Variables $variables
        $appliedVarabiles.should.equal(@{
            "protocol" = "http://"
            "hostname" = "localhost"
            "port" = "1234"
            "apphost" = "localhost:1234"
            "baseUri" = "http://localhost:1234/baseUri"
        })

    }


    It "should throw exception when the value of any place holder is not defined." {
        $variables = @{
            "hostname" = "localhost"
            "port" = "1234"
            "apphost" = "[hostname]:[anotherPort]"
        }
        $exceptionThrown = $false;

        try {
            $appliedVarabiles = Resolve-Variables $variables
        } catch {
            $exceptionThrown = $true
        }
        $exceptionThrown.should.Be($true)
    }

}