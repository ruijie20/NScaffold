$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = "$here\..\.."
$nugetExe = "$root\tools\nuget\NuGet.exe"
$fixturesTemplate = "$root\test\test-fixtures"
$fixtures = "$TestDrive\test-fixtures"
$nugetRepo = "$fixtures\nugetRepo"
$workingDir = "$fixtures\workingDir"
$scaffoldPackageName = "NScaffold.Scaffold"
$projectDir = "$fixtures\project_fixture"
. "$root\src\ns-install\tools\scripts\commands\Initialize-Project.ps1"
. "$root\src-libs\functions\Use-Directory.ns.ps1"

Describe "go.ns.ps1 Compile" {
    Copy-Item $fixturesTemplate $fixtures -Recurse

    & $nugetExe pack "$root\src\scaffold\nscaffold.scaffold.nuspec" -NoPackageAnalysis -o $nugetRepo
    & $nugetExe install $scaffoldPackageName -Source $nugetRepo -OutputDirectory $workingDir -NoCache
    $scaffoldPackageDir = Get-ChildItem $workingDir | ? {$_.Name -like "$scaffoldPackageName.*"} | Select-Object -First 1
    $scaffoldSourceDir = "$($scaffoldPackageDir.FullName)"
    Use-Directory $here {
        Clean-Scaffold $projectDir
        Apply-Scaffold $scaffoldSourceDir $projectDir
    } 

    It "should deploy the package and run install.ps1." {
        Use-Directory $projectDir {
            iex ".\go.ns.ps1 Compile"
        }
        "$projectDir\src\single-project\bin\Debug\Single.Project.exe".should.exist()
        "$projectDir\src\multi-project\bin\Debug\Project1\Multi.Project1.exe".should.exist()
        "$projectDir\src\multi-project\bin\Debug\Project2\Multi.Project2.exe".should.exist()
        (Test-Path "$projectDir\src\group-project\bin\Debug\Group.Project.exe").should.be($false)
    }
}

Describe "go.ns.ps1 Package" {
    Copy-Item $fixturesTemplate $fixtures -Recurse

    & $nugetExe pack "$root\src\scaffold\nscaffold.scaffold.nuspec" -NoPackageAnalysis -o $nugetRepo
    & $nugetExe install $scaffoldPackageName -Source $nugetRepo -OutputDirectory $workingDir -NoCache
    $scaffoldPackageDir = Get-ChildItem $workingDir | ? {$_.Name -like "$scaffoldPackageName.*"} | Select-Object -First 1
    $scaffoldSourceDir = "$($scaffoldPackageDir.FullName)"
    Use-Directory $here {
        Clean-Scaffold $projectDir
        Apply-Scaffold $scaffoldSourceDir $projectDir
    } 

    It "should deploy the package and run install.ps1." {
        Use-Directory $projectDir {
            iex ".\go.ns.ps1 Package"
        }
        "$projectDir\tmp\nupkgs\Single.Project.1.0.0.nupkg".should.exist()
        "$projectDir\tmp\nupkgs\Multi.Project.1.0.0.nupkg".should.exist()
        "$projectDir\tmp\nupkgs\Package1.Project.1.0.0.nupkg".should.exist()
        "$projectDir\tmp\nupkgs\Package2.Project.1.0.0.nupkg".should.exist()
        "$projectDir\tmp\nupkgs\pkgs.txt".should.exist()

        & $nugetExe install "Package1.Project" -Source "$projectDir\tmp\nupkgs" -OutputDirectory $workingDir -NoCache
        "$workingDir\Package1.Project.1.0.0\target\Group.Project.exe".should.exist()
        & $nugetExe install "Package2.Project" -Source "$projectDir\tmp\nupkgs" -OutputDirectory $workingDir -NoCache
        "$workingDir\Package2.Project.1.0.0\target\Group.Project.exe".should.exist()
    }
}