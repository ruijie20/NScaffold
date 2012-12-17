Function Generate-Config ($sourcePath, $packageId) {
    @{
        'siteName' = "$packageId"
        'physicalPath' = "$sourcePath"
        'appPoolName' = "$packageId-app"
        'appPoolUser' = "$packageId-user"
        'appPoolPassword' = "1111aaaa#"
    }
}

Function Generate-PackageConfig ($packageInfo) {
    $packageId = $packageInfo.packageId
    $sourcePath = $packageInfo.sourcePath
    @{
        'siteName' = "$packageId"
        'physicalPath' = "$sourcePath"
        'appPoolName' = "$packageId-app"
        'appPoolUser' = "$packageId-user"
        'appPoolPassword' = "1111aaaa#"
    }
}