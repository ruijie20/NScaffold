Function Test-ServiceStatus($name, $status="Running") {
    (Get-Service -Name $name | ? {$_.Status -eq $status} | Measure-Object).Count -eq 1
}