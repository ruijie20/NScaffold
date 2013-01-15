$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"
$root = "$here\..\..\..\.."
. "$root\src-libs\functions\Merge-Hashtable.ns.ps1"

Describe "Resolve-Varialbes" {

    It "should resolve variables when no place holder is present" {
        $variables = @{
            "apphost" = "hostname:port"
            "hostname" = "localhost"
            "port" = "1234"
        }
        $appliedVarabiles = Resolve-Variables $variables @{}
        $appliedVarabiles.apphost.should.be("hostname:port")
        $appliedVarabiles.hostname.should.be("localhost")
        $appliedVarabiles.port.should.be("1234")
    }

    It "return resolve variables to their values" {
        $variables = @{
            "protocol" = "http://"
            "hostname" = "localhost"
            "port" = "1234"
            "apphost" = "[hostname]:[port]"
            "baseUri" = "[protocol][apphost]/baseUri"
        }
        $appliedVarabiles = Resolve-Variables $variables @{}

        $appliedVarabiles.protocol.should.be("http://")
        $appliedVarabiles.hostname.should.be("localhost")
        $appliedVarabiles.port.should.be("1234")
        $appliedVarabiles.apphost.should.be("localhost:1234")
        $appliedVarabiles.baseUri.should.be("http://localhost:1234/baseUri")
    }


    It "should throw exception when the value of any place holder is not defined." {
        $variables = @{
            "hostname" = "localhost"
            "port" = "1234"
            "apphost" = "[hostname]:[anotherPort]"
        }
        $exceptionThrown = $false;

        try {
            $appliedVarabiles = Resolve-Variables $variables @{}
        } catch {
            $exceptionThrown = $true
        }
        $exceptionThrown.should.be($true)
    }

    It "return resolve variables from the context" {
        $variables = @{
            "k1" = "[v1]"
            "k2" = "[v2]"
            "v2" = 3
        }
        $context = @{
            "v1" = 1
            "v2" = 2
        }
        
        $appliedVarabiles = Resolve-Variables $variables $context

        $appliedVarabiles.Count.should.be(3);
        $appliedVarabiles.k1.should.be(1)
        $appliedVarabiles.k2.should.be(3)
    }
}