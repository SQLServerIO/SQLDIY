/************************************************************************************************
Populate Server Table
By Wesley D. Brown
Date 8/30/2004
Mod 2/11/2005
Mod 2/20/2005

**Description**
This script is called from pull daily info job on primary management server.
It will attempt to identify all computers and test to see if they are a SQL Server.
It tests to see if the server is also active.
This runs once a day.

Functions:
Dump all machine names from net view domain command and catgorize them type MachineList
Use SQL DMO to pull a list of all SQL Servers on the network and catgorize them type SQLServer
Get IP Address and MAC Address of every computer on the network

**End Discription**

**Change Log**
Addition:
2/11/2005 added node descovery and clasification for servers running SQL 2000 SP3 or greater
bug Fix:
2/20/2005 server would ping but no mac address is reported
Addition:
2/20/2005 added config option to not to pull the mac address from all discovered machines
**End Change Log**
************************************************************************************************/
--insert into config values('MacAddresses','Yes')
set nocount on
--insert into AuditLog values('PopulateServerTable',getdate(),getdate())
/*****************************************
* Pull in all config values first
*****************************************/
declare @MacAddresses as varchar(255)

set @MacAddresses  = 'Yes'

/*****************************************
*Create all temp tables needed
*****************************************/
create table ##audit
(
ServerName varchar(255)
,pass varchar(50)
,tstamp datetime
)

create table ##instancedata
(
	computername varchar(255)
	,baseserver varchar(255)
	,port int
	,namedpipe varchar(255)
	,instance varchar(255)
)

create table #netview
(
	result varchar(8000)
)

create table #ping
(
	result varchar(8000)
)

create table #nbtstat
(
	result varchar(8000)
)

create table #psresults
(
	results varchar(8000)
)

create table #cmdout
(
	cmdout varchar(8000)
)
create table #active
(
	act int
)

create table ##clusternodes
(
	ServerName varchar(255)
)

declare @IPAddress varchar(20)
declare @cmd varchar(8000)
declare @flname varchar(255)
declare @hld varchar(8000)
DECLARE @retval int
DECLARE @result varchar(500)
DECLARE @object int 
DECLARE @objectList int 
DECLARE @src varchar(254)
DECLARE @desc varchar(255)
DECLARE @resultsCount int
DECLARE @counter int
DECLARE @method varchar(255)
declare @ServerName_hld as varchar(255)
declare @activedate datetime
DECLARE @ServerName varchar(255)
declare @iphld varchar(20) 
declare @active int

/**************************************************
Try to find all running SQL Servers using SQL DMO
**************************************************/
--create SQLDMO object
EXEC @retval = sp_OACreate 'SQLDMO.Application', @object OUT
-- check if object was created successfully
IF @retval <> 0 
	BEGIN
	   EXEC sp_OAGetErrorInfo @object, @src OUT, @desc OUT 
	   SELECT hr=convert(varbinary(4),@retval), Source=@src, Description=@desc
	   RETURN
	END
--call method ListAvailableServers() , get Object_ID for SQLDMO.NameList
EXEC @retval = sp_OAMethod @object , 'ListAvailableSQlServers()' , @objectList OUT
-- error ?
IF @retval <> 0 
	BEGIN
	   EXEC sp_OAGetErrorInfo @objectList, @src OUT, @desc OUT 
	   SELECT hr=convert(varbinary(4),@retval), Source=@src, Description=@desc
	   RETURN
	END
-- Count Servers in the neighborhood
EXEC @retval = sp_OAGetProperty @objectList , 'Count' , @resultsCount OUT
-- error handler again
IF @retval <> 0 
	BEGIN
	   EXEC sp_OAGetErrorInfo @objectList, @src OUT, @desc OUT 
	   SELECT hr=convert(varbinary(4),@retval), Source=@src, Description=@desc
	   RETURN
	END
-- If there are Servers , step into .....
IF @resultsCount > 0
	BEGIN
		SET @counter = 1
		DECLARE @ServersTbl table (ServerName varchar(255))
		WHILE @counter <= @resultsCount
			BEGIN
				-- List SQL Server : Name by Name 
				SET @method = 'Item(' + convert(varchar(3),@counter) + ')'								
				EXEC @retval = sp_OAGetProperty @objectList ,@method , @result OUT
				--if our result is local then get the local server name
				if @result = '(local)'
				select @result = cast(serverproperty('servername') as varchar(500))
				-- Store data in the temp table
				INSERT INTO @ServersTbl (ServerName) SELECT @result where @result not in(select ServerName from @ServersTbl)
				
				-- move to next record
				SET @counter = @counter + 1
			END
	END
ELSE
	BEGIN
		INSERT INTO @ServersTbl (ServerName) SELECT @result
	END
-- kill object
EXEC @retval = sp_OADestroy @object
IF @retval <> 0
BEGIN
   EXEC sp_OAGetErrorInfo @object, @src OUT, @desc OUT 
   SELECT hr=convert(varbinary(4),@retval), Source=@src, Description=@desc
   RETURN
END

/**************************************************
Update the ActiveAsOf column if the server was 
found on this pass
**************************************************/
update
	Server
set 
	LastScan = getdate()
where
	ServerName in (Select ServerName from @ServersTbl)

/**************************************************
Insert any new servers that DMO found
**************************************************/
insert into Server (ServerName ,LastScan, CreateDate, ActiveLastScan)
select distinct
	ServerName
	,getdate() as ActiveAsOf
	, getdate() as CreateDate 
	, 1
from
	@ServersTbl
where
	ServerName not in
			(
				select
					ServerName
				from
					Server
			)

/**************************************************
Supertype them as SQLServer
**************************************************/
insert into ServerType (SID,SRLID)
select distinct
	SID,
	(select SRLID from ServerRole where type = 'SQLServer')
from
	server
where
	SID not in
			(
				select
					s.SID
				from
					ServerType st
					inner join
					ServerRole sr
					on st.SRLID=sr.SRLID
					inner join
					Server s
					on s.sid = st.sid
				where 
					Type = 'SQLServer'
			)



--/**************************************************
--Add any server not in machine list to it
--**************************************************/
--insert into ServerType 
--select distinct
--	SID,
--	(select SRLID from ServerRole where type = 'MachineList')
--from
--	server
--where
--	SID not in
--			(
--				select
--					SID
--				from
--					ServerType st
--					inner join
--					ServerRole sr
--					on st.SRLID=sr.SRLID
--					inner join
--					Server s
--					on s.sid = st.sid
--				where 
--					Type = 'MachineList'
--			)
--and
--charindex('\',ServerName,0) = 0
--union all
--select distinct
--	SID,
--	(select SRLID from ServerRole where type = 'MachineList')
--from
--	server
--where
--	SID not in
--			(
--				select
--					SID
--				from
--					ServerType st
--					inner join
--					ServerRole sr
--					on st.SRLID=sr.SRLID
--					inner join
--					Server s
--					on s.sid = st.sid
--				where 
--					Type = 'MachineList'
--			)

--select 
--	distinct substring(ServerName,0,len(ServerName)-len(substring(ServerName,charindex('\',ServerName,0),len(ServerName)))+1) as ServerName,'MachineList'
--from
--	Server
--where
--	substring(ServerName,0,len(ServerName)-len(substring(ServerName,charindex('\',ServerName,0),len(ServerName)))+1) not in
--			(
--				Select
--					ServerName
--				from
--					ServerType
--				where
--					Type = 'MachineList'
--			)
--and
--	charindex('\',ServerName,0) > 0

--/**************************************************
--Find all named instances from the machine name
--**************************************************/

--DECLARE nbtstat CURSOR
--FAST_FORWARD
--FOR
--Select ServerName from ServerType where Type = 'MachineList'

--OPEN nbtstat

--FETCH NEXT FROM nbtstat INTO @ServerName
--WHILE (@@fetch_status <> -1)
--BEGIN
--	IF (@@fetch_status <> -2)
--	BEGIN

--		/**************************************************
--		Get MACAddress and IPAddress of every server
--		**************************************************/
--		truncate table #nbtstat
--		truncate table #ping

--		set @cmd = 'master..xp_cmdshell ''ping  "'+@ServerName+'" -n 1'''
--		insert into #ping
--		exec(@cmd)

--		update
--			Server
--		set
--			IPAddress = 
--				(
--					select
--						ltrim(rtrim(right(substring(result,charindex('[',result),(charindex(']',result)-charindex('[',result))),(charindex(']',result)-charindex('[',result))-1)))
--					from
--						#ping
--					where
--						result like '%Pinging%'
--				)

--		where
--			ServerName = @ServerName

--		set @iphld = (select ltrim(rtrim(right(substring(result,charindex('[',result),(charindex(']',result)-charindex('[',result))),(charindex(']',result)-charindex('[',result))-1))) as ip from #ping where result like '%Pinging%')
--		set @iphld = ltrim(rtrim(@iphld))

--		truncate table #active

--		insert into #active
--		exec('select count(result) as active from #ping where result like ''%'+@iphld+'%'' and result like ''%Reply%''')
--		if (select act from #active) = 1
--		begin
--			if @MacAddresses = 'No'
--			begin
--				if exists (select ServerName from ServerType where ServerName = @ServerName and Type = 'SQLServer')
--				begin
--					set @cmd = 'master..xp_cmdshell ''nbtstat -a "'+@ServerName+'"'''
--					insert into #nbtstat
--					exec(@cmd)

--					update Server set MACAddress = (select ltrim(rtrim(replace(ltrim(rtrim(reverse(substring(reverse(rtrim(ltrim(result))),0,charindex('=',reverse(ltrim(rtrim(result))),0))))),'-',''))) from #nbtstat where charindex('=',result,0) > 0) where ServerName = @ServerName
--					update Server set IPAddress = @iphld where ServerName = @ServerName
--					if (Select MACAddress from Server where ServerName = @ServerName) is null
--					begin
--						set @cmd = 'master..xp_cmdshell ''nbtstat -A "'+@iphld+'"'''
--						insert into #nbtstat
--						exec(@cmd)
--						update Server set MACAddress = (select ltrim(rtrim(replace(ltrim(rtrim(reverse(substring(reverse(rtrim(ltrim(result))),0,charindex('=',reverse(ltrim(rtrim(result))),0))))),'-',''))) from #nbtstat where charindex('=',result,0) > 0) where ServerName = @ServerName
--					end
--				end
--			end
--			else
--			begin
--				set @cmd = 'master..xp_cmdshell ''nbtstat -a "'+@ServerName+'"'''
--				insert into #nbtstat
--				exec(@cmd)

--				update Server set MACAddress = (select top 1 ltrim(rtrim(replace(ltrim(rtrim(reverse(substring(reverse(rtrim(ltrim(result))),0,charindex('=',reverse(ltrim(rtrim(result))),0))))),'-',''))) from #nbtstat where charindex('=',result,0) > 0) where ServerName = @ServerName
--				update Server set IPAddress = @iphld where ServerName = @ServerName
--				if (Select distinct MACAddress from Server where ServerName = @ServerName) is null
--				begin
--					set @cmd = 'master..xp_cmdshell ''nbtstat -A "'+@iphld+'"'''
--					insert into #nbtstat
--					exec(@cmd)

--					update Server set MACAddress = (select top 1 ltrim(rtrim(replace(ltrim(rtrim(reverse(substring(reverse(rtrim(ltrim(result))),0,charindex('=',reverse(ltrim(rtrim(result))),0))))),'-',''))) from #nbtstat where charindex('=',result,0) > 0) where ServerName = @ServerName
--				end
--			end
--			update Server set ActiveAsOf = getdate() where ServerName = @ServerName
--			exec('update Server set ActiveAsOf = getdate() where ServerName like '''+@ServerName+'\%'' and charindex(''\'',ServerName,0) > 0')
--		end

--		truncate table #cmdout
--		truncate table #psresults

--		if  (Select count(ServerName) from ServerType where Type = 'SQLServer' and ServerName = @ServerName) = 0
--		begin
--			insert into #psresults
--			exec ('master.dbo.xp_cmdshell ''\\fs2\DatabaseBU\sharedfiles\yaps.exe -start -resolve y -start_port 1433 -stop_port 1433 -start_address '+@IPAddress+' -stop_address '+@IPAddress+' -timeout 1''')
--		end

--		delete from #psresults where results like '%Started scan%'
--		delete from #psresults where results like '%Stopping scan%'
--		delete from #psresults where results is null

--		insert into ServerType
--		select
--			ServerName
--			,'SQLServer' as ServerType
--		from 
--			(
--				select 
--					upper(ltrim(rtrim(substring(results,charindex(' ',results),charindex('.',results,(charindex(' ',results)-1))-charindex(' ',results))))) as ServerName 
--				from
--					#psresults
--				where
--					results like '%mcr%'
--				and
--					upper(ltrim(rtrim(substring(results,charindex(' ',results),charindex('.',results,(charindex(' ',results)-1))-charindex(' ',results))))) not in (Select ServerName from ServerType where Type = 'SQLServer')
--			) a 

--		if  (Select count(ServerName) from ServerType where Type = 'SQLServer' and ServerName = @ServerName) > 0
--		begin
--			set @cmd = 'osql -S '+@ServerName+' -l 1 -E  -d management -i "'+@UNCPathScripts+'reporting\instancename.sql"'
--			exec master..xp_cmdshell @cmd,no_output 
--			set @flname = ltrim(rtrim(replace(@ServerName,'\','_')))
--			exec('master..xp_cmdshell ''bcp "tempdb.##instancedata" in "'+@UNCPathDataGathering+'InstanceName\'+@flname+'_ver.txt" -c -C ''''RAW'''' -T'',no_output') 
--			exec('master..xp_cmdshell ''bcp "tempdb.##clusternodes" in "'+@UNCPathDataGathering+'InstanceName\'+@flname+'_clusternodes.txt" -c -C ''''RAW'''' -T'',no_output') 
--		end
--	END
--	FETCH NEXT FROM nbtstat INTO @ServerName
--END

--CLOSE nbtstat
--DEALLOCATE nbtstat

--/**************************************************
--Insert any new servers that are not in the list
--**************************************************/
--insert into Server
--select distinct ServerName,null as IPAddress,Port,null as MACAddress,getdate() as ActiveAsOf,getdate() as CreateDate
--from
--(
--select 
--	ServerName = 
--	CASE instance 
--		WHEN 'DEFAULT_INSTANCE' THEN namedpipe
--		else
--			namedpipe+'\'+instance	
--	END
--	,port
--from
--##instancedata
--) a
--where ServerName <> '' and ServerName not in (select ServerName from Server)

--/**************************************************
--Insert any new cluster nodes descovered
--**************************************************/
--insert into Server
--select distinct ServerName,null as IPAddress,null as Port,null as MACAddress,getdate() as ActiveAsOf,getdate() as CreateDate
--from
--(
--select 
--	ServerName
--from
--	##clusternodes
--) a
--where ServerName <> '' and ServerName not in (select ServerName from Server)

--/**************************************************
--Set the type to Node for all servers in 
--##clusternodes table
--**************************************************/
--insert into ServerType 
--select
--	a.ServerName
--	,'Node' as Type
--from
--(
--	select distinct ServerName
--	from
--	(
--		select 
--			distinct 
--			ServerName
--		from
--		##clusternodes
--	) a
--	where ServerName <> ''
--) a
--where
--	a.ServerName not in
--			(
--				select
--					ServerName
--				from
--					ServerType
--				where 
--					Type = 'Node'
--			)


--/**************************************************
--update the server table with the port number
--if there is one
--**************************************************/
--update 
--	Server
--set
--	Port = a.Port
--from
--(
--	select distinct ServerName,port
--	from
--	(
--	select 
--		ServerName = 
--		CASE instance 
--			WHEN 'DEFAULT_INSTANCE' THEN namedpipe
--			else
--				namedpipe+'\'+instance	
--		END
--		,port
--	from
--	##instancedata
--	) a
--	where ServerName <> ''
--)a
--inner join
--Server b
--on
--a.ServerName = b.ServerName

--/**************************************************
--Add Server to SQLServer supertype
--**************************************************/
--insert into ServerType 
--select
--	a.ServerName
--	,'SQLServer' as Type
--from
--(
--	select distinct ServerName
--	from
--	(
--	select 
--		ServerName = 
--		CASE instance 
--			WHEN 'DEFAULT_INSTANCE' THEN namedpipe
--			else
--				namedpipe+'\'+instance	
--		END
--		,port
--	from
--	##instancedata
--	) a
--	where ServerName <> ''
--) a
--where
--	a.ServerName not in
--			(
--				select
--					ServerName
--				from
--					ServerType
--				where 
--					Type = 'SQLServer'
--			)


--/**************************************************
--Set IP and MAC addresses of named instances
--*************************************************/
--UPDATE
--	Server 
--set

--	MACAddress = a.MACAddress
--	,IPAddress = a.IPAddress
--	,ActiveAsOf = a.ActiveAsOf
--FROM 
--	Server a
--where
--	a.IPAddress is not null
--and
--	charindex('\',a.ServerName,0) > 0


--/**************************************************
--insert any named instances into the ServerType
--table
--**************************************************/
--insert into ServerType 
--select
--	ServerName
--	,'SQLServer' as Type
--from
--	Server
--where
--	ServerName not in
--			(
--				select
--					ServerName
--				from
--					ServerType
--				where 
--					Type = 'SQLServer'
--			)
--and
--	charindex('\',ServerName,0) > 0


--/**************************************************
--This is a place holder used by other scripts
--NA must exist for every server.
--**************************************************/
--insert DB
--select
--	'NA' as DBName
--	, ServerName
--	, 0 as BackupFlag
--	, getdate()
--	, getdate()
--from
--	Server
--where
--	ServerName not in (select distinct ServerName from DB where DBName = 'NA')

drop table ##clusternodes
drop table ##instancedata
drop table #active
drop table #cmdout
drop table #ping
drop table #netview
drop table #nbtstat
drop table #psresults
drop table ##audit

set nocount off
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       