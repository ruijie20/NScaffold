Function Patch-Config ([Parameter(ValueFromPipeline = $true)]$target, $patch) {
  process{
    $result = @{}
    $target.GetEnumerator() | % {
      if($_.value -ne $null) {
        $result[$_.key] = $_.value
      }
    }
    
    $patch.GetEnumerator() | % {
      if($_.value -ne $null) {
        if (-not $result[$_.key]){
          $result[$_.key] = $_.value  
        }       
      }
    }
    write-output $result
  }
}
