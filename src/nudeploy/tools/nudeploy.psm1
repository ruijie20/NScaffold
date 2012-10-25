Get-ChildItem "$PSScriptRoot\libs" -Filter *.ps1 -Recurse | 
    ? { -not ($_.Name.Contains(".Tests.")) } | % {
        . $_.FullName
    }

Function Install-NuDeployPackage(){
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $packageId, 
        [string] $version, 
        [string] $source, 
        [string] $config,
        [string[]] $features, 
        [string] $workingDir = (Get-Location).ProviderPath, 
        [switch] $force)

    $outputDir = "$workingDir\$packageId.$version"
    if($force -and (Test-Path $outputDir)){
        Remove-Item "$outputDir\*" -Force -Recurse
    }
    $configFullPath = (Resolve-Path $config).ProviderPath
    $nugetSource = $source
    $nuget = "$PSScriptRoot\tools\nuget\nuget.exe"
    Install-NuPackage $packageId $workingDir $version | % {
        Use-Directory $_ {
            if(Test-Path ".\install.ps1"){
                & ".\install.ps1" $configFullPath $features
            }
        }
    }
}

Set-Alias nudeploy Install-NuDeployPackage
Export-ModuleMember Install-NuDeployPackage
Export-ModuleMember -Alias nudeploy