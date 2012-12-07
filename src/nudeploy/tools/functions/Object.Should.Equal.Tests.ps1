Describe "object.should.equal" {
	It "should pass for two same object references" {
		$expected = New-Object PSObject -Property @{"key" = "value"}
		$actual = $expected
		$actual.should.equal($expected)
	}
	It "should pass for two strings with the same value" {
		$expected = "something"
		$actual = "something"
		$actual.should.equal($expected)
	}
	It "should fail for two strings with different values" {
		$expected = "something"
		$actual = "some other thing"
		$excpetionThrown = $false
		try {
			$actual.should.equal($expected)
		}
		catch {
			$excpetionThrown = $true
		}
		$excpetionThrown.should.be($true)
	}
	It "should pass for two hashtables with the same key-value pairs defined in the same order" {
		$expected = @{a = 1; b = 2}
		$actual = @{a = 1; b = 2}
		$actual.should.equal($expected)
	}
	It "should pass for two hashtables with the same key-value pairs defined in different order" {
		$expected = @{a = 1; b = 2}
		$actual = @{b = 2; a = 1}
		$actual.should.equal($expected)
	}
	It "should fail for two hashtables with different count of key-value pairs" {
		$expected = @{a = 1}
		$actual = @{a = 1; b = 1}
		$excpetionThrown = $false
		try {
			$actual.should.equal($expected)
		}
		catch {
			$excpetionThrown = $true
		}
		$excpetionThrown.should.be($true)
	}
	It "should fail for two hashtables with different keys" {
		$expected = @{a = 1}
		$actual = @{b = 1}
		$excpetionThrown = $false
		try {
			$actual.should.equal($expected)
		}
		catch {
			$excpetionThrown = $true
		}
		$excpetionThrown.should.be($true)
	}
	It "should fail for two hashtables with different values" {
		$expected = @{a = 1}
		$actual = @{a = 2}
		$excpetionThrown = $false
		try {
			$actual.should.equal($expected)
		}
		catch {
			$excpetionThrown = $true
		}
		$excpetionThrown.should.be($true)
	}
	It "should fail for two hashtables with different key-value pairs" {
		$expected = @{a = 1}
		$actual = @{b = 2}
		$excpetionThrown = $false
		try {
			$actual.should.equal($expected)
		}
		catch {
			$excpetionThrown = $true
		}
		$excpetionThrown.should.be($true)
	}
}