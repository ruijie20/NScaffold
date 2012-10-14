
# here setup includes
properties{
    Resolve-Path "$libsRoot\*.ps1" | 
        ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
        % { . "$($_.ProviderPath)" }
    . PS-Require "$libsRoot\functions"
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
    $codebaseConfig.projectDirs | % { Assert (Test-Path $_) "ProjectDir configuration error: Directory '$_' does not exists!" }
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
    &$yam build $projects
    Pop-Location
}

Task Package -description "Compile, package and push to nuget server if there's one"{

    Clear-Directory $packageOutputDir
    $version = &$versionManager.generate
    Use-Directory $packageOutputDir {
        $codebaseConfig.projectDirs | 
            % { Get-ChildItem $_ -Recurse -Include '*.nuspec' } | 
            % {
                &$nuget pack $_.FullName -prop Configuration=$buildConfiguration -version $version -NoPackageAnalysis
            }
    }

    &$versionManager.store $version

    if($packageConfig.pushRepo){
        Get-ChildItem $packageOutputDir -Filter *.nupkg | % {
            &$nuget push $_.name -s $packageConfig.pushRepo $packageConfig.apiKey
        }
    }
}

Task Install -description "Download from nuget server and install by running 'install.ps1' in the package"{
    if(-not $packageId){
        throw "packageId must be specified. "
    }    
    $version = &$versionManager.retrive
    
    Install-NuPackage $packageId $packageConfig.installDir $version | % {
        Use-Directory $_ {
            if(Test-Path "install.ps1"){
                & "install.ps1"
            }
        }
    }
}

Task UT {
    throw "comming soon. "
}

Task Help {
    Write-Documentation
}

# register extensions
if(Test-Path ".\build.ext.ps1"){
    include ".\build.ext.ps1"    
}
