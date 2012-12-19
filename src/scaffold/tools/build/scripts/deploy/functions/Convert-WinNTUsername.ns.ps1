Function Convert-WinNTUsername($username) {
    if($username -match "^{localhost}\\(.+)") {
        "$($env:COMPUTERNAME)\$($matches[1])"
    }
    elseif(-not ($username -like "*\*")) {
        "$($env:COMPUTERNAME)\$username"
    }
    else {
        $username
    }
}