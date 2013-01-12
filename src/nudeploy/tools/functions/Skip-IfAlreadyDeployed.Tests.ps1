$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Skip-IfAlreadyDeployed.ps1"

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
Describe "Test-AlreadyDeployed" {

    It "return true given this deployment is the same as last one" {
        remove-item $root -recurse -erroraction SilentlyContinue
        Register-SuccessDeployment $root $appConfig

        $appConfig.config = New-TempFile @{k2 = 2; k1 = ' v1 ';}
        $result = Test-AlreadyDeployed $root $appConfig

        $result.should.be($True)
    }

    It "return false given there's no deployment before" {
        remove-item $root -recurse -erroraction SilentlyContinue
        $result = Test-AlreadyDeployed $root $appConfig

        $result.should.be($False)
    }

    Function Assert-ReturnFalseWhenNewDeploymentHasDifferent($key, $value){
        remove-item $root -recurse -erroraction SilentlyContinue
        Register-SuccessDeployment $root $appConfig

        $appConfig2 = $appConfig.clone()
        $appConfig2[$key] = $value
        $result = Test-AlreadyDeployed $root $appConfig2

        $result.should.be($False)
    }

    It "return false given this deployment doesn NOT have the same env as last one" {
        Assert-ReturnFalseWhenNewDeploymentHasDifferent 'env' 'Prod' 
    }

    It "return false given this deployment doesn NOT have the same server as last one" {
        Assert-ReturnFalseWhenNewDeploymentHasDifferent 'server' '192.168.1.102'
    }

    It "return false given this deployment doesn NOT have the same app as last one" {
        Assert-ReturnFalseWhenNewDeploymentHasDifferent 'package' 'TigerAPI'
    }

    It "return false given this deployment doesn NOT have the same version as last one" {
        Assert-ReturnFalseWhenNewDeploymentHasDifferent 'version' '1.1.2'
    }

    It "return false given this deployment doesn NOT have the same config as last one" {
        Assert-ReturnFalseWhenNewDeploymentHasDifferent 'config' (New-TempFile @{k1 = 'v1'; k2 = 2; k3 = 3})
    }

    It "return false when redeploying a previously deployed version" {
        remove-item $root -recurse -erroraction SilentlyContinue

        $appConfig1 = $appConfig.clone()
        $appConfig1.version = "1.1.2"

        Register-SuccessDeployment $root $appConfig
        Register-SuccessDeployment $root $appConfig1

        $result = Test-AlreadyDeployed $root $appConfig
        $result.should.be($False)
    }
}

Describe "Skip-IfAlreadyDeployed" {
    
    It "skip deployment if it's successfully executed previously" {
        remove-item $root -recurse -erroraction SilentlyContinue
        Skip-IfAlreadyDeployed $root $appConfig $false {
           
        }

        Skip-IfAlreadyDeployed $root $appConfig $false {
            throw "should not be here"
        }
    }
}