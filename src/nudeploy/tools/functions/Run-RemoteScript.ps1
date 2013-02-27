Function Run-RemoteScript($server, [ScriptBlock]$scriptblock, $argumentList) {
	if($server -eq "localhost") {
		Push-Location
        try {
			Invoke-Command -ErrorVariable ice -scriptblock $scriptblock -ArgumentList $argumentList
			if($ice){throw $ice}
		} finally {
            Pop-Location
        }
	}
	else {
		Invoke-Command -ErrorVariable ice -ComputerName $server -scriptblock $scriptblock -ArgumentList $argumentList
		if($ice){throw $ice}
	}
}
