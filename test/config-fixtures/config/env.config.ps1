$here = Split-Path -Parent $MyInvocation.MyCommand.Path

@{
	nugetRepo = "$TestDrive\nugetRepo"
	nodeDeployRoot = "$TestDrive\deployment_root"
	variables = @{
		ENV = "int"
		PWD ="TWr0ys1ngh4m"
		IISRoot = "C:\IIS"
		DBHost = 'localhost'
		MyTaxesDatabaseName = "MyTaxes"
		ConsentServicePort = 8888
	}
	apps = @(
	 	@{
			"server" = "localhost"
			"package" = "Test.Package"
			"features" = @("forceRedeploy")
	 	}
	)
}
