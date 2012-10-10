
# here setup includes
properties{
    Resolve-Path "$libsRoot\*.ps1" | 
    ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
    % { . "$($_.ProviderPath)" }
    . PSRequire "$libsRoot\functions\"
    . PSRequire ".\functions\"
    $env:EnableNuGetPackageRestore = "true"
    $context = @{}
    . $codebaseRoot\codebaseConfig.ps1
    $projectDirs = $codebaseConfig.projectDirs
    $yam = "$codebaseRoot\yam.ps1"
}

include ".\build.prop.ps1"

TaskSetup {
    # check $projectDirs is configured properly
    # $projectDirs | % { Assert (Test-Path $_) "ProjectDir configuration error: Directory '$_' does not exists!" }
}

Task Clean -description "clear all bin and obj under project directories (with extra outputs)" {
    Clean-Projects $projectDirs
    if($codebaseConfig.extraProjectOutputs){
        $codebaseConfig.extraProjectOutputs | 
            ? { Test-Path $_ } |
            Remove-Item -Force -Recurse
    }
}

Task Compile -depends Clean -description "Compile all deploy nodes, need yam configured" {
    Get-DeployProjects $projectDirs | % { 
        &$yam build $_
    }
}

Task Package -depends Compile -description "Compile, package and push to nuget server"{
    throw "comming soon. "
}

Task Install -description "Download from nuget server and install by running 'install.ps1' in the package"{
    throw "comming soon. "
}

Task UT {
    throw "comming soon. "
}

Task Help {
    Write-Documentation
}