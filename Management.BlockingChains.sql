---------------------------------------------------------------------------------------
--  BlockingChains tables
--  by: Wesley D. Brown
--  date: 02/08/2011
--  mod:  

--  description:
--	Tables needed for AlertOnBlocking stored procedure
--  parameters:
--  platforms:
--  SQL Server 2005
--  SQL Server 2008
--  SQL Server 2008 R2
--  tested:
--  SQL Server 2005 SP2
--  SQL Server 2008 R2
---------------------------------------------------------------------------------------
--  *** change log		***
--  *** end change log	***
---------------------------------------------------------------------------------------
--USE <Management>
GO
IF EXISTS (SELECT
             *
           FROM
             dbo.sysobjects
           WHERE
            id = Object_id(N'[dbo].[BlockingChains]')
            AND Objectproperty(id, N'IsTable') = 1)
  DROP TABLE [dbo].[BlockingChains]
GO
CREATE TABLE [dbo].[BlockingChains] (
	[ServerName] [varchar] (255) NOT NULL,
	[SampleTime] [datetime] NOT NULL ,
	[Spid] [int] NULL ,
	[SpidBlocked] [int] NULL ,
	[WaitType] [varchar] (255) NULL ,
	[WaitTime] [bigint] NULL ,
	[PhysicalIO] [bigint] NULL ,
	[CPUInSeconds] [bigint] NULL ,
	[MemoryUsed] [bigint] NULL ,
	[Name] [nvarchar] (128)  NOT NULL ,
	[NumberOfOpenTransactions] [tinyint] NULL ,
	[Status] [varchar] (20)  NULL ,
	[HostName] [varchar] (50)  NULL ,
	[ProgramName] [varchar] (100)  NULL ,
	[CommandIssued] [varchar] (100)  NULL ,
	[DomainName] [varchar] (100)  NULL ,
	[DomainUserName] [varchar] (200)  NULL ,
	[LoginName] [varchar] (100)  NULL ,
	[EventTpe] [varchar] (255)  NULL ,
	[Parameters] [varchar] (255)  NULL ,
	[EventInfo] [varchar] (4000)  NULL ,
	[CommandText] [varchar] (max)  NULL
)
GO

IF EXISTS (SELECT
             *
           FROM
             dbo.sysobjects
           WHERE
            id = Object_id(N'[dbo].[BlockingChainsHistory]')
            AND Objectproperty(id, N'IsTable') = 1)
  DROP TABLE [dbo].[BlockingChainsHistory]
GO

CREATE TABLE [dbo].[BlockingChainsHistory] (
	[ServerName] [varchar] (255) NOT NULL,
	[SampleTime] [datetime] NOT NULL ,
	[Spid] [int] NULL ,
	[SpidBlocked] [int] NULL ,
	[WaitType] [varchar] (255) NULL ,
	[WaitTime] [bigint] NULL ,
	[PhysicalIO] [bigint] NULL ,
	[CPUInSeconds] [bigint] NULL ,
	[MemoryUsed] [bigint] NULL ,
	[Name] [nvarchar] (128)  NOT NULL ,
	[NumberOfOpenTransactions] [tinyint] NULL ,
	[Status] [varchar] (20)  NULL ,
	[HostName] [varchar] (50)  NULL ,
	[ProgramName] [varchar] (100)  NULL ,
	[CommandIssued] [varchar] (100)  NULL ,
	[DomainName] [varchar] (100)  NULL ,
	[DomainUserName] [varchar] (200)  NULL ,
	[LoginName] [varchar] (100)  NULL ,
	[EventTpe] [varchar] (255)  NULL ,
	[Parameters] [varchar] (255)  NULL ,
	[EventInfo] [varchar] (4000)  NULL ,
	[CommandText] [varchar] (max)  NULL
)
GO

--USE Management

GO
---------------------------------------------------------------------------------------
--  AlertOnBlocking
--  by: Wesley D. Brown
--  date: 02/08/2011
--  mod:  

--  description:
--	This stored procedure is used to track and alert on blocking chains
--

--  parameters:
--	@Duration          DATETIME = '08:00:00',	-- Duration of data collection in hours.
--	@IntervalInSeconds       INT = 30,-- Approximate time in seconds the gathering interval.
--	@MaximumWaitTime       INT = 28000,	-- This is in milliseconds.
--	@Recivers          VARCHAR(8000) = 'test@email.com',	-- Who all gets the emails.
--	@ProcessesToIgnore VARCHAR(8000) = '',	-- Ignore any processes that you don't want to trigger an alert.
--	@HostsToIgnore     VARCHAR(8000) = '',	-- Ignore any host that you don't want to trigger an alert.
--	@LoginsToIgnore    VARCHAR(8000) = ''	-- Ignore any login that you don't want to trigger an alert.
--  usage:

--	EXEC @RC = AlertOnBlocking
--	  '08:00:00',
--	  30,
--	  28000,
--	  'test@email.com',
--	  '',
--	  '',
--	  ''

--  platforms:
--  SQL Server 2005
--  SQL Server 2008
--  SQL Server 2008 R2
--  tested:
--  SQL Server 2005 SP2
--  SQL Server 2008 R2
---------------------------------------------------------------------------------------
--  *** change log		***
--	Added history table and perge on start up if there is data in the main table
--  *** end change log	***
---------------------------------------------------------------------------------------
--USE <Management>
CREATE PROCEDURE AlertOnBlocking 
								-- Duration of data collection in hours.
								@Duration          DATETIME = '08:00:00',
								-- Approximate time in seconds the gathering interval.
								@IntervalInSeconds       INT = 30,
								-- This is in milliseconds.
								@MaximumWaitTime       INT = 28000,
								-- Who all gets the emails.
								@Recivers          VARCHAR(8000) = 'test@email.com',
								-- Ignore any processes that you don't want to trigger an alert.
								@ProcessesToIgnore VARCHAR(8000) = '',
								-- Ignore any host that you don't want to trigger an alert.
								@HostsToIgnore     VARCHAR(8000) = '',
								-- Ignore any login that you don't want to trigger an alert.
								@LoginsToIgnore    VARCHAR(8000) = ''
AS
	SET nocount ON
  
	IF EXISTS (SELECT
			   1
			 FROM
			   dbo.BlockingChains)
	BEGIN
		IF EXISTS (SELECT
					 *
				   FROM
					 dbo.sysobjects
				   WHERE
					id = Object_id(N'[dbo].[BlockingChains]')
					AND Objectproperty(id, N'IsTable') = 1)
		  BEGIN
			  INSERT INTO dbo.BlockingChainsHistory
			  SELECT
				*
			  FROM
				BlockingChains;

			  TRUNCATE TABLE dbo.BlockingChains
		  END
	END

  CREATE TABLE #active_spids
    (
       spid           INT,
       blocked        INT,
       waittype       VARCHAR(255),
       waittime       BIGINT,
       physical_io    BIGINT,
       cpu            BIGINT,
       memusage       BIGINT,
       [dbid]         INT,
       open_tran      TINYINT,
       [status]       VARCHAR(20),
       hostname       VARCHAR(50),
       [program_name] VARCHAR(100),
       cmd            VARCHAR(100),
       nt_domain      VARCHAR(100),
       nt_username    VARCHAR(200),
       loginame       VARCHAR(100),
       [sql_handle]   [BINARY] (20) NOT NULL,
       [stmt_start]   [INT] NOT NULL,
       [stmt_end]     [INT] NOT NULL,
       [sql_text]     [VARCHAR] (MAX)
    )

  CREATE TABLE #active_spids_info
    (
       spid           INT,
       blocked        INT,
       waittype       VARCHAR(255),
       waittime       BIGINT,
       physical_io    BIGINT,
       cpu            BIGINT,
       memusage       BIGINT,
       [dbid]         INT,
       open_tran      TINYINT,
       [status]       VARCHAR(20),
       hostname       VARCHAR(50),
       [program_name] VARCHAR(100),
       cmd            VARCHAR(100),
       nt_domain      VARCHAR(100),
       nt_username    VARCHAR(200),
       loginame       VARCHAR(100),
       [sql_handle]   [BINARY] (20) NOT NULL,
       [stmt_start]   [INT] NOT NULL,
       [stmt_end]     [INT] NOT NULL,
       eventtype      VARCHAR(255),
       parameters     VARCHAR(255),
       eventinfo      VARCHAR(4000),
       [text]         [VARCHAR] (MAX)
    )

  CREATE TABLE #event_info
    (
       spid         INT,
       eventtype    VARCHAR(255),
       [Parameters] VARCHAR(255),
       eventinfo    VARCHAR(4000)
    )

  DECLARE @TerminateGatheringDT DATETIME,-- when to stop gathering
          @WaitFor_Interval     DATETIME,
          @LastRecordingDT      DATETIME,
          @RecordingDT          DATETIME,
          @myError              INT,-- Local copy of @@ERROR
          @myRowCount           INT,-- Local copy of @@RowCount
          @msgText              NVARCHAR(4000),-- for error messages
          @dbname               VARCHAR(255),
          @svrname              VARCHAR(255),
          @datestart            AS DATETIME,
          @tstamp               VARCHAR(255),
          @spid1                VARCHAR(255),
          @dbname1              VARCHAR(255),
          @status               VARCHAR(255),
          @hostname             VARCHAR(255),
          @programname          VARCHAR(255),
          @cmd                  VARCHAR(255),
          @nt_domain            VARCHAR(255),
          @nt_username          VARCHAR(255),
          @loginame             VARCHAR(255),
          @text                 VARCHAR(8000),
          @msg                  VARCHAR(8000),
          @sub                  VARCHAR(8000),
          @timestamp            AS DATETIME,
          @spid                 INT,
          @sqlhandle            BINARY(20),
          @tsqlhandle           AS VARCHAR(255),
          @waittime             VARCHAR(255),
          @waittype             VARCHAR(255),
          @buffer               VARCHAR(255),
          @diffmsec             BIGINT

  --SET @Duration = '08:00:00' -- Duration of data collection
  --SET @IntervalInSeconds = 30 -- Approx sec in the gathering interval
  --SET @MaximumWaitTime = 28000 -- This is in miliseconds!!!
  --SET @Recivers = '' --who all gets the emails
  SET @diffmsec = Datediff(ms, CONVERT(DATETIME, '00:00:00', 8), @Duration)

  SELECT @WaitFor_Interval = Dateadd (s, @IntervalInSeconds,
                             CONVERT (DATETIME, '00:00:00', 108
                                    )),
         @TerminateGatheringDT = Dateadd(ms, @diffmsec, Getdate())

  WHILE Getdate() <= @TerminateGatheringDT
    BEGIN
        TRUNCATE TABLE #active_spids

        TRUNCATE TABLE #active_spids_info

        TRUNCATE TABLE #event_info

        INSERT INTO #active_spids
        SELECT spid,
               blocked,
               waittype,
               waittime,
               physical_io,
               cpu,
               [memusage],
               a.dbid,
               open_tran,
               a.status,
               hostname,
               [program_name],
               cmd,
               nt_domain,
               nt_username,
               loginame,
               [sql_handle],
               [stmt_start],
               [stmt_end],
               [text]
        FROM   (SELECT spid,
                       blocked,
                       'waittype' = CASE
                                      WHEN waittype = 0x0001 THEN
                                      'Exclusive table lock'
                                      WHEN waittype = 0x0003 THEN
                                      'Exclusive intent lock'
                                      WHEN waittype = 0x0004 THEN
                                      'Shared table lock'
                                      WHEN waittype = 0x0005 THEN
                                      'Exclusive page lock'
                                      WHEN waittype = 0x0006 THEN
                                      'Shared page lock'
                                      WHEN waittype = 0x0007 THEN
                                      'Update page lock'
                                      WHEN waittype = 0x0013 THEN
                                      'Buffer resource lock (exclusive) request'
                                      WHEN waittype = 0x0013 THEN
                       'Miscellaneous I/O (sort, audit, direct xact log I/O)'
                       WHEN waittype = 0x0020 THEN 'Buffer in I/O'
                       WHEN waittype = 0x0022 THEN 'Buffer being dirtied'
                       WHEN waittype = 0x0023 THEN 'Buffer being dumped'
                       WHEN waittype = 0x0081 THEN 'Write the TLog'
                       WHEN waittype = 0x0200 THEN 'Parallel query coordination'
                       WHEN waittype = 0x0208 THEN 'Parallel query coordination'
                       WHEN waittype = 0x0420 THEN 'Buffer I/O latch'
                       WHEN waittype = 0x0421 THEN 'Buffer I/O latch'
                       WHEN waittype = 0x0422 THEN 'Buffer I/O latch'
                       WHEN waittype = 0x0423 THEN 'Buffer I/O latch'
                       WHEN waittype = 0x0424 THEN 'Buffer I/O latch'
                       WHEN waittype = 0x0425 THEN 'Buffer I/O latch'
                       WHEN waittype = 0x0800 THEN 'Network I/O completion'
                       WHEN waittype = 0x8001 THEN 'Exclusive table lock'
                       WHEN waittype = 0x8003 THEN 'Exclusive intent lock'
                       WHEN waittype = 0x8004 THEN 'Shared table lock'
                       WHEN waittype = 0x8005 THEN 'Exclusive page lock'
                       WHEN waittype = 0x8006 THEN 'Shared page lock'
                       WHEN waittype = 0x8007 THEN 'Update page lock'
                       WHEN waittype = 0x8011 THEN
                       'Buffer resource lock (shared) request'
                       ELSE 'OLEDB/Miscellaneous'
                                    END,
                       waittime,
                       physical_io,
                       cpu,
                       [memusage],
                       sp.dbid,
                       open_tran,
                       status,
                       hostname,
                       [program_name],
                       cmd,
                       nt_domain,
                       nt_username,
                       loginame,
                       [sql_handle],
                       [stmt_start],
                       [stmt_end],
                       [text]
                FROM   MASTER.dbo.sysprocesses sp WITH(nolock)
                       CROSS APPLY sys.Dm_exec_sql_text([sql_handle]))a
        WHERE  blocked > 0
               AND waittime > @MaximumWaitTime
        UNION ALL
        SELECT spid,
               blocked,
               waittype,
               waittime,
               physical_io,
               cpu,
               [memusage],
               a.dbid,
               open_tran,
               a.status,
               hostname,
               [program_name],
               cmd,
               nt_domain,
               nt_username,
               loginame,
               [sql_handle],
               [stmt_start],
               [stmt_end],
               [text]
        FROM   (SELECT spid,
                       blocked,
                       'waittype' = CASE
                                      WHEN waittype = 0x0001 THEN
                                      'Exclusive table lock'
                                      WHEN waittype = 0x0003 THEN
                                      'Exclusive intent lock'
                                      WHEN waittype = 0x0004 THEN
                                      'Shared table lock'
                                      WHEN waittype = 0x0005 THEN
                                      'Exclusive page lock'
                                      WHEN waittype = 0x0006 THEN
                                      'Shared page lock'
                                      WHEN waittype = 0x0007 THEN
                                      'Update page lock'
                                      WHEN waittype = 0x0013 THEN
                                      'Buffer resource lock (exclusive) request'
                                      WHEN waittype = 0x0013 THEN
                       'Miscellaneous I/O (sort, audit, direct xact log I/O)'
                       WHEN waittype = 0x0020 THEN 'Buffer in I/O'
                       WHEN waittype = 0x0022 THEN 'Buffer being dirtied'
                       WHEN waittype = 0x0023 THEN 'Buffer being dumped'
                       WHEN waittype = 0x0081 THEN 'Write the TLog'
                       WHEN waittype = 0x0200 THEN 'Parallel query coordination'
                       WHEN waittype = 0x0208 THEN 'Parallel query coordination'
                       WHEN waittype = 0x0420 THEN 'Buffer I/O latch'
                       WHEN waittype = 0x0421 THEN 'Buffer I/O latch'
                       WHEN waittype = 0x0422 THEN 'Buffer I/O latch'
                       WHEN waittype = 0x0423 THEN 'Buffer I/O latch'
                       WHEN waittype = 0x0424 THEN 'Buffer I/O latch'
                       WHEN waittype = 0x0425 THEN 'Buffer I/O latch'
                       WHEN waittype = 0x0800 THEN 'Network I/O completion'
                       WHEN waittype = 0x8001 THEN 'Exclusive table lock'
                       WHEN waittype = 0x8003 THEN 'Exclusive intent lock'
                       WHEN waittype = 0x8004 THEN 'Shared table lock'
                       WHEN waittype = 0x8005 THEN 'Exclusive page lock'
                       WHEN waittype = 0x8006 THEN 'Shared page lock'
                       WHEN waittype = 0x8007 THEN 'Update page lock'
                       WHEN waittype = 0x8011 THEN
                       'Buffer resource lock (shared) request'
                       ELSE 'OLEDB/Miscellaneous'
                                    END,
                       waittime,
                       physical_io,
                       cpu,
                       [memusage],
                       sp.dbid,
                       open_tran,
                       status,
                       hostname,
                       [program_name],
                       cmd,
                       nt_domain,
                       nt_username,
                       loginame,
                       [sql_handle],
                       [stmt_start],
                       [stmt_end],
                       [text]
                FROM   MASTER.dbo.sysprocesses sp WITH(nolock)
                       CROSS APPLY sys.Dm_exec_sql_text([sql_handle])
                WHERE  spid IN (SELECT blocked
                                FROM   MASTER.dbo.sysprocesses WITH(nolock)
                                WHERE  blocked > 0
                                       AND waittime > @MaximumWaitTime)) a
        ORDER  BY blocked

        --loop through the spids without a cursor
        WHILE (SELECT COUNT(spid)
               FROM   #active_spids) > 0
          BEGIN
              SET @spid = (SELECT TOP 1 spid
                           FROM   #active_spids
                           ORDER  BY spid)

              --grab the top spid
              INSERT INTO #active_spids_info
                          (spid,
                           blocked,
                           waittype,
                           waittime,
                           physical_io,
                           cpu,
                           [memusage],
                           dbid,
                           open_tran,
                           status,
                           hostname,
                           [program_name],
                           cmd,
                           nt_domain,
                           nt_username,
                           loginame,
                           [sql_handle],
                           [stmt_start],
                           [stmt_end],
                           [text])
              SELECT TOP 1 spid,
                           blocked,
                           waittype,
                           waittime,
                           physical_io,
                           cpu,
                           [memusage],
                           dbid,
                           open_tran,
                           status,
                           hostname,
                           [program_name],
                           cmd,
                           nt_domain,
                           nt_username,
                           loginame,
                           [sql_handle],
                           [stmt_start],
                           [stmt_end],
                           [sql_text]
              FROM   #active_spids
              ORDER  BY spid

              INSERT INTO #event_info
                          (eventtype,
                           parameters,
                           eventinfo)
              EXEC('DBCC INPUTBUFFER (' + @spid + ') WITH NO_INFOMSGS')

              --get the inputbuffer
              EXEC('update #event_info set spid = '+@spid+' where spid IS NULL')

              --add the spid to the input buffer data
              SELECT @sqlhandle = sql_handle
              FROM   #active_spids
              WHERE  spid = @spid

              DELETE FROM #active_spids
              WHERE  spid = @spid
          --remove the spid processed
          END

        UPDATE #active_spids_info
        SET    #active_spids_info.eventtype = #event_info.eventtype,
               #active_spids_info.parameters = #event_info.parameters,
               #active_spids_info.eventinfo = #event_info.eventinfo
        FROM   #active_spids_info,
               #event_info
        WHERE  #active_spids_info.spid = #event_info.spid

        --join all the info into one table
        SET @timestamp = Getdate()

        --select statement to return results
        INSERT INTO dbo.blockingchains
        SELECT @@SERVERNAME,
               @timestamp       AS tstamp,
               a.spid,
               a.blocked,
               a.waittype,
               a.waittime,
               a.physical_io,
               ( a.cpu / 1000 ) AS cpu_in_seconds,
               a.[memusage],
               b.[name],
               a.open_tran,
               a.status,
               a.hostname,
               a.[program_name],
               a.cmd,
               a.nt_domain,
               a.nt_username,
               a.loginame,
               a.eventtype,
               a.parameters,
               a.eventinfo,
               a.TEXT
        FROM   #active_spids_info a
               INNER JOIN MASTER.dbo.sysdatabases b
                 ON a.dbid = b.dbid

        IF ( (SELECT MAX(sampletime)
              FROM   dbo.blockingchains
              WHERE  spidblocked = 0
                     AND programname NOT IN( @ProcessesToIgnore )
                     AND hostname NOT IN( @HostsToIgnore )
                     AND ( domainname NOT IN( @LoginsToIgnore )
                            OR loginname NOT IN( @LoginsToIgnore ) )) =
             @timestamp
           )
          BEGIN
              SELECT @sub = 'Blocking Issues - ' + @@SERVERNAME

              SELECT @tstamp = sampletime,
                     @spid1 = spid,
                     @status = status,
                     @hostname = Isnull(hostname, ''),
                     @programname = Isnull([programname], ''),
                     @cmd = Isnull(commandissued, ''),
                     @nt_domain = Isnull(domainname, ''),
                     @nt_username = Isnull(domainusername, ''),
                     @loginame = Isnull(loginname, ''),
                     @text = Isnull(commandtext, ''),
                     @waittime = (SELECT MAX(waittime)
                                  FROM   dbo.blockingchains
                                  WHERE  sampletime = (SELECT MAX(sampletime)
                                                       FROM
                                         dbo.blockingchains)),
                     @waittype = Isnull(waittype, ''),
                     @buffer = Isnull(eventinfo, '')
              FROM   dbo.blockingchains
              WHERE  sampletime = (SELECT MAX(sampletime)
                                   FROM   dbo.blockingchains)
                     AND spidblocked = 0

              SELECT @msg =
  'The user below is at the head of the blocking chain on the listed server:'
  + CHAR(13) +
  '__________________________________________________________________________'
  +
                CHAR(13) + 'Server Name:' + @@SERVERNAME + CHAR(13) +
                'TimeStamp: ' + @tstamp + CHAR(13) + 'SPID: ' + @spid1 + CHAR(13)
  + 'Login Name: ' + @loginame + CHAR(13) + 'NT Domain: ' + @nt_domain + CHAR(13)
  + 'NT Username: ' + @nt_username + CHAR(13) + 'Host Name: ' + @hostname +  CHAR(13) 
  + 'Command: ' + @cmd + CHAR(13) + 'Program Name: ' +
                @programname + CHAR(13) + 'Wait Type: ' + @waittype + CHAR(13)
  +
                'Maximum Wait Time For Blocked Thread: ' + @waittime + CHAR(13) +
                'Input Buffer: ' + @buffer + CHAR(13) + 'Status: ' + @status +
                CHAR(13) + 'SQL String:' + CHAR(13) +
                '--WARNING CAN BE LONG AND MAY NOT BE THE WHOLE TEXT!!!--' +
  CHAR(13) + @text

  EXEC msdb.dbo.Sp_send_dbmail
    @recipients = @Recivers,
    @body = @msg,
    @subject = @sub;
  END

  WAITFOR delay @WaitFor_Interval -- delay
  END

  DROP TABLE #active_spids

  DROP TABLE #active_spids_info

  DROP TABLE #event_info
