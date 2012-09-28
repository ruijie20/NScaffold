
$basePath = Split-Path -parent $MyInvocation.MyCommand.Definition

$localSource = "$basePath\tmp\pkgs\".Replace("\", "/")
$nugetSource = "file:///$localSource"
$root = join-path $basePath "src\"

. .\src\install\tools\NScaffold.ps1 @args
