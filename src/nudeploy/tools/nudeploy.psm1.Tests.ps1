$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = "$here\..\..\.."
$nugetExe = "$root\tools\nuget\NuGet.exe"
$fixturesTemplate = "$root\test\config-fixtures"
$fixtures = "$TestDrive\config-fixtures"
$nugetRepo = "$fixtures\nugetRepo"
$workingDir = "$fixtures\workingDir"
$nuDeployPackageName = "NScaffold.NuDeploy"

Describe "nudeploy.psm1" {
    Copy-Item $fixturesTemplate $fixtures -Recurse

    & $nugetExe pack "$root\src\nudeploy\nscaffold.nudeploy.nuspec" -NoPackageAnalysis -o $nugetRepo
    & $nugetExe install $nuDeployPackageName -Source $nugetRepo -OutputDirectory $workingDir -NoCache
    $nuDeployDir = Get-ChildItem $workingDir | ? {$_.Name -like "$nuDeployPackageName.*"} | Select-Object -First 1
    Import-Module "$($nuDeployDir.FullName)\tools\nudeploy.psm1" -Force

    It "should have command nudeploy" {
        (Get-Command Install-NuDeployPackage).Name.should.be("Install-NuDeployPackage")
        (Get-Command nudeploy).Name.should.be("nudeploy")
    }

    It "should have command nudeployEnv" {
        (Get-Command Install-NudeployEnv).Name.should.be("Install-NudeployEnv")
        (Get-Command nudeployEnv).Name.should.be("nudeployEnv")
    }
}