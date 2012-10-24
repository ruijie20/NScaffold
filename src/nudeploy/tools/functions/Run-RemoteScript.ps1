Function Run-RemoteScript($server, [ScriptBlock]$scriptblock, $argumentList) {
	if($server -eq "localhost") {
		Save-Location {
			Invoke-Command -scriptblock $scriptblock -ArgumentList $argumentList
		}
	}
	else {
		Invoke-Command -ComputerName $server -scriptblock $scriptblock -ArgumentList $argumentList
	}
}

Function Save-Location([ScriptBlock]$action) {
    Push-Location
    Try {
        & $action
    } Finally {
        Pop-Location
    }
}
