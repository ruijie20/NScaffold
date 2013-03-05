$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = "$here\..\.."
$fixturesTemplate = "$root\test\test-fixtures"
$fixtures = "$TestDrive\test-fixtures"
$projectDir = "$fixtures\project_fixture"
. "$root\src\scaffold\tools\build\scripts\build\functions\Get-DeployNodes.ns.ps1"
. "$root\src\scaffold\tools\build\scripts\build\functions\Get-PackageId.ns.ps1"
. "$root\src\scaffold\tools\build\scripts\build\functions\Get-PackageConfig.ns.ps1"

Describe "Get-DeployNodes.Tests" {

    Remove-Item -Force -Recurse $fixtures -ErrorAction SilentlyContinue |Out-Null
    Copy-Item $fixturesTemplate $fixtures -Recurse

    It "should get deploy nodes for single project." {
        $nodes = Get-DeployNodes "$projectDir\src" "Single.Project"
        $nodes.id.should.be("Single.Project");
        $nodes.project.should.exist()
    }

    It "should get deploy nodes for multi project." {
        $nodes = Get-DeployNodes "$projectDir\src" "Multi.Project"
        $nodes.id.should.be("Multi.Project");
        $nodes.project.Count.should.be(2)
        $nodes.project[0].should.exist()
        $nodes.project[1].should.exist()
    }
}