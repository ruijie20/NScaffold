param(
  [string] $command
)

$root = Split-Path -parent $MyInvocation.MyCommand.Definition

if(!$libsRoot){
  $libsRoot = "$root\scripts\libs"
}

if(!$toolsRoot){
	$toolsRoot = "$root\tools"
}

Resolve-Path "$libsRoot\*.ps1" | 
    ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
    % { . $_.ProviderPath }

. PSRequire "$libsRoot\functions\"
. PSRequire "$root\scripts\commands\"

if(-not $command){
	Show-Help
}

switch -wildcard ($command) 
{
  "init" { Initialize-Project @args; }
  "help" { Show-Help; }
  default { Write-Host 'Please run NScaffold help'; }
}
