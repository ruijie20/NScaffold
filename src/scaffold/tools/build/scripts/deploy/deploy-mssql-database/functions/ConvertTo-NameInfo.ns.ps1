Function ConvertTo-NameInfo($username) {
    $result = @{
        'prefix' = $env:COMPUTERNAME
    }
    if ($username -match '(?:(?<prefix>[^\\]+)\\)?(?<name>.+)' ) {
        if ($result.prefix -ne '{localhost}'){
            $result.prefix = $Matches.prefix
        }            
        $result.name = $Matches.name
    }
    $result
}