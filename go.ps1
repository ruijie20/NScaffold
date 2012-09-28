
$root = Split-Path -parent $MyInvocation.MyCommand.Definition

$localSource = "$root\tmp\pkgs\".Replace("\", "/")
$nugetSource = "file:///$localSource"

. .\src\install\tools\NScaffold.ps1 @args
