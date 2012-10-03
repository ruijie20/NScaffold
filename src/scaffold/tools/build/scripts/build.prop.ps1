
properties {
    $rootDir = $rootDir
    $majorVersion = "1.0"
    $buildConfiguration = "Debug"
    $deployToolsDir = "$rootDir\build\tools\deploy-tools"
    $nuget = "$deployToolsDir\nudeploy\nuget.exe"
    $xunitRunner = "$rootDir\build\tools\XunitRunner\xunit.console.clr4.exe"
    $testAssemblies = "$rootDir\test\myVisas-test-unit\bin\myVisas-test-unit.dll"
    $packageDir = "$rootDir\tmp\nupkgs"
    $sourceDir = @("$rootDir\src", "$rootDir\test") 
    $reportsDir = "$rootDir\reports"
    $packageName = $packageName
    
}