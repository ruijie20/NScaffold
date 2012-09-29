Function Merge-Hashtable($hashtable1, $hashtable2) {
	$hashtable2.GetEnumerator() | % {
		if($_.value -ne $null) {
  			$hashtable1[$_.key] = $_.value
  		}
	}
	return $hashtable1
}
