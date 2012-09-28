
$root = Split-Path -parent $MyInvocation.MyCommand.Definition

$localSource = "$root\tmp\pkgs\".Replace("\", "/")

$config = @{
    "nuget" = "$root\nuget\nuget.exe"
    "scaffoldSource" = "file:///$localSource"
}

. .\src\install\tools\NScaffold.ps1 @args
