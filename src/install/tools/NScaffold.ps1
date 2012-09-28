param(
  [string] $command
)

$root = Split-Path -parent $MyInvocation.MyCommand.Definition

Resolve-Path $root\commands\*.ps1 | 
    ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
    % { . $_.ProviderPath }

if(Test-Path "config.ps1"){
	. "config.ps1"
}

$localRepo =  Join-Path $env:appdata "NScaffold\scaffolds\"

if(-not $command){
	Show-Help
}

switch -wildcard ($command) 
{
  "init" { Initialize-Project @args; }
  "help" { Show-Help; }
  default { Write-Host 'Please run NScaffold help'; }
}
