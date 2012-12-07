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
        $config.should.equal(@{
			"DatabaseName" = "MyTaxes-int"
			"AppPoolPassword" = "TWr0ys1ngh4m"
			"DataSource" = "localhost"
			"IISRoot" = 'C:\IIS'
			"WebsiteName" = "ConsentService-int"
			"PWD" = "TWr0ys1ngh4m"
			"WebsitePort" = "8888"
			"PhysicalPath" = 'C:\IIS\ConsentService-int'
			"DBHost" = "localhost"
			"AppPoolName" = "ConsentService-int"
			"AppPoolUser" = "ConsentService-int"
			"MyTaxesDatabaseName" = "MyTaxes"
			"AppName" = "ConsentService"
			"ConsentServicePort" = "8888"
			"ENV" = "int"
		})       
    }   
}