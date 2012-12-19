USE [master]
 
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'$(Name)')
BEGIN
	CREATE LOGIN [$(Name)] FROM WINDOWS WITH DEFAULT_DATABASE=[master]
END
GO