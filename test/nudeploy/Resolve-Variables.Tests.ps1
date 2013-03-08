$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = "$here\..\.."

$configFolder = "$root\test\test-fixtures\resolve-varialbes"

. "$root\src\nudeploy\tools\functions\Resolve-Variables.ps1"
. "$root\src-libs\functions\Merge-Hashtable.ns.ps1"
. "$root\src-libs\functions\Import-Config.ns.ps1"

Describe "Resolve-Varialbes" {
    It "should resolve variables when no place holder is present" {
        $configPath = "$configFolder\no_place_holder.ini"
        $appliedVarabiles = Resolve-Variables $configPath @{}
        $appliedVarabiles.apphost.should.be("hostname:port")
        $appliedVarabiles.hostname.should.be("localhost")
        $appliedVarabiles.port.should.be("1234")
    }

    It "return resolve variables to their values" {
        $configPath = "$configFolder\place_holder_resolve_by_self.ini"
        $appliedVarabiles = Resolve-Variables $configPath @{}

        $appliedVarabiles.protocol.should.be("http://")
        $appliedVarabiles.hostname.should.be("localhost")
        $appliedVarabiles.port.should.be("1234")
        $appliedVarabiles.apphost.should.be("localhost:1234")
        $appliedVarabiles.baseUri.should.be("http://localhost:1234/baseUri")
    }


    It "should throw exception when the value of any place holder is not defined." {
        $configPath = "$configFolder\place_holder_not_def.ini"
        $exceptionThrown = $false;

        try {
            $appliedVarabiles = Resolve-Variables $configPath @{}
        } catch {
            $exceptionThrown = $true
        }
        $exceptionThrown.should.be($true)
    }

    It "return resolve variables from the context" {
        $configPath = "$configFolder\place_holder_resolve_from_content.ini"
        $context = @{
            "v1" = 1
            "v2" = 2
        }
        
        $appliedVarabiles = Resolve-Variables $configPath $context

        $appliedVarabiles.Count.should.be(3);
        $appliedVarabiles.k1.should.be(1)
        $appliedVarabiles.k2.should.be(3)
    }
}