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
    if (-not $ignoreInstall -and (Test-Path "$packageDir\install.ps1")) {
        if ($config -and (Test-Path "$packageDir\config.ini")){
            Verify-Config $config "$packageDir\config.ini"
        }
        
        Use-Directory $packageDir {
            if ($features -eq $null) {
                & ".\install.ps1" $config | Out-Default
            }else{
                & ".\install.ps1" $config $features | Out-Default
            }
        }         
    }    
    $packageDir
}