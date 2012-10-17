Function Generate-Config ($sourcePath, $packageId) {
    @{
        'siteName' = "$packageId"
        'physicalPath' = "$sourcePath"
        'appPoolName' = "$packageId-app"
        'appPoolUser' = "$packageId-user"
        'appPoolPassword' = "1111aaaa#"
    }
}