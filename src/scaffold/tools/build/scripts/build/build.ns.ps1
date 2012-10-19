$root = $MyInvocation.MyCommand.Path | Split-Path -parent
# here setup includes
properties{
    Get-ChildItem $libsRoot -Filter *.ps1 -Recurse | 
        ? { -not ($_.Name.Contains(".Tests.")) } | % {
            . $_.FullName
        }

    . PS-Require ".\functions"
    $env:EnableNuGetPackageRestore = "true"
    . "$codebaseRoot\codebaseConfig.ps1"
    $yam = "$codebaseRoot\yam.ps1"

    $tmpDir = "$codeBaseRoot\tmp"
    $packageOutputDir = "$tmpDir\nupkgs"

    # here include environment settings
    if (Test-Path "$environmentsRoot\$env.ps1") {
        . "$environmentsRoot\$env.ps1"
    }    
}

TaskSetup {
    # check $codebaseConfig.projectDirs is configured properly
    $codebaseConfig.projectDirs | % { Assert (Test-Path $_) "ProjectDir configuration error: Directory '$_' does not exist!" }
}

Task Clean -description "clear all bin and obj under project directories (with extra outputs)" {
    Clean-Projects $codebaseConfig.projectDirs
    if($codebaseConfig.extraProjectOutputs){
        $codebaseConfig.extraProjectOutputs | 
            ? { Test-Path $_ } |
            Remove-Item -Force -Recurse
    }
}

Task Compile -depends Clean -description "Compile all deploy nodes, need yam configured" {
    $projects = Get-DeployProjects $codebaseConfig.projectDirs | % { $_.FullName }
    Set-Location $codebaseRoot
    exec {&$yam build $projects}
    Pop-Location
}

Task Package -description "Compile, package and push to nuget server if there's one"{
    Clear-Directory $packageOutputDir
    $version = &$versionManager.generate
    Use-Directory $packageOutputDir {
        $codebaseConfig.projectDirs | 
            % { Get-ChildItem $_ -Recurse -Include '*.nuspec' } | 
            % {
                exec {&$nuget pack $_.FullName -prop Configuration=$buildConfiguration -version $version -NoPackageAnalysis}
            }
    }

    &$versionManager.store $version

    if($packageConfig.pushRepo){
        Get-ChildItem $packageOutputDir -Filter *.nupkg | % {
            exec {&$nuget push $_.name -s $packageConfig.pushRepo $packageConfig.apiKey}
        }
    }
}

Task Deploy -description "Download from nuget server, deploy and install by running 'install.ps1' in the package"{
    if(-not $packageId){
        throw "packageId must be specified. "
    }
    $version = &$versionManager.retrive
    $packageId | % {
        exec {&nudeploy $_ -version $version -s $packageConfig.pullRepo -working $packageConfig.installDir -Force}
    }    
}

Task UT {
    $version = &$versionManager.retrive
    $codebaseConfig.projectDirs | Get-ChildItem -include *.ut.nuspec -Recurse | % {
        $packageId = Get-PackageId $_
        exec {&nudeploy $packageId -version $version -s $packageConfig.pullRepo -working $packageConfig.installDir -Force}
    }
}

Task Help {
    Write-Documentation
}

# register extensions
if(Test-Path "$root\build.ext.ps1"){
    include "$root\build.ext.ps1"    
}
