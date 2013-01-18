$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Skip-IfAlreadyDeployed.ps1"
. "$here\Test-ConfigFileEqual.ps1"
. "$here\..\..\..\..\src-libs\functions\Import-Config.ns.ps1"

Function New-TempFile($config){
    $timestamp = (Get-Date).Ticks
    $tempFileName = "$($env:temp)\$timestamp.txt"
    $config.GetEnumerator()| %{ "$($_.key)=$($_.value)" | Out-File $tempFileName -append }
    $tempFileName
}

$appConfig = @{
    env = 'QA'
    server  = "10.18.8.25" 
    package = "TigerUI"
    version = "1.1.1" 
    config  = New-TempFile @{k1 = 'v1'; k2 = 2}
}
$root = "$($env:temp)\Test-AlreadyDeployed"
Describe "Skip-IfAlreadyDeployed" {

    It "should not deploy given this deployment is the same as last one" {
        remove-item $root -recurse -erroraction SilentlyContinue

        Skip-IfAlreadyDeployed $root $appConfig {
        }
 
        $appConfig.config = New-TempFile @{k2 = 2; k1 = ' v1 ';}
        $result = @{}
        $result.deploying = $false
        Skip-IfAlreadyDeployed $root $appConfig {
            $result.deploying = $true
        }
        $result.deploying.should.be($false)
    }

    It "should deploy given there's no deployment before" {
        remove-item $root -recurse -erroraction SilentlyContinue
        $result = @{}
        $result.deploying = $false
        Skip-IfAlreadyDeployed $root $appConfig {
            $result.deploying = $true
        }
        $result.should.be($true)
    }

    Function Assert-DeployWhenEnvIsDifferent($key, $value){
        remove-item $root -recurse -erroraction SilentlyContinue

        Skip-IfAlreadyDeployed $root $appConfig {
            
        }

        $appConfig2 = $appConfig.clone()
        $appConfig2[$key] = $value

        $result = @{}
        $result.deploying = $false
        Skip-IfAlreadyDeployed $root $appConfig2 {
            $result.deploying = $true
        }

        $result.deploying.should.be($true)
    }

    It "should deploy given this deployment does NOT have the same env as last one" {
        Assert-DeployWhenEnvIsDifferent 'env' 'Prod' 
    }

    It "should deploy given this deployment doesn NOT have the same server as last one" {
        Assert-DeployWhenEnvIsDifferent 'server' '192.168.1.102'
    }

    It "should deploy given this deployment doesn NOT have the same app as last one" {
        Assert-DeployWhenEnvIsDifferent 'package' 'TigerAPI'
    }

    It "should deploy given this deployment doesn NOT have the same version as last one" {
        Assert-DeployWhenEnvIsDifferent 'version' '1.1.2'
    }

    It "should deploy given this deployment doesn NOT have the same config as last one" {
        Assert-DeployWhenEnvIsDifferent 'config' (New-TempFile @{k1 = 'v1'; k2 = 2; k3 = 3})
    }

    It "should deploy redeploying a new version" {
        remove-item $root -recurse -erroraction SilentlyContinue

        $appConfig1 = $appConfig.clone()
        $appConfig1.version = "1.1.2"

        $result = @{}
        $result.deploying = $false
        Skip-IfAlreadyDeployed $root $appConfig {
            
        }

        Skip-IfAlreadyDeployed $root $appConfig1 {
            $result.deploying = $true
        }
        $result.deploying.should.be($true)
    }    
    It "skip deployment if it's successfully executed previously" {
        remove-item $root -recurse -erroraction SilentlyContinue
        Skip-IfAlreadyDeployed $root $appConfig {
           
        }

        Skip-IfAlreadyDeployed $root $appConfig {
            throw "should not be here"
        }
    }

    It "should return deploy information regardless whether skipped or not" {
        remove-item $root -recurse -erroraction SilentlyContinue
        $result = Skip-IfAlreadyDeployed $root $appConfig {
            "installed"
        }
        $result.should.be("installed")

        $result = Skip-IfAlreadyDeployed $root $appConfig {
            throw "should not deploy. "
        }
        $result.should.be("installed")
    }

}