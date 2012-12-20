Function Install-NuDeployPackage(){
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $packageId, 
        [string] $version, 
        [string] $source, 
        [string] $config,
        [string[]] $features, 
        [string] $workingDir = (Get-Location).ProviderPath, 
        [switch] $ignoreInstall,
        [switch] $force)

    $outputDir = "$workingDir\$packageId.$version"
    if($force -and (Test-Path $outputDir)){
        Remove-Item "$outputDir\*" -Force -Recurse
    }
    if($config){
        $config = (Resolve-Path $config).ProviderPath    
    }
    $nugetSource = $source
    $nuget = "$PSScriptRoot\tools\nuget\nuget.exe"

    $packageDir = Install-NuPackage $packageId $workingDir $version

    $packageDir | ? {-not $ignoreInstall} `
                | ? {Test-Path "$_\install.ps1"} `
                | % {
                        Use-Directory $_ {
                            if ($features -eq $null) {
                                & ".\install.ps1" $config
                            }else{
                                & ".\install.ps1" $config $features
                            }
                        } 
                    } 
    return $packageDir
}