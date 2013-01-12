$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = "$here\..\..\..\.."
$nugetExe = "$root\tools\nuget\NuGet.exe"
$fixturesTemplate = "$root\test\config-fixtures"
$fixtures = "$TestDrive\config-fixtures"
$nugetRepo = "$TestDrive\nugetRepo"
$workingDir = "$TestDrive\workingDir"
$nuDeployPackageName = "NScaffold.NuDeploy"
. "$root\src-libs\functions\Import-Config.ns.ps1"


Write-host "TestDrive = $TestDrive"
Function Publish-NugetPackage($nuspecPath, $version){
    write-host "Publish-NugetPackage $nugetExe pack $nuspecPath -NoPackageAnalysis -o $nugetRepo"
    if($version) {
        & $nugetExe pack $nuspecPath -NoPackageAnalysis -Version $version -o $nugetRepo
    }else{
        & $nugetExe pack $nuspecPath -NoPackageAnalysis -o $nugetRepo
    }
}
Function Install-NugetPackage($package){
    & $nugetExe install $package -Source $nugetRepo -OutputDirectory $workingDir -NoCache
}
Function Import-NudeployModule(){
    $nuDeployDir = Get-ChildItem $workingDir | ? {$_.Name -like "$nuDeployPackageName.*"} | Select-Object -First 1
    Import-Module "$($nuDeployDir.FullName)\tools\nudeploy.psm1" -Force
}
Function ReImport-NudeployModule(){
    Publish-NugetPackage "$root\src\nudeploy\nscaffold.nudeploy.nuspec"
    Install-NugetPackage $nuDeployPackageName
    Import-NudeployModule $nuDeployPackageName
}
Function Reset-Folder($folder){
    Remove-Item -Force -Recurse $folder -ErrorAction SilentlyContinue |Out-Null
    New-Item $folder -type directory
}
Function Setup-ConfigFixtures(){
    Reset-Folder $nugetRepo
    Reset-Folder $workingDir
    Remove-Item -Force -Recurse $fixtures -ErrorAction SilentlyContinue |Out-Null
    Copy-Item $fixturesTemplate $fixtures -Recurse
}
Function Get-ExpectedPackageInstallationPath($envConfigFile, $package, $version){
    $envConfig = & $envConfigFile
    "$($envConfig.nodeDeployRoot)\$package\$package.$version"
}
Function Assert-PackageInstalled($envConfigFile, $package, $version){
    $packageRoot = Get-ExpectedPackageInstallationPath $envConfigFile $package $version
    if(-not(Test-Path $packageRoot)){
        throw "expect package[$package] with version[$version] to be installed in $packageRoot, actual not found"
    }
}

Describe "Install-NudeployEnv with no spec param" {
    Function Assert-GeneratedConfigFile($deploymentConfigFile){
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

    Setup-ConfigFixtures
    ReImport-NudeployModule
    Publish-NugetPackage "$fixtures\package_source\test_package.nuspec" 1.0 
    $envConfigFolder = "$fixtures\config"
    $envConfigFile = "$envConfigFolder\env.config.ps1"

    It "should deploy the package on the host specified in env config with correct package configurations" {
        Install-NudeployEnv $envConfigFile

        Assert-PackageInstalled $envConfigFile "Test.Package" "1.0"
        $packageRoot = Get-ExpectedPackageInstallationPath $envConfigFile "Test.Package" "1.0"
        Assert-GeneratedConfigFile "$packageRoot\deployment.config.ini"
    }

    It "should deploy the package given the envConfig folder" {
        Install-NudeployEnv $envConfigFolder

        Assert-PackageInstalled $envConfigFile "Test.Package" "1.0"
        $packageRoot = Get-ExpectedPackageInstallationPath $envConfigFile "Test.Package" "1.0"
        Assert-GeneratedConfigFile "$packageRoot\deployment.config.ini"
    }
}

Describe "Install-NudeployEnv with spec nudeploy version in node server" {
    Setup-ConfigFixtures
    Publish-NugetPackage "$root\src\nudeploy\nscaffold.nudeploy.nuspec" "0.0.1"
    Publish-NugetPackage "$root\src\nudeploy\nscaffold.nudeploy.nuspec" "0.0.2"
    Install-NugetPackage $nuDeployPackageName
    Import-NudeployModule
    Publish-NugetPackage "$fixtures\package_source\test_package.nuspec" 0.9

    It "should deploy the package on the host specified in env config with correct package configurations" {
        $envConfigFile = "$fixtures\config_spec_nudeploy\env.config.ps1"

        Install-NudeployEnv $envConfigFile
        
        Assert-PackageInstalled $envConfigFile "Test.Package" "0.9"

        $envConfig = & $envConfigFile
        "$($envConfig.nodeDeployRoot)\tools\NScaffold.NuDeploy.0.0.1".should.exist();
        (Test-Path  "$($envConfig.nodeDeployRoot)\tools\NScaffold.NuDeploy.0.0.2").should.be($false);
    }
}

Describe "Install-NudeployEnv with spec param" {
    Setup-ConfigFixtures
    ReImport-NudeployModule
    Publish-NugetPackage "$fixtures\package_source\test_package.nuspec" 1.0 
    Publish-NugetPackage "$fixtures\package_source\test_package.nuspec" 0.9

    It "should deploy the package on the host specified in env config with correct package configurations" {
        $envConfigFile = "$fixtures\config_simple\env.config.ps1"
        $vesrionSpecFile = "$fixtures\versionSpec.ini"

        Install-NudeployEnv -envPath $envConfigFile -versionSpec $vesrionSpecFile -nugetRepoSource $nugetRepo

        Assert-PackageInstalled $envConfigFile "Test.Package" "0.9"

        $packageRoot = Get-ExpectedPackageInstallationPath $envConfigFile "Test.Package" "0.9" 
        $config = Import-Config "$packageRoot\deployment.config.ini"
        $config.DataSource.should.be("localhost1")
        $config.DatabaseName.should.be("MyTaxes-local1")
        $config.WebsiteName.should.be("ConsentService-local1")
        $config.WebsitePort.should.be("80791")
        $config.AppPoolName.should.be("ConsentService-local1")
        $config.AppPoolUser.should.be("ConsentService-local1")
        $config.AppPoolPassword.should.be("TWr0ys1ngh4m1")
        $config.PhysicalPath.should.be("C:\IIS\ConsentService-local1")
    }
}

Describe "Install-NudeployEnv with multi-package" {
    Setup-ConfigFixtures
    ReImport-NudeployModule
    Publish-NugetPackage "$fixtures\package_source\test_package.nuspec" 2.0 
    Publish-NugetPackage "$fixtures\package_source_multiple\test_package_multiple.nuspec" 2.1

    It "should deploy the package on the host specified in env config with correct package configurations" {
        $envConfigFile = "$fixtures\config_multiple\env.config.ps1"

        Install-NudeployEnv $envConfigFile

        Assert-PackageInstalled $envConfigFile "Test.Package" "2.0"
        Assert-PackageInstalled $envConfigFile "Test.Package.Multiple" "2.1"
    }
}