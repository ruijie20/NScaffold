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
    
    if (Test-Path "$environmentsRoot\$env.ps1") {
        $envSettings = & "$environmentsRoot\$env.ps1"
        $packageSettings = $envSettings.package
    } else {
        throw "Missing env file. Please create it under 'build/scripts/build/environments' folder. "
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
    $version = $packageSettings.version
    $nodes = Get-DeployNodes $codebaseConfig.projectDirs $packageId

    #default profile    
    $nodes | ? {-not $_.profile} | % {
        New-PackageWithSpec $_.spec $_.type {
            param($spec)
            exec { & $nuget pack $spec -prop Configuration=$buildConfiguration -Version $version -NoPackageAnalysis -OutputDirectory $packageOutputDir }
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
        $currentNodes | % {            
            New-PackageWithSpec $_.spec $_.type {
                param($spec)
                exec { & $nuget pack $spec -prop Configuration=$buildConfiguration -Version $version -NoPackageAnalysis -OutputDirectory $packageOutputDir }
            }
        }
    }
    
    $pkgs = @{}
    $nodes | % { $pkgs.Add($_.id, $version) }
    
    &$packageSettings.store $pkgs

    if($packageSettings.pushRepo){
        Get-ChildItem $packageOutputDir -Filter *.nupkg | % {
            exec {&$nuget push $_.FullName -s $packageSettings.pushRepo $packageSettings.apiKey}
        }
    }
}


Task Deploy -description "Download from nuget server and install"{
    if(-not $packageId){
        throw "packageId must be specified. "
    }
    Clear-Directory $packageWorkingDir
    $pkgs = &$packageSettings.retrive
    $packageId | % {
        exec {
            $version = $pkgs[$_]
            if ($features -eq $null) {
                $result = Install-NuDeployPackage $_ -version $version -s $packageSettings.pullRepo -working $packageSettings.installDir -Force
            } else{
                $result = Install-NuDeployPackage $_ -version $version -s $packageSettings.pullRepo -working $packageSettings.installDir -Force -features $features                
            }
            $result | Out-String | write-host -f green
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
