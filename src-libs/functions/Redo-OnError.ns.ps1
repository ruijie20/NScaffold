Function Redo-OnError($command, $argumentList, $timeout = 90, $retries = 3){
   # param ($command, $argumentList, $timeout = 90, $retries = 3)

    $timestamp = (Get-Date).Ticks
    $tempFile = New-Item "$($env:temp)\$timestamp.txt" -type File 
    $fileName = $tempFile.FullName
    while($retries -gt 0) {
        $retries = $retries - 1
        if($argumentList) {
            $p = Start-Process $command -ArgumentList $argumentList -NoNewWindow -RedirectStandardOutput $fileName -PassThru
        }
        else {
            $p = Start-Process $command -NoNewWindow -RedirectStandardOutput $fileName -PassThru 
        }

        Wait-Process -InputObject $p -Timeout $timeout -ErrorAction SilentlyContinue

        if($?) {
            $output = Get-Content $fileName
            Remove-Item $fileName
            return $output
        }

        Stop-Process -InputObject $p -ErrorAction SilentlyContinue
        Stop-Process -Name WerFault -ErrorAction SilentlyContinue
        Write-Host "Retry once more..."         
    }

    throw "Error when invoking command [$command] with arguments [$argumentList]"
}
