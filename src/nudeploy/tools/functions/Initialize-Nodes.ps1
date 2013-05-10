
Function Initialize-Nodes($envConfig){
    $targetNodes = $envConfig.apps | % { $_.server } | Sort | Get-Unique
    Add-HostAsTrusted $targetNodes
    $targetNodes | % { Setup-NuDeployRemotely $_ $envConfig.nodeDeployRoot} | Out-Default
    
}
Function Add-HostAsTrusted($targetNodes) {
    Write-Host "Adding nodes to TrustedHosts"
    winrm set winrm/config/client "@{TrustedHosts=`"$($targetNodes -join ",")`"}" | Out-Default
}

Function Setup-NuDeployRemotely($server, $nodeDeployRoot){
    Write-Host "Preparing NuDeploy on node [$server]...." -f cyan
    Clear-RemoteDeployRoot $server $nodeDeployRoot

    $nugetExeDest = "$nodeDeployRoot\tools\nuget.exe"
    Copy-NuGetExeToRemote $server $nugetExeDest

    $nugetRepoDest = "$nodeDeployRoot\nupkgs"
    Copy-NuDeployPkgToRemote $server $nugetRepoDest

    $installPath = "$nodeDeployRoot\tools"
    Install-NuDeployOnRemote $server $nugetExeDest $nugetRepoDest $installPath
    Write-Host "Node [$server] has been setup NuDeploy.`n" -f cyan
}
Function Clear-RemoteDeployRoot($server, $path) {
    Run-RemoteScript $server {
        param($path)
        if(Test-Path $path){
            Remove-Item $path -r -Force
        }
    } -argumentList $path | out-Default
}
Function Copy-NuGetExeToRemote($server, $nugetExeDest) {
    $nugetExeSource = "$PSScriptRoot\tools\nuget\nuget.exe"
    Copy-FileRemote $server $nugetExeSource $nugetExeDest | out-Default
}
Function Copy-NuDeployPkgToRemote($server, $nugetRepoDest) {
    $nupkg = Get-Item "$PSScriptRoot\..\*.nupkg"
    Copy-FileRemote $server $nupkg.FullName "$nugetRepoDest\$($nupkg.Name)" | out-Default
}
Function Install-NuDeployOnRemote($server, $nugetExeDest, $nugetRepoDest, $installPath) {
    Run-RemoteScript $server {
        param($nugetExeDest, $nugetRepoDest, $installPath)
        Write-Host "& $nugetExeDest install 'NScaffold.NuDeploy' -source $nugetRepoDest -NoCache -OutputDirectory $installPath"
        & $nugetExeDest install 'NScaffold.NuDeploy' -source $nugetRepoDest -NoCache -OutputDirectory $installPath
        if(-not($LASTEXITCODE -eq 0)){
            throw "Setup nuDeployPackage failed"
        }
    } -argumentList $nugetExeDest, $nugetRepoDest, $installPath | out-Default
}