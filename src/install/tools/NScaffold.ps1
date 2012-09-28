param(
  [string] $command
)

$localRoot = Split-Path -parent $MyInvocation.MyCommand.Definition
if(!$root){
  $root = $localRoot
}


Resolve-Path $root\core\*.ps1 | 
    ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
    % { . $_.ProviderPath }


Extract-PsFiles "$root\functions\" | % { . $_.ProviderPath }
Extract-PsFiles "$localRoot\commands\" | % { . $_.ProviderPath }

if(-not $command){
	Show-Help
}

switch -wildcard ($command) 
{
  "init" { Initialize-Project @args; }
  "help" { Show-Help; }
  default { Write-Host 'Please run NScaffold help'; }
}
