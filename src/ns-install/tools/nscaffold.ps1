param(
  [Parameter(Mandatory=$true)][string] $command,
  [string] $targetDir,
  [alias("s")][string] $scaffoldSource = ""
)

$root = Split-Path -parent $MyInvocation.MyCommand.Definition

$libsRoot = "$root\scripts\libs"
$nuget = "$root\tools\nuget\nuget.exe"

Resolve-Path "$libsRoot\*.ps1" | 
    ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
    % { . $_.ProviderPath }

. PS-Require "$libsRoot\functions\"
. PS-Require "$root\scripts\commands\"

if(-not $command){
	Show-Help
}

if($scaffoldSource){
	$nugetSource = $scaffoldSource
}

switch -wildcard ($command) 
{
  "init" { Initialize-Project $targetDir; }
  "clean" { 
  	if($targetDir){
  		Clean-Scaffold $targetDir
  	} else {
  		$localRepo =  Join-Path $env:appdata "NScaffold\scaffolds\"
  		if(test-path $localRepo){
  			Remove-Item $localRepo -Force -Recurse
  		}
  	}
  }
  "help" { Show-Help; }
  default { Write-Host 'Please run NScaffold help'; }
}
