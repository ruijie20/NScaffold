Function Convert-WinNTUsername($username) {
	$ComputerName = $env:UserDomain

    if($username -match "^{localhost}\\(.+)") {
        "$ComputerName\$($matches[1])"
    }
    elseif(-not ($username -like "*\*")) {
        "$ComputerName\$username"
    }
    else {
        $username
    }
}