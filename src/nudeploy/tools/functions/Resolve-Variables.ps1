Function Resolve-Variables($hashTable, $startSymbol = "\[", $endSymbol = "\]") {
	$context = Build-ResolvingContext $hashTable $startSymbol $endSymbol
	while($context.unresolved.count -gt 0) {
		if(-not (Resolve-InContext $context $startSymbol $endSymbol)) {
			$errorInfo = New-Object PSObject -prop $context.unresolved | Out-String
			throw "Cannot finish resolving because some value of placeholder is not defined!`n$errorInfo"
		}
	}
	$context.resolved
}

Function Build-ResolvingContext($hashTable, $startSymbol, $endSymbol) {
	$context = @{ resolved = @{}; unresolved = @{} }
	$hashTable.getEnumerator() | % {
		if(Test-ValueResovled $_.value $startSymbol $endSymbol) {
			$context.resolved[$_.key] = $_.value
		}
		else {
			$context.unresolved[$_.key] = $_.value
		}
	}
	$context
}

Function Test-ValueResovled($value, $startSymbol, $endSymbol) {
	$placeholderPattern = "$startSymbol[^$endSymbol]*$endSymbol"
	-not ($value -match $placeholderPattern)
}

Function Resolve-InContext($context, $startSymbol, $endSymbol) {
	$newlyResolvedKeys = @()
	$context.unresolved.getEnumerator() | % {
		$_.value = Replace-Placeholder $_.value $context.resolved $startSymbol $endSymbol

		if(Test-ValueResovled $_.value $startSymbol $endSymbol) {
			$context.resolved[$_.key] = $_.value
			$newlyResolvedKeys = $newlyResolvedKeys + $_.key
		}
	}
	$newlyResolvedKeys | % { $context.unresolved.remove($_) }
	$newlyResolvedKeys.count -gt 0
}

Function Replace-Placeholder($value, $placeholderDef, $startSymbol = "\[", $endSymbol = "\]") {
	Extract-Placeholder $value $startSymbol $endSymbol | % {
		if($placeholderDef.keys -contains $_) {
			$value = $value -replace "$startSymbol$_$endSymbol", $placeholderDef[$_]
		}
	}
	$value
}

Function Extract-Placeholder($value, $startSymbol, $endSymbol) {
	$placeholders = @()
	$value | Select-String -AllMatches -Pattern "$startSymbol([^$endSymbol]*)$endSymbol" `
		| Select-Object -ExpandProperty Matches `
		| %{ $placeholders = $placeholders + $_.groups[1].value}
	$placeholders
}