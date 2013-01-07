throw "Here specify environment related settings which will be visible for all tasks, comment this line after all set. "

$buildNumber = $Env:BUILD_NUMBER
$packageManager = @{
    "generateVersion" = {"1.0.0.$buildNumber"}
    "store" = {
        param($pkgs)
        if (Test-Path "$packageOutputDir\pkgs.txt") {
            Remove-Item "$packageOutputDir\pkgs.txt"
        }
        $pkgs.GetEnumerator() | Sort-Object -Property Name | % { 
            Add-Content "$packageOutputDir\pkgs.txt" "$($_.Name).$($_.Value)"
        }
    }
    "retrive" = {
        $pkgs = @{}
        Get-Content "http://some/artifact/url/pkgs.txt" | % {
            $info = Get-PackageInfo $_
            $pkgs.Add($info.packageId, $info.version)
        }
        $pkgs
    }
}

# nuget package config
$packageConfig = @{
    "pushRepo" = "http://10.18.1.28/nuget-repo2"
    "apiKey" = "01634e7b-0c29-4c1d-b06f-d991b0730124"
    "pullRepo" = "http://10.18.1.28/nuget-repo2/nuget"
    "installDir" = "$tmpDir\working"
}