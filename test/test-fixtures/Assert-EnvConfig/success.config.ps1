$here = Split-Path -Parent $MyInvocation.MyCommand.Path

@{
	nugetRepo = "$TestDrive\nugetRepo"
	nodeDeployRoot = "$TestDrive\deployment_root"
	variables = @{
		ENV = "tst"
		User = "user"
	}
	apps = @(
	 	@{
			"server" = "localhost"
			"package" = "Test.Package"
	 	}
	)
}
