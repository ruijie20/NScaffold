Function Generate-Config ($packageRoot, $packageId) {
    @{
        'siteName' = "$packageId-site"
        'physicalPath' = "$packageRoot\$sourcePath"
        'appPoolName' = "$packageId-app"
        'appPoolUser' = "$packageId-user"
        'appPoolPassword' = "$packageId-password"
    }
}