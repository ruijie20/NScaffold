USE [master]
IF EXISTS (SELECT * FROM sys.server_principals WHERE name = N'$(Name)')
BEGIN
DROP LOGIN [$(Name)]
END
