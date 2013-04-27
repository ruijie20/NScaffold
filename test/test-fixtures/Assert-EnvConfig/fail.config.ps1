$here = Split-Path -Parent $MyInvocation.MyCommand.Path

@{
	nugetRepo = "$TestDrive\nugetRepo"
	nodeDeployRoot = "$TestDrive\deployment_root"
	variables = @{
		ENV = "tst"
	}
	apps = @(
	 	@{
			"server" = "localhost"
			"package" = "Test.Package"
	 	}
	)
}
