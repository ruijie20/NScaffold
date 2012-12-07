$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = "$here\..\..\..\.."
$nugetExe = "$root\tools\nuget\NuGet.exe"
$fixturesTemplate = "$root\test\config-fixtures\Install-NudeployEnv-fixtures"
$fixtures = "$TestDrive\Install-NudeployEnv-fixtures"
$nugetRepo = "$fixtures\nugetRepo"
$workingDir = "$fixtures\workingDir"
$nuDeployPackageName = "NScaffold.NuDeploy"
. "$root\src-libs\functions\Import-Config.ns.ps1"

Describe "Install-NudeployEnv" {
    Copy-Item $fixturesTemplate $fixtures -Recurse

    & $nugetExe pack "$root\src\nudeploy\nscaffold.nudeploy.nuspec" -NoPackageAnalysis -o $nugetRepo
    & $nugetExe install $nuDeployPackageName -Source $nugetRepo -OutputDirectory $workingDir -NoCache
    $nuDeployDir = Get-ChildItem $workingDir | ? {$_.Name -like "$nuDeployPackageName.*"} | Select-Object -First 1
    Import-Module "$($nuDeployDir.FullName)\tools\nudeploy.psm1" -Force

    & $nugetExe pack "$fixtures\package_source\test_package.nuspec" -NoPackageAnalysis -o $nugetRepo

    It "should deploy the package on the host specified in env config with correct package configurations" {
        $envPath = "$fixtures\config"
        Install-NudeployEnv $envPath
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