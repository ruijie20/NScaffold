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

. $root\src\nudeploy\tools\functions\Assert-PackagesInRepo.ps1
Describe "Assert-PackagesInRepo" {
    Setup-ConfigFixtures
    Publish-NugetPackage "$root\src\nudeploy\nscaffold.nudeploy.nuspec" "0.0.1"
    Publish-NugetPackage "$root\src\nudeploy\nscaffold.nudeploy.nuspec" "0.0.2"

    $nuget = "$root\tools\nuget\nuget.exe"

    It "should return quietly when given package is in the repository" {
        $apps = @(
                @{
                    "package" = "NScaffold.NuDeploy"
                    "version" = "0.0.1"
                },
                @{
                    "package" = "NScaffold.NuDeploy"
                    "version" = "0.0.2"
                },
                @{
                    "package" = "NScaffold.NuDeploy"
                    "version" = "0.0.1"
                }
            )
        Assert-PackagesInRepo $nugetRepo $apps
    }

    It "should throw exception when 1 of the given package is not in the repository" {
        $apps = @(
                @{
                    "package" = "NScaffold.NuDeploy"
                    "version" = "0.0.1"
                },
                @{
                    "package" = "package_not_exist"
                    "version" = "0.0.1"
                }
            )
        try{
            Assert-PackagesInRepo $nugetRepo $apps
            throw "Exception is not thrown"
        }catch{
            $_.should.match("not found")
        }
    }
    It "should throw exception when version doesn't match exactly" {
        $apps = @(
                @{
                    "package" = "NScaffold.NuDeploy"
                    "version" = "0.0"
                }
            )
        try{
            Assert-PackagesInRepo $nugetRepo $apps
            throw "Exception is not thrown"
        }catch{
            $_.should.match("not found")
        }
    }
}