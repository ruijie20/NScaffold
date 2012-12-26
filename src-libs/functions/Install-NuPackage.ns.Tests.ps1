$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = "$here\..\.."
$nugetExe = "$root\tools\nuget\NuGet.exe"
$fixturesTemplate = "$root\test\config-fixtures"
$fixtures = "$TestDrive\config-fixtures"
$nugetRepo = "$fixtures\nugetRepo"
$packageName = "Test.Package"

$workingDir = "$TestDrive\deployment_package"

. "$here\Redo-OnError.ns.ps1"
. "$here\Install-NuPackage.ns.ps1"

Describe "Install-NuPackage" {
    
    Copy-Item $fixturesTemplate $fixtures -Recurse
    & $nugetExe pack "$fixtures\package_source\test_package.nuspec" -NoPackageAnalysis -Version 1.0 -o $nugetRepo
    & $nugetExe pack "$fixtures\package_source\test_package.nuspec" -NoPackageAnalysis -Version 0.9 -o $nugetRepo

    It "should install the package with the latest version." {
        $nuget = $nugetExe
        $nugetSource = $nugetRepo
        $packageRoot = Install-NuPackage $packageName $workingDir

        
        $packageVersion = "1.0"
        $packageRoot.should.be("$workingDir\$packageName.$packageVersion") 
        $fileInPackage = "$packageRoot\config.ini"
        (Test-Path $fileInPackage).should.be($True)
        $installResultFile = "$packageRoot\deployment.config.ini"
        (Test-Path $installResultFile).should.be($False)
    }  

    It "should install the package with the spec version." {
        $nuget = $nugetExe
        $nugetSource = $nugetRepo
        $packageVersion = "0.9"

        $packageRoot = Install-NuPackage $packageName $workingDir $packageVersion
        
        $packageRoot.should.be("$workingDir\$packageName.$packageVersion") 
        $fileInPackage = "$packageRoot\config.ini"
        (Test-Path $fileInPackage).should.be($True)
        $installResultFile = "$packageRoot\deployment.config.ini"
        (Test-Path $installResultFile).should.be($False)
    } 

    It "should install the package and run the block." {
        $nuget = $nugetExe
        $nugetSource = $nugetRepo
        $packageVersion = "1.0"

        $fileCreateByBlock = "$TestDrive\block.ini"
        $packageRoot = Install-NuPackage $packageName $workingDir $packageVersion {
           New-Item -type file -path $fileCreateByBlock
        }
        $packageRoot.should.be("$workingDir\$packageName.$packageVersion") 
        $fileInPackage = "$packageRoot\config.ini"
        (Test-Path $fileInPackage).should.be($True)
        $installResultFile = "$packageRoot\deployment.config.ini"
        (Test-Path $installResultFile).should.be($False)
        $fileCreateByBlock.should.exist()
    }
    It "should throw error if install failed." {
        $nuget = $nugetExe
        $nugetSource = $nugetRepo
        $packageVersion = "0.9"
        try{
            $packageRoot = Install-NuPackage "noSuchPackage" $workingDir "0.9"    
        }
        catch {
            write-host $_ -f Magenta
            return
        }
        throw New-Object PesterFailure("exception", "no exception")
    }
}