
&.\pack.ps1

$dir = Join-Path $(Split-Path -parent $MyInvocation.MyCommand.Definition) "tmp\pkgs\"
$url = $dir.Replace("\", "/")

&nscaffold.bat @args -s "file:///$url"