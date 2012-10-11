# here specify environment related settings which will be visible for all tasks
throw "comment this line after all set. "

# NUGET_REPO_PUSH = ""
# NUGET_API_KEY = ""

# NUGET_REPO_GET = "$rootDir\tmp\nupkgs"
# NUGET_PKG_VERSION_SRC = "$rootDir\tmp\nupkgs\version.txt"
# NUGET_PKG_INSTALL_DIR = "$rootDir\tmp\working"

# NUGET_REPO_PUSH = "http://10.18.1.28/nuget-repo2"
# NUGET_API_KEY = "01634e7b-0c29-4c1d-b06f-d991b0730124"

# NUGET_REPO_GET = "http://10.18.1.28/nuget-repo2/nuget"
# NUGET_PKG_VERSION_SRC = "http://10.18.8.119:8080/job/$jenkinsJobName/$jenkinsJobNo/artifact/tmp/nupkgs/version.txt"
# NUGET_PKG_INSTALL_DIR = "c:/working-packages"

# version manager, which support provide, store and read
$versionManager = @{
    "generate" = {"1.0.0.0"}
    "store" = {
        param($version)
        Set-Content $version "$packageOutputDir\version.txt" 
    }
    "retrive" = {
        Get-Content "$packageOutputDir\version.txt" 
    }
}

# nuget package config
$packageConfig = @{
    "pushRepo" = ""
    "apiKey" = ""
    "pullRepo" = "$packageOutputDir"
    "installDir" = "$tmpDir\working"
}