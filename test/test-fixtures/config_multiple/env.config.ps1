$here = Split-Path -Parent $MyInvocation.MyCommand.Path

@{
	nugetRepo = "$TestDrive\nugetRepo"
	nodeDeployRoot = "$TestDrive\deployment_root"
	variables = @{
		ENV = "int"
		PWD ="password"
		IISRoot = "C:\IIS"
		DBHost = 'localhost'
		MyPackageDatabaseName = "MyPackage"
		MyServicePort = 8888
	}
	apps = @(
	 	@{
			"server" = "localhost"
			"package" = "Test.Package"
	 	},
	 	@{
			"server" = "localhost"
			"package" = "Test.Package.Multiple"
	 	}
	)
}
