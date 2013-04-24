$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = resolve-path "$here\..\.."
$nugetExe = "$root\tools\nuget\NuGet.exe"
$nugetRepo = "$TestDrive\nugetRepo"


Write-host "TestDrive = $TestDrive"
Function Publish-NugetPackage($nuspecPath, $version){
    write-host "Publish-NugetPackage $nugetExe pack $nuspecPath -NoPackageAnalysis -o $nugetRepo"
    if($version) {
        & $nugetExe pack $nuspecPath -NoPackageAnalysis -Version $version -o $nugetRepo
    }else{
        & $nugetExe pack $nuspecPath -NoPackageAnalysis -o $nugetRepo
    }
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
}

. $root\src\nudeploy\tools\functions\env-config-processors\Overwrite-AppVersionWithVersionSpec.ps1
Describe "Assert-VersionSpec" {
    Setup-ConfigFixtures
    Publish-NugetPackage "$root\src\nudeploy\nscaffold.nudeploy.nuspec" "0.0.1"
    Publish-NugetPackage "$root\src\nudeploy\nscaffold.nudeploy.nuspec" "0.0.2"

    $PSScriptRoot = $root
    It "should return quietly when given empty versionSpec is in the repository" {
        $versionSpec = @{}
        Assert-VersionSpec $versionSpec $nugetRepo
    }
    It "should return quietly when given package is in the repository" {
        $versionSpec = @{"NScaffold.NuDeploy"="0.0.1"}
        Assert-VersionSpec $versionSpec $nugetRepo
    }

    It "should throw exception when 1 of the given package is not in the repository" {
        $versionSpec = @{"NScaffold.NuDeploy"="0.0.1";"package_not_exist"="0.0.3"}
        try{
            Assert-VersionSpec $versionSpec $nugetRepo
            throw "Exception is not thrown"
        }catch{
            $_.should.match("not found")
        }
    }
    It "should throw exception when version doesn't match exactly" {
        $versionSpec = @{"NScaffold.NuDeploy"="0.0"}
        try{
            Assert-VersionSpec $versionSpec $nugetRepo
            throw "Exception is not thrown"
        }catch{
            $_.should.match("not found")
        }
    }
}