USE [$(ApplicationDatabaseName)]

IF NOT EXISTS (SELECT * FROM sysusers where name = N'$(Name)')	
BEGIN 
	CREATE USER [$(Name)] FOR LOGIN [$(Name)]
END
GO