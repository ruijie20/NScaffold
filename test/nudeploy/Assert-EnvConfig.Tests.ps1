$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = resolve-path "$here\..\.."
$nugetExe = "$root\tools\nuget\NuGet.exe"
$fixturesTemplate = "$root\test\test-fixtures"
$fixtures = "$TestDrive\test-fixtures"
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
    Remove-Item -Force -Recurse $folder -ErrorAction SilentlyContinue 
    while(Test-Path $folder){
        sleep 2
        write-host "trying Reset-Folder $folder"
        Remove-Item -Force -Recurse $folder -ErrorAction SilentlyContinue 
    }
    New-Item $folder -type directory
}
Function Setup-ConfigFixtures(){
    Reset-Folder $nugetRepo
    Reset-Folder $workingDir
    Remove-Item -Force -Recurse $fixtures -ErrorAction SilentlyContinue
}

Describe "Assert-EnvConfig" {

    It "should throw exception when variables are not resolvable" {
        Setup-ConfigFixtures
        ReImport-NudeployModule

        $envConfig = "$fixturesTemplate\Assert-EnvConfig\fail.config.ps1"
        try{
            Assert-EnvConfig $envConfig
        }catch{
            $_.should.match("User")
            return
        }
        throw "wrong_if_here"
    }

    It "should return quitely when variables in app config are resolvable" {
        Setup-ConfigFixtures
        ReImport-NudeployModule

        $envConfig = "$fixturesTemplate\Assert-EnvConfig\success.config.ps1"
        Assert-EnvConfig $envConfig
    }
}

