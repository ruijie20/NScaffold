$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$root = resolve-path "$here\..\.."
. "$root\src\nudeploy\tools\functions\Copy-FileRemote.ps1"

Describe "Copy-FileRemote" {
    It "should be able to copy a file to a remote non-existed folder" {
        $source = "$here\Copy-FileRemote.Tests.ps1"
        $randomNumber = [System.DateTime]::Now.Ticks
        $not_existed_folder = "$env:temp\not\existe\f$randomNumber"
        $dest = "$not_existed_folder\1.dat"

        if(Test-Path $not_existed_folder) {
            throw "not_existed_folder existed"
        }

        Copy-FileRemote "localhost" $source $dest

        if(-not(Test-Path $dest)) {
            throw "file not copied"
        }
    }
}

