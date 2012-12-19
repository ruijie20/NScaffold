USE [master]
IF EXISTS (SELECT name FROM sys.databases WHERE name = N'$(DatabaseName)') 
BEGIN	
	 
	declare @spid varchar(15), @killstring varchar(20)

	select convert(varchar(15), spid) AS spid
	into #procs
	from master..sysdatabases sd, master..sysprocesses sp
	where sd.name in ('$(DatabaseName)') and sd.dbid = sp.dbid and spid >= 50
	set rowcount 1

	while (select count(*) from #procs) > 0
	begin
	       select @spid = spid from #procs
	       select @killstring = 'kill ' + @spid
	       exec (@killstring)
	       print 'Killed session ' + @spid + ' on $(DatabaseName) database'
	       delete from #procs where spid = @spid
	end

	set rowcount 0

	ALTER DATABASE [$(DatabaseName)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE

	drop table #procs

	DROP DATABASE [$(DatabaseName)]

END
GO