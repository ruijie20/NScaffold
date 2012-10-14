
throw "Here specify environment related settings which will be visible for all tasks, comment this line after all set. "

$buildNumber = $Env:BUILD_NUMBER
$versionManager = @{
    "generate" = {"1.0.0.$buildNumber"}
    "store" = {
        param($version)
        Set-Content $version "$packageOutputDir\version.txt" 
    }
    "retrive" = {
        Get-Content "http://10.18.8.119:8080/job/$jenkinsJobName/$jenkinsJobNo/artifact/tmp/nupkgs/version.txt" 
    }
}

# nuget package config
$packageConfig = @{
    "pushRepo" = "http://10.18.1.28/nuget-repo2"
    "apiKey" = "01634e7b-0c29-4c1d-b06f-d991b0730124"
    "pullRepo" = "http://10.18.1.28/nuget-repo2/nuget"
    "installDir" = "c:\working-packages"
}