$root = $MyInvocation.MyCommand.Path | Split-Path -parent
# here setup includes
properties{
    Get-ChildItem $libsRoot -Filter *.ps1 -Recurse | 
        ? { -not ($_.Name.Contains(".Tests.")) } | % {
            . $_.FullName
        }

    . PS-Require ".\functions"
    $env:EnableNuGetPackageRestore = "true"
    $yam = "$codebaseRoot\yam.ps1"

    $tmpDir = "$codeBaseRoot\tmp"
    $packageOutputDir = "$tmpDir\nupkgs"
    $packageWorkingDir = "$tmpDir\working"

    # here include environment settings
    if (Test-Path "$environmentsRoot\$env.ps1") {
        $packageManager = & "$environmentsRoot\$env.ps1"
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

# only compile the default profile nodes
Task Compile -depends Clean -description "Compile all deploy nodes, need yam configured" {
    $nodes = Get-DeployNodes $codebaseConfig.projectDirs $packageId    
    $projects = $nodes | ? {-not $_.profile -and $_.project} | % { $_.project.FullName }
    Set-Location $codebaseRoot
    exec {&$yam build $projects}
    Pop-Location
}

Task Package -depends Compile -description "Compile, package and push to nuget server if there's one"{
    Clear-Directory $packageOutputDir
    $version = &$packageManager.generateVersion
    $nodes = Get-DeployNodes $codebaseConfig.projectDirs $packageId

    #default profile
    Use-Directory $packageOutputDir {
        $nodes | ? {-not $_.profile} |
            % {
                exec {&$nuget pack $_.spec.FullName -prop Configuration=$buildConfiguration -version $version -NoPackageAnalysis}
            }
    }

    # others
    $nodes | ? {$_.profile} | group -Property {$_.profile} | % {
        $profile = $_.Name
        $currentNodes = $_.Group
        $compileProjects = $currentNodes | ? {$_.project}
        $dirs = $compileProjects | % { $_.project.Directory.FullName }
        $projects = $compileProjects | % { $_.project.FullName }
        Clean-Projects $dirs
        Set-Location $codebaseRoot        
        exec {&$yam build $projects -runtimeProfile $profile}
        Pop-Location
        Use-Directory $packageOutputDir {
            $currentNodes | % {
                exec {&$nuget pack $_.spec.FullName -prop Configuration=$buildConfiguration -version $version -NoPackageAnalysis}
            }
        }
    }
    
    $pkgs = @{}
    $nodes | % { $pkgs.Add($_.id, $version) }
    
    &$packageManager.store $pkgs

    if($packageManager.pushRepo){
        Get-ChildItem $packageOutputDir -Filter *.nupkg | % {
            exec {&$nuget push $_.FullName -s $packageManager.pushRepo $packageManager.apiKey}
        }
    }
}


Task Deploy -description "Download from nuget server and install"{
    if(-not $packageId){
        throw "packageId must be specified. "
    }
    Clear-Directory $packageWorkingDir
    $pkgs = &$packageManager.retrive
    $packageId | % {
        exec {
            $version = $pkgs[$_]
            if ($features -eq $null) {
                Install-NuDeployPackage $_ -version $version -s $packageManager.pullRepo -working $packageManager.installDir -Force
            } else{
                Install-NuDeployPackage $_ -version $version -s $packageManager.pullRepo -working $packageManager.installDir -Force -features $features                
            }            
        }
    }    
}

Task Help {
    Write-Documentation
}

# register extensions
if(Test-Path "$root\build.ext.ps1"){
    include "$root\build.ext.ps1"    
}
