Function Resolve-Variables($configPath, $context, $startSymbol = "\[", $endSymbol = "\]") {
    $variables = Import-Config $configPath
	$variableGroup = Group-Variables $variables $startSymbol $endSymbol
	while($variableGroup.unresolved.count -gt 0) {
		if(-not (Resolve-InContext $variableGroup $context $startSymbol $endSymbol)) {
			$errorInfo = New-Object PSObject -prop $variableGroup.unresolved | Out-String
			throw "Cannot finish resolving $configPath file because some value of placeholder is not defined!`n$errorInfo"
		}
	}
	$variableGroup.resolved
}

Function Group-Variables($variables, $startSymbol, $endSymbol) {
	$variableGroup = @{ resolved = @{}; unresolved = @{} }
	$variables.getEnumerator() | % {
		if(Test-ValueResovled $_.value $startSymbol $endSymbol) {
			$variableGroup.resolved[$_.key] = $_.value
		}
		else {
			$variableGroup.unresolved[$_.key] = $_.value
		}
	}
	$variableGroup
}

Function Test-ValueResovled($value, $startSymbol, $endSymbol) {
	$placeholderPattern = "$startSymbol[^$endSymbol]*$endSymbol"
	-not ($value -match $placeholderPattern)
}

Function Resolve-InContext($variableGroup, $context, $startSymbol, $endSymbol) {
	$newlyResolvedKeys = @()
	$variableGroup.unresolved.getEnumerator() | % {
		$mergedContext = Merge-Hashtable $context $variableGroup.resolved
		$_.value = Replace-Placeholder $_.value $mergedContext $startSymbol $endSymbol

		if(Test-ValueResovled $_.value $startSymbol $endSymbol) {
			$variableGroup.resolved[$_.key] = $_.value
			$newlyResolvedKeys = $newlyResolvedKeys + $_.key
		}
	}
	$newlyResolvedKeys | % { $variableGroup.unresolved.remove($_) }
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