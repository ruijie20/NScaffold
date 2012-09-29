
$basePath = Split-Path -parent $MyInvocation.MyCommand.Definition

$localSource = "$basePath\tmp\pkgs\".Replace("\", "/")
$nugetSource = "file:///$localSource"
$libsRoot = join-path $basePath "src-libs\"
$toolsRoot = join-path $basePath "tools\"

. .\src\ns-install\tools\nscaffold.ps1 @args
