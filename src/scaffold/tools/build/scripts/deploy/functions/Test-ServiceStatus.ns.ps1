Function Test-ServiceStatus($name, $status) {
    $serv = Get-Service -Name $name -ErrorAction SilentlyContinue
    if($serv){
        if ( $status) {
            $serv.Status -eq $status
        }
        else {
            $true
        }       
    } else {
        $false  
    }   
}