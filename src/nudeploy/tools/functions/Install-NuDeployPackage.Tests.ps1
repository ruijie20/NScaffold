$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = "$here\..\..\..\.."
$nugetExe = "$root\tools\nuget\NuGet.exe"
$fixturesTemplate = "$root\test\config-fixtures"
$fixtures = "$TestDrive\config-fixtures"
$nugetRepo = "$fixtures\nugetRepo"
$workingDir = "$fixtures\workingDir"
$nuDeployPackageName = "NScaffold.NuDeploy"
$packageName = "Test.Package"

$configFile = "$fixtures\config\app-configs\Test.Package.ini"
. "$root\src-libs\functions\Import-Config.ns.ps1"

Describe "Install-NuDeployPackage" {
    Copy-Item $fixturesTemplate $fixtures -Recurse

    & $nugetExe pack "$root\src\nudeploy\nscaffold.nudeploy.nuspec" -NoPackageAnalysis -o $nugetRepo
    & $nugetExe install $nuDeployPackageName -Source $nugetRepo -OutputDirectory $workingDir -NoCache
    $nuDeployDir = Get-ChildItem $workingDir | ? {$_.Name -like "$nuDeployPackageName.*"} | Select-Object -First 1
    Import-Module "$($nuDeployDir.FullName)\tools\nudeploy.psm1" -Force

    & $nugetExe pack "$fixtures\package_source\test_package.nuspec" -NoPackageAnalysis -Version 1.0 -o $nugetRepo
    & $nugetExe pack "$fixtures\package_source\test_package.nuspec" -NoPackageAnalysis -Version 0.9 -o $nugetRepo

    It "should deploy the package and run install.ps1." {
        Install-NuDeployPackage -packageId $packageName -source $nugetRepo -workingDir $workingDir
        $packageVersion = "1.0"
        $packageRoot = "$workingDir\$packageName.$packageVersion"
        $deploymentConfigFile = "$packageRoot\deployment.config.ini"
        $config = Import-Config $deploymentConfigFile
        $config.DatabaseName.should.be("MyTaxes-local")
        "$packageRoot\features.txt".should.exist()
        (Get-Content "$packageRoot\features.txt").should.be("default")
    }

    It "should deploy the latest package all spec." {
        $features = @("renew", "load-balancer")
        Install-NuDeployPackage -packageId $packageName -version 0.9  -source $nugetRepo -workingDir $workingDir -config $configFile -features $features
        $packageRoot = "$workingDir\$packageName.0.9"
        $deploymentConfigFile = "$packageRoot\deployment.config.ini"
        $config = Import-Config $deploymentConfigFile
		$config.DatabaseName.should.be("[MyTaxesDatabaseName]-[ENV]")
        (Get-Content "$packageRoot\features.txt").should.be("renew load-balancer")
    }

    It "should deploy the package and ignore install.ps1." {
        & $nugetExe pack "$fixtures\package_source\test_package.nuspec" -NoPackageAnalysis -Version 1.1 -o $nugetRepo
        Install-NuDeployPackage -packageId $packageName -source $nugetRepo -workingDir $workingDir -ignoreInstall
        $packageVersion = "1.1"
        $packageRoot = "$workingDir\$packageName.$packageVersion"
        $installResultFile = "$packageRoot\deployment.config.ini"
        (Test-Path $installResultFile).should.be($False)
    }

    It "should deploy success if specified config file is missing or outdated" {
        Add-Content "$fixtures\package_source\config.ini" -value "`nExtraConfig = whatever"
        Get-Content "$fixtures\package_source\config.ini" | write-host -f yellow
        & $nugetExe pack "$fixtures\package_source\test_package.nuspec" -NoPackageAnalysis -Version 1.2 -o $nugetRepo
        Install-NuDeployPackage -packageId $packageName -version 1.2 -source $nugetRepo -workingDir $workingDir -config $configFile    
    }
}