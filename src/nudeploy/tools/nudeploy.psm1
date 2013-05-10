Get-ChildItem "$PSScriptRoot\libs" -Filter *.ps1 -Recurse | 
    ? { -not ($_.Name.Contains(".Tests.")) } | % {
        . $_.FullName
    }
    
Get-ChildItem "$PSScriptRoot\functions" -Filter *.ps1 -Recurse | 
    ? { -not ($_.Name.Contains(".Tests.")) } | % {
        . $_.FullName
    }

Set-Alias nudeploy Install-NuDeployPackage
Set-Alias nudeployEnv Install-NuDeployEnv
Export-ModuleMember -Function Install-NuDeployPackage -Alias nudeploy
Export-ModuleMember -Function Install-NuDeployEnv -Alias nudeployEnv
