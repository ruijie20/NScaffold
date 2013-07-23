$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Install-NudeployEnv.Tests.util.ps1"


Describe "Install-NudeployEnv" {

    $envConfigFile = "$fixtures\config\env.config.ps1"

    Function Assert-GeneratedConfigFile($deploymentConfigFile){
        $deploymentConfigFile.should.exist()
        $config = Import-Config $deploymentConfigFile
        $config.Count.should.be(9)
        $config.DatabaseName.should.be("MyPackage-int")
        $config.AppPoolPassword.should.be("password")
        $config.DataSource.should.be("localhost")
        $config.WebsiteName.should.be("MyService-int")
        $config.WebsitePort.should.be("8888")
        $config.PhysicalPath.should.be('C:\IIS\MyService-int')
        $config.AppPoolName.should.be("MyService-int")
        $config.AppPoolUser.should.be("MyService-int")
        $config.AppName.should.be("MyService")
    }

    It "should deploy the package on the host specified in env config with correct package configurations with no spec param" {
        Setup-ConfigFixtures
        ReImport-NudeployModule
        Publish-NugetPackage "$fixtures\package_source\test_package.nuspec" 1.0 

        [object[]]$appsConfig = Install-NudeployEnv $envConfigFile
        
        $appsConfig.Count.should.be(1)
        $app = $appsConfig[0]
        $app.package = 'Test.Package'
        $app.version = '1.0'

        Assert-PackageInstalled $envConfigFile "Test.Package" "1.0" {
            param($packageRoot)
            Assert-GeneratedConfigFile "$packageRoot\deployment.config.ini"
            $features = Get-Content "$packageRoot\features.txt"
            $features.should.be("a b")
        }
    }

    It "should stop deployment when exception is thrown when config miss item" {
        $envConfigFile = "$fixtures\config_miss_config_item\env.config.ps1"
        Setup-ConfigFixtures
        ReImport-NudeployModule
        Publish-NugetPackage "$fixtures\package_source\test_package.nuspec" 1.0 

        try{
            Install-NudeployEnv $envConfigFile
            throw "should not be here"
        }catch{
            $_.toString().should.be("Missing configuration for PhysicalPath.")
        }
    }

    It "should not deploy packages that have been deployed" {
        Setup-ConfigFixtures
        ReImport-NudeployModule
        Publish-NugetPackage "$fixtures\package_source\test_package.nuspec" 1.0 

        Install-NudeployEnv $envConfigFile

        Remove-InstalledPackages $envConfigFile 
        Install-NudeployEnv $envConfigFile
        Assert-PackageNotInstalled $envConfigFile "Test.Package" "1.0"
    }

    It "should stop deployment when exception is thrown when installing a package" {
        Setup-ConfigFixtures
        ReImport-NudeployModule
        Publish-NugetPackage "$fixtures\package_source_with_error_exitcode\test_package.nuspec" 1.0 
        $errorCode = 10

        try{
            Install-NudeployEnv $envConfigFile
            throw "should not be here"
        }catch{
            $_.toString().should.be("install.ps1 end with exit code: $errorCode")
        }
    }

    It "should stop deployment when exception is thrown when installing a package" {
        Setup-ConfigFixtures
        ReImport-NudeployModule
        Publish-NugetPackage "$fixtures\package_source_exception\test_package.nuspec" 1.0 

        try{
            Install-NudeployEnv $envConfigFile
            throw "should not be here"
        }catch{
            $_.toString().should.be('exception thrown when install')
        }
    }
}

Describe "Install-NudeployEnv with spec param" {
    Setup-ConfigFixtures
    ReImport-NudeployModule
    Publish-NugetPackage "$fixtures\package_source\test_package.nuspec" 1.0 
    Publish-NugetPackage "$fixtures\package_source\test_package.nuspec" 0.9

    It "should deploy the package on the host specified in env config with correct package configurations with spec param" {
        $envConfigFile = "$fixtures\config_simple\env.config.ps1"
        $vesrionSpecFile = "$fixtures\versionSpec.ini"

        Install-NudeployEnv -envPath $envConfigFile -versionSpec $vesrionSpecFile -nugetRepoSource $nugetRepo

        Assert-PackageInstalled $envConfigFile "Test.Package" "0.9" {
            param($packageRoot)
            $config = Import-Config "$packageRoot\deployment.config.ini"
            $config.DataSource.should.be("localhost1")
            $config.DatabaseName.should.be("MyPackage-local1")
            $config.WebsiteName.should.be("MyService-local1")
            $config.WebsitePort.should.be("80791")
            $config.AppPoolName.should.be("MyService-local1")
            $config.AppPoolUser.should.be("MyService-local1")
            $config.AppPoolPassword.should.be("password1")
            $config.PhysicalPath.should.be("C:\IIS\MyService-local1")
        }
    }
}

Describe "Install-NudeployEnv with multi-package" {
    Setup-ConfigFixtures
    ReImport-NudeployModule
    Publish-NugetPackage "$fixtures\package_source\test_package.nuspec" 2.0 
    Publish-NugetPackage "$fixtures\package_source_multiple\test_package_multiple.nuspec" 2.1

    It "should deploy the package on the host specified in env config with correct package configurations with multi-package" {
        $envConfigFile = "$fixtures\config_multiple\env.config.ps1"

        Install-NudeployEnv $envConfigFile

        Assert-PackageInstalled $envConfigFile "Test.Package" "2.0"
        Assert-PackageInstalled $envConfigFile "Test.Package.Multiple" "2.1"
    }
}
