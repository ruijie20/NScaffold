Function Generate-Config ($sourcePath, $packageId) {
    @{
        'siteName' = "$packageId"
        'physicalPath' = "$sourcePath"
        'appPoolName' = "$packageId"
    }
}

Function Generate-PackageConfig ($packageInfo) {
    $packageId = $packageInfo.packageId
    $sourcePath = $packageInfo.sourcePath
    @{
        'siteName' = "$packageId"
        'physicalPath' = "$sourcePath"
        'appPoolName' = "$packageId"
    }
}