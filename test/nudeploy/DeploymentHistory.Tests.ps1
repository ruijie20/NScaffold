$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$prjRoot = "$here\..\.."
. "$prjRoot\src\nudeploy\tools\functions\DeploymentHistory.ps1"
. "$prjRoot\src\nudeploy\tools\functions\Test-ConfigFileEqual.ps1"
. "$prjRoot\src-libs\functions\Import-Config.ns.ps1"

Function New-TempFile($config){
    $timestamp = (Get-Date).Ticks
    $tempFileName = "$($env:temp)\$timestamp.txt"
    $config.GetEnumerator()| %{ "$($_.key)=$($_.value)" | Out-File $tempFileName -append }
    $tempFileName
}

$appConfig = @{
    env = 'QA'
    server  = "10.18.8.25" 
    package = "MyPackageUI"
    version = "1.1.1" 
    config  = New-TempFile @{k1 = 'v1'; k2 = 2}
}
$historyRoot = "$($env:temp)\Test-AlreadyDeployed"
Describe "Load-LastMatchingDeploymentResult" {
    It "should return last deployment result given this deployment is the same as last one" {
        Clear-AllDeploymentHistory($historyRoot)

        $result = @{a = "abc"}
        Save-LastDeploymentResult $historyRoot $appConfig $result
 
        $appConfig2 = $appConfig.clone()
        $appConfig2.config = New-TempFile @{k2 = 2; k1 = ' v1 ';}
        $historyResult = Load-LastMatchingDeploymentResult $historyRoot $appConfig2

        $historyResult.keys.should.be(@('a'))
        $historyResult.a.should.be($result.a)
    }

    It "should return empty given there's no deployment before" {
        Clear-AllDeploymentHistory($historyRoot)

        $historyResult = Load-LastMatchingDeploymentResult $historyRoot $appConfig

        if($historyResult) {
            throw "Expect no history result.but got $historyResult"
        }
    }

    Function Assert-LoadNoHistoryFor($key, $value){
        Clear-AllDeploymentHistory($historyRoot)

        $result = @{a = "abc"}
        Save-LastDeploymentResult $historyRoot $appConfig $result

        $appConfig2 = $appConfig.clone()
        $appConfig2[$key] = $value

        $historyResult = Load-LastMatchingDeploymentResult $historyRoot $appConfig2
        if($historyResult) {
            throw "Expect no history result.but got $historyResult"
        }
    }

    It "should return no history when this deployment does NOT have the same env as last one" {
        Assert-LoadNoHistoryFor 'env' 'Prod' 
    }

    It "should return no history when this deployment doesn NOT have the same server as last one" {
        Assert-LoadNoHistoryFor 'server' '192.168.1.102'
    }

    It "should return no history when this deployment doesn NOT have the same app as last one" {
        Assert-LoadNoHistoryFor 'package' 'MyPackageAPI'
    }

    It "should return no history when this deployment doesn NOT have the same version as last one" {
        Assert-LoadNoHistoryFor 'version' '1.1.2'
    }

    It "should return no history when this deployment doesn NOT have the same config as last one" {
        Assert-LoadNoHistoryFor 'config' (New-TempFile @{k1 = 'v1'; k2 = 2; k3 = 3})
    }

    It "should return the result of the new version after redeploying a new version" {
        Clear-AllDeploymentHistory($historyRoot)

        $result = @{a = "abc"}
        Save-LastDeploymentResult $historyRoot $appConfig $result
 
        $appConfig2 = $appConfig.clone()
        $appConfig2.version = "1.1.2"
        Save-LastDeploymentResult $historyRoot $appConfig2 @{a = "new"}

        $historyResult = Load-LastMatchingDeploymentResult $historyRoot $appConfig
        if($historyResult) {
            throw "Expect no history result.but got $historyResult"
        }
    }    
}