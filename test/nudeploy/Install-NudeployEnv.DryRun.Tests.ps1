$here = Split-Path -Parent $MyInvocation.MyCommand.Path
. "$here\Install-NudeployEnv.Tests.util.ps1"

Describe "Install-NudeployEnv with DryRun" {

    $envConfigFile = "$fixtures\config\env.config.ps1"

    Function Assert-GeneratedConfigFile($deploymentConfigFile){
        $deploymentConfigFile.should.exist()
        $config = Import-Config $deploymentConfigFile
        $config.Count.should.be(9)
        $config.DatabaseName.should.be("MyTaxes-int")
        $config.AppPoolPassword.should.be("TWr0ys1ngh4m")
        $config.DataSource.should.be("localhost")
        $config.WebsiteName.should.be("ConsentService-int")
        $config.WebsitePort.should.be("8888")
        $config.PhysicalPath.should.be('C:\IIS\ConsentService-int')
        $config.AppPoolName.should.be("ConsentService-int")
        $config.AppPoolUser.should.be("ConsentService-int")
        $config.AppName.should.be("ConsentService")
    }

    Function Assert-InstallIsNotExecuted($envConfigFile, $package, $version){
        $envConfig = & $envConfigFile
        $packageRoot = "$($envConfig.nodeDeployRoot)\$package\$package.$version"
        $fileGeneratedByInstall = "$packageRoot\fileGeneratedByInstall.txt"
        if(Test-Path $fileGeneratedByInstall){
            throw "expect package[$package] with version[$version] to be NOT installed in $packageRoot, actual is installed"
        }
    }
    It "should not deploy the package" {
        Setup-ConfigFixtures
        ReImport-NudeployModule
        Publish-NugetPackage "$fixtures\package_source\test_package.nuspec" 1.0 
        Assert-InstallIsNotExecuted $envConfigFile "Test.Package" "1.0"

        [object[]]$appsConfig = Install-NudeployEnv -DryRun $envConfigFile
        
        Assert-InstallIsNotExecuted $envConfigFile "Test.Package" "1.0"
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
}