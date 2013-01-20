Function Get-DeployNodes ($dirs, [string[]]$packageIds){
    $nodes = $dirs | Get-ChildItem -include *.nuspec -Recurse | % { 
        $packageId = Get-PackageId $_
        $packageConfig = Get-PackageConfig $_
        $prj = Get-ChildItem $_.Directory -filter *.csproj
        @{
            'id' = $packageId
            'spec' = $_
            'project' = $prj
            'profile' = $packageConfig.profile
            'type' = $packageConfig.type
        }
    } 
    if ($packageIds) {
        $nodes = $nodes | ? { $packageIds -contains $_.id }
    }
    $nodes
}
