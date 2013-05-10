Function Install-NuDeployPackage(){
    [CmdletBinding(DefaultParameterSetName="configFile")]   
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $packageId, 
        [string] $version, 
        [string] $source, 
        [Parameter(ParameterSetName = "configFile")]
        [alias("cf")]
        [string]$configFile, 
        [Parameter(ParameterSetName = "configObject")]
        [alias("co")]
        [hashtable]$cfgObject, 
        [string[]] $features, 
        [string] $workingDir = (Get-Location).ProviderPath, 
        [switch] $ignoreInstall,
        [switch] $force)
    if($PsCmdlet.ParameterSetName -eq 'configObject') {
        $config = [System.IO.Path]::GetTempFileName()
        $cfgObject.GetEnumerator() | % { "$($_.key) = $($_.value)" } | Set-Content $config
    } else {
        $config = $configFile
    }

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

    if ($config -and (Test-Path "$packageDir\config.ini")){
        Verify-Config $config "$packageDir\config.ini"
    }
    if (-not $ignoreInstall -and (Test-Path "$packageDir\install.ps1")) {
        $result = Use-Directory $packageDir {
            if ($features -eq $null) {
                & ".\install.ps1" $config
            }else{
                & ".\install.ps1" $config $features
            }
            if(-not($LastExitCode -eq 0)){
                throw "install.ps1 end with exit code: $Lastexitcode"
            }
        }
    }
    if($PsCmdlet.ParameterSetName -eq 'configObject') {
        Remove-Item $config -Force -ea SilentlyContinue
    }
    $result
}