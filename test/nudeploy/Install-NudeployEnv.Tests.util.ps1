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
    Copy-Item $fixturesTemplate $fixtures -Recurse
}
Function Assert-PackageInstalled($envConfigFile, $package, $version, $script){
    $envConfig = & $envConfigFile
    $packageRoot = "$($envConfig.nodeDeployRoot)\$package\$package.$version"
    if(-not(Test-Path $packageRoot)){
        throw "expect package[$package] with version[$version] to be installed in $packageRoot, actual is not installed"
    }
    if($script){
        & $script $packageRoot
    }
}
Function Remove-InstalledPackages($envConfigFile){
    $envConfig = & $envConfigFile
    Reset-Folder $envConfig.nodeDeployRoot
}
Function Assert-PackageNotInstalled($envConfigFile, $package, $version){
    $envConfig = & $envConfigFile
    $packageRoot = "$($envConfig.nodeDeployRoot)\$package\$package.$version"
    if(Test-Path $packageRoot){
        throw "expect package[$package] with version[$version] to be NOT installed in $packageRoot, actual is installed"
    }
}