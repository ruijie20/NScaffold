Function Run-RemoteScript($server, [ScriptBlock]$scriptblock, $argumentList) {
	if($server -eq "localhost") {
		Push-Location
        try {
			Invoke-Command -scriptblock $scriptblock -ArgumentList $argumentList
		} finally {
            Pop-Location
        }
	}
	else {
		Invoke-Command -ComputerName $server -scriptblock $scriptblock -ArgumentList $argumentList
	}
}
