$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = "$here\..\..\..\.."
$nugetExe = "$root\tools\nuget\NuGet.exe"
$fixturesTemplate = "$root\test\config-fixtures"
$fixtures = "$TestDrive\config-fixtures"
$nugetRepo = "$fixtures\nugetRepo"
$workingDir = "$fixtures\workingDir"
$nuDeployPackageName = "NScaffold.NuDeploy"
. "$root\src-libs\functions\Import-Config.ns.ps1"

Describe "Install-NudeployEnv with no spec param" {
    Copy-Item $fixturesTemplate $fixtures -Recurse

    & $nugetExe pack "$root\src\nudeploy\nscaffold.nudeploy.nuspec" -NoPackageAnalysis -o $nugetRepo
    & $nugetExe install $nuDeployPackageName -Source $nugetRepo -OutputDirectory $workingDir -NoCache
    $nuDeployDir = Get-ChildItem $workingDir | ? {$_.Name -like "$nuDeployPackageName.*"} | Select-Object -First 1
    Import-Module "$($nuDeployDir.FullName)\tools\nudeploy.psm1" -Force

    & $nugetExe pack "$fixtures\package_source\test_package.nuspec" -NoPackageAnalysis -Version 1.0 -o $nugetRepo
    & $nugetExe pack "$fixtures\package_source\test_package.nuspec" -NoPackageAnalysis -Version 0.9 -o $nugetRepo

    It "should deploy the package on the host specified in env config with correct package configurations" {
        $envPath = "$fixtures\config"
        $result = Install-NudeployEnv $envPath
        $verf = ""
        $result | % {
            $verf = $verf + $_.package
            $verf = $verf + $_.version
        }
        $verf.should.be("Test.Package1.0")

        $envConfig = & "$envPath\env.config.ps1"
        $packageName = "Test.Package"
        $packageVersion = "1.0"
        $packageRoot = "$($envConfig.nodeDeployRoot)\$packageName\$packageName.$packageVersion"
        $deploymentConfigFile = "$packageRoot\deployment.config.ini"
        $config = Import-Config $deploymentConfigFile

        $config.DatabaseName.should.be("MyTaxes-int")
        $config.AppPoolPassword.should.be("TWr0ys1ngh4m")
        $config.DataSource.should.be("localhost")
        $config.IISRoot.should.be('C:\IIS')
        $config.WebsiteName.should.be("ConsentService-int")
        $config.PWD.should.be("TWr0ys1ngh4m")
        $config.WebsitePort.should.be("8888")
        $config.PhysicalPath.should.be('C:\IIS\ConsentService-int')
        $config.DBHost.should.be("localhost")
        $config.AppPoolName.should.be("ConsentService-int")
        $config.AppPoolUser.should.be("ConsentService-int")
        $config.MyTaxesDatabaseName.should.be("MyTaxes")
        $config.AppName.should.be("ConsentService")
        $config.ConsentServicePort.should.be("8888")
        $config.ENV.should.be("int")
    }
}

Describe "Install-NudeployEnv with spec nudeploy version in node server" {
    Copy-Item $fixturesTemplate $fixtures -Recurse

    & $nugetExe pack "$root\src\nudeploy\nscaffold.nudeploy.nuspec" -NoPackageAnalysis -Version 0.0.1 -o $nugetRepo
    & $nugetExe pack "$root\src\nudeploy\nscaffold.nudeploy.nuspec" -NoPackageAnalysis -Version 0.0.2 -o $nugetRepo
    & $nugetExe install $nuDeployPackageName -Source $nugetRepo -OutputDirectory $workingDir -NoCache
    Import-Module "$workingDir\NScaffold.NuDeploy.0.0.2\tools\nudeploy.psm1" -Force

    & $nugetExe pack "$fixtures\package_source\test_package.nuspec" -NoPackageAnalysis -Version 0.9 -o $nugetRepo

    It "should deploy the package on the host specified in env config with correct package configurations" {
        $envPath = "$fixtures\config_spec_nudeploy"
        $result = Install-NudeployEnv $envPath
        
        $verf = ""
        $result | % {
            $verf = $verf + $_.package
            $verf = $verf + $_.version
        }
        $verf.should.be("Test.Package0.9")

        $envConfig = & "$envPath\env.config.ps1"
        "$($envConfig.nodeDeployRoot)\tools\NScaffold.NuDeploy.0.0.1".should.exist();
        (Test-Path  "$($envConfig.nodeDeployRoot)\tools\NScaffold.NuDeploy.0.0.2").should.be($false);
    }
}


Describe "Install-NudeployEnv with spec param" {
    Copy-Item $fixturesTemplate $fixtures -Recurse

    & $nugetExe pack "$root\src\nudeploy\nscaffold.nudeploy.nuspec" -NoPackageAnalysis -o $nugetRepo
    & $nugetExe install $nuDeployPackageName -Source $nugetRepo -OutputDirectory $workingDir -NoCache
    $nuDeployDir = Get-ChildItem $workingDir | ? {$_.Name -like "$nuDeployPackageName.*"} | Select-Object -First 1
    Import-Module "$($nuDeployDir.FullName)\tools\nudeploy.psm1" -Force

    & $nugetExe pack "$fixtures\package_source\test_package.nuspec" -NoPackageAnalysis -Version 1.0 -o $nugetRepo
    & $nugetExe pack "$fixtures\package_source\test_package.nuspec" -NoPackageAnalysis -Version 0.9 -o $nugetRepo

    It "should deploy the package on the host specified in env config with correct package configurations" {
        $envPath = "$fixtures\config_simple"
        $versionTempFile = "$fixtures\versionSpec.ini"
        $result = Install-NudeployEnv -envPath $envPath -versionSpec $versionTempFile -nugetRepoSource $nugetRepo
        $verf = ""
        $result | % {
            $verf = $verf + $_.package
            $verf = $verf + $_.version
        }
        $verf.should.be("Test.Package0.9")

        $envConfig = & "$envPath\env.config.ps1"
        $packageName = "Test.Package"
        $packageVersion = "0.9"
        $defaultDeployRoot = "C:\deployment"
        $packageRoot = "$defaultDeployRoot\$packageName\$packageName.$packageVersion"
        $packageRoot.should.exist()
        $deploymentConfigFile = "$packageRoot\deployment.config.ini"
        $config = Import-Config $deploymentConfigFile

        $config.DataSource.should.be("localhost1")
        $config.DatabaseName.should.be("MyTaxes-local1")
        $config.WebsiteName.should.be("ConsentService-local1")
        $config.WebsitePort.should.be("80791")
        $config.AppPoolName.should.be("ConsentService-local1")
        $config.AppPoolUser.should.be("ConsentService-local1")
        $config.AppPoolPassword.should.be("TWr0ys1ngh4m1")
        $config.PhysicalPath.should.be("C:\IIS\ConsentService-local1")
        Remove-Item -r "$defaultDeployRoot\$packageName" -Force
    }
}

Describe "Install-NudeployEnv with multi-package" {
    Copy-Item $fixturesTemplate $fixtures -Recurse

    & $nugetExe pack "$root\src\nudeploy\nscaffold.nudeploy.nuspec" -NoPackageAnalysis -o $nugetRepo
    & $nugetExe install $nuDeployPackageName -Source $nugetRepo -OutputDirectory $workingDir -NoCache
    $nuDeployDir = Get-ChildItem $workingDir | ? {$_.Name -like "$nuDeployPackageName.*"} | Select-Object -First 1
    Import-Module "$($nuDeployDir.FullName)\tools\nudeploy.psm1" -Force

    & $nugetExe pack "$fixtures\package_source\test_package.nuspec" -NoPackageAnalysis -Version 2.0 -o $nugetRepo
    & $nugetExe pack "$fixtures\package_source_multiple\test_package_multiple.nuspec" -NoPackageAnalysis -Version 2.1 -o $nugetRepo

    It "should deploy the package on the host specified in env config with correct package configurations" {
        $envPath = "$fixtures\config_multiple"
        $result = Install-NudeployEnv $envPath
        $verf = ""
        $result | % {
            $verf = $verf + $_.package
            $verf = $verf + $_.version
        }
        $verf.should.be("Test.Package2.0Test.Package.Multiple2.1")
    }
}