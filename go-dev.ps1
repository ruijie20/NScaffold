
$basePath = Split-Path -parent $MyInvocation.MyCommand.Definition

#$localSource = "$basePath\tmp\pkgs\".Replace("\", "/")
#$nugetSource = "file:///$localSource"
$libsRoot = join-path $basePath "src-libs"
$toolsRoot = join-path $basePath "tools"
 
. .\src\scaffold\tools\go.ns.ps1 @args
