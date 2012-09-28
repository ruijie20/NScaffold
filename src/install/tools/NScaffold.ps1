param(
  [string] $command
)

if(!$root){
  $root = Split-Path -parent $MyInvocation.MyCommand.Definition
}

Resolve-Path $root\core\*.ps1 | 
    ? { -not ($_.ProviderPath.Contains(".Tests.")) } |
    % { . $_.ProviderPath }

Include-PSFolder "$root\functions\"
Include-PSFolder ".\commands\"


if(-not $command){
	Show-Help
}

switch -wildcard ($command) 
{
  "init" { Initialize-Project @args; }
  "help" { Show-Help; }
  default { Write-Host 'Please run NScaffold help'; }
}
