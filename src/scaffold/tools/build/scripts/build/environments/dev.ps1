throw "Here specify environment related settings which will be visible for all tasks, comment this line after all set. "
# version manager
$versionManager = @{
    "generate" = {"1.0.0.0"}
    "store" = {
        param($version)
        Set-Content "$packageOutputDir\version.txt" $version
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