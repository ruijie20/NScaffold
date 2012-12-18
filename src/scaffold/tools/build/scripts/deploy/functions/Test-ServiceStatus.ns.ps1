Function Test-ServiceStatus($name, $status) {
	$serv = Get-Service -Name $name -ErrorAction SilentlyContinue
	if($serv -and $status){
		$serv.Status -eq $status
	} else {
		$false	
	}   
}