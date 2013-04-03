Import-Module ServerManager

Function Install-WindowsFeature($windowsFeature) {
	if(-not (Get-WindowsFeature "$windowsFeature").Installed) {
		Write-Host "Installing Windows Feature: $windowsFeature" -f green
		Add-WindowsFeature "$windowsFeature"
	}
}
