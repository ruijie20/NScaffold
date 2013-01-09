throw "Here specify environment related settings which will be visible for all tasks, comment this line after all set. "

@{
    "generateVersion" = {"1.0.0.0"}
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
        Get-Content "$packageOutputDir\pkgs.txt" | % {
            $info = Get-PackageInfo $_
            $pkgs.Add($info.packageId, $info.version)
        }        
        $pkgs
    }
    "pushRepo" = ""
    "apiKey" = ""
    "pullRepo" = "$packageOutputDir"
    "installDir" = "$tmpDir\working"
}
