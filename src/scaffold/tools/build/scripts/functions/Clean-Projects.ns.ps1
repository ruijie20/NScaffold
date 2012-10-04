
Function Clean-Projects ($projectDirs) {
    $projectDirs | 
        ? { Test-Path $_ } | 
        Get-ChildItem -include bin,obj -Recurse | 
        ? { $_.attributes -eq "Directory" } | 
        Remove-Item -Force -Recurse
}
