USE [$(DatabaseName)]
GO
EXEC sp_addrolemember N'db_datareader', N'$(Username)'
GO
EXEC sp_addrolemember N'db_datawriter', N'$(Username)'
GO