	DECLARE @DatabaseList VARCHAR(MAX)
	DECLARE @ExcludeSystemDatabases tinyint
	DECLARE @dletter VARCHAR(2) 
	DECLARE @fspace INT 
	DECLARE @tspace BIGINT 
	DECLARE @drsize VARCHAR(500) 
	DECLARE @ret INT 
	DECLARE @DBName AS VARCHAR(255) 
	DECLARE @cmd AS VARCHAR(8000) 
	DECLARE @date AS VARCHAR(10) 
	DECLARE @DBid AS VARCHAR(3) 
	DECLARE @svrname AS VARCHAR(255) 
	DECLARE @recordeddate as datetime
	set @recordeddate = getdate()
	set @DatabaseList = 'ALL'
	set @ExcludeSystemDatabases = 0;

	SET @svrname = CONVERT(VARCHAR(255), Serverproperty('ServerName')) 
	SET @date = Cast(Datepart(year, Getdate())AS CHAR(4)) 
				+ '-' 
				+ Cast(Datepart(month, Getdate()) AS VARCHAR(2)) 
				+ '-' 
				+ Cast(Datepart(day, Getdate()) AS VARCHAR(2)) 

	/***************************************** 
	* Create temp tables 
	*****************************************/ 
	IF EXISTS (SELECT * 
				   FROM   tempdb.dbo.sysobjects 
				   WHERE  [name] like '##DBFile%' 
						  AND Objectproperty(id, N'IsUserTable') = 1) 
	  drop table ##DBFile
	  
  CREATE TABLE ##DBFile 
	( 
	   DBFilename     VARCHAR(255) NOT NULL, 
	   DBName         VARCHAR(255) NOT NULL, 
	   ServerName     VARCHAR(255) NOT NULL, 
	   DriveName      CHAR(1) NULL, 
	   CreateDate     DATETIME NULL, 
	   LastActiveDate DATETIME NULL, 
	   DBFileGroup    VARCHAR(255) NULL, 
	   FileSizeKB     DEC(38, 2) NULL, 
	   SpaceUsedKB    DEC(38, 2) NULL, 
	   FileType           VARCHAR(10) NULL,
	   RecordedDateTime DATETIME NULL
	) 
	
	if exists(select 1 from tempDB.dbo.sysobjects where name like '##dbnames%')
	drop table ##dbnames

	CREATE TABLE ##dbnames
	(
		name NVARCHAR(128)
	)

	if exists(select 1 from tempDB.dbo.sysobjects where name like '##loginfo%')
	drop table ##loginfo

	CREATE TABLE ##loginfo 
	  ( 
		 recoveryunitid INT, 
		 fileid         INT, 
		 filesize       DECIMAL(28, 6), 
		 startoffset    DECIMAL(28, 0), 
		 fseqno         DECIMAL(28, 0), 
		 status         TINYINT, 
		 parity         TINYINT, 
		 createlsn      VARCHAR(50) 
	  ) 

	if exists(select 1 from tempDB.dbo.sysobjects where name like '##loginfo_results%')
	drop table ##loginfo_results

	CREATE TABLE ##loginfo_results 
	  ( 
		 ServerName  VARCHAR(255), 
		 DBName      VARCHAR(255), 
		 DBFilename  VARCHAR(255), 
		 SpaceUsedKB DECIMAL(38, 2) 
	  ) 

	if exists(select 1 from tempDB.dbo.sysobjects where name like '##DBusage_base%')
	drop table ##DBusage_base

	CREATE TABLE ##DBusage_base
	  ( 
		 server_name   VARCHAR(255), 
		 database_name VARCHAR(255), 
		 DBid          INT, 
		 fileid        INT, 
		 filegroup     VARCHAR(255), 
		 totalextents  DECIMAL(10, 2), 
		 usedextents   DECIMAL(10, 2), 
		 [name]        VARCHAR(250), 
		 filename      VARCHAR(350) 
	  ) 

	if exists(select 1 from tempDB.dbo.sysobjects where name like '##DBusage_stats%')
	drop table ##DBusage_stats

	CREATE TABLE ##DBusage_stats 
	  ( 
		 fileid       INT, 
		 filegroup    INT, 
		 totalextents DECIMAL(10, 2), 
		 usedextents  DECIMAL(10, 2), 
		 name         VARCHAR(250), 
		 filename     VARCHAR(350) 
	  ) 

/*****************************************
  * Get list of databases
  *****************************************/
    IF Upper(@DatabaseList) = 'ALL'
    BEGIN
		SET @DatabaseList = '';
        IF @ExcludeSystemDatabases = 1
          BEGIN

              SELECT @DatabaseList = @DatabaseList + '''' + name + ''','
              FROM   MASTER.dbo.sysdatabases
              WHERE  name NOT IN ( 'master', 'msdb', 'model', 'pubs',
                                   'northwind', 'tempdb' );
          END
        ELSE
          BEGIN
              SELECT @DatabaseList = @DatabaseList + '''' + name + ''','
              FROM   MASTER.dbo.sysdatabases;
          END

        SET @DatabaseList = LEFT(@DatabaseList, Len(@DatabaseList) - 2) + ''''
        
		INSERT INTO ##dbnames
		EXEC('select name from master.dbo.sysdatabases where name in ('+@DatabaseList+')')

    END;

	/***************************************** 
	* Return disk space info 
	*****************************************/ 
	INSERT INTO ##DBFile 
				(DBFilename, 
				 DBName, 
				 ServerName, 
				 DriveName, 
				 CreateDate, 
				 LastActiveDate, 
				 filesizekb) 
	SELECT af.[name]                             AS [DBFileName], 
		   DB.[name]                             AS [DBName], 
		   @svrname                              AS ServerName, 
		   LEFT(af.filename, 1), 
		   Cast(@date AS DATETIME)               AS CreateDate, 
		   Cast(@date AS DATETIME)               AS LastActiveDate, 
		   Cast(af.[size] AS DECIMAL(38, 2)) * 8 AS [FileSize] 
	FROM   master.dbo.sysaltfiles af WITH(nolock) 
		   INNER JOIN master.dbo.sysdatabases DB WITH(nolock) 
				   ON af.DBid = DB.DBid 
	where DB.[name] in (select name from ##dbnames)
	ORDER  BY DB.[name], 
			  af.[name]; 

    /***************************************** 
	* Return file DBusage_numbers 
	*****************************************/ 
	DECLARE DB_cursor CURSOR FOR 
	  SELECT name 
	  FROM   ##dbnames

	OPEN DB_cursor 

	FETCH next FROM DB_cursor INTO @DBName 

	WHILE @@FETCH_STATUS = 0 
	  BEGIN 
		  IF (SELECT CONVERT(SYSNAME, Databasepropertyex(@DBName, 'status'))) = 
			 'ONLINE' 
			 AND (SELECT CONVERT(SYSNAME, Databasepropertyex(@DBName, 'useraccess ') 
						 )) 
				 = 
				 'MULTI_USER' 
			BEGIN 
				SET @cmd = 'use [' + @DBName + '] insert into ##DBusage_stats exec(''DBCC showfilestats'');' 

				EXEC(@cmd) 

				SELECT @DBid = DB_id(@DBName) 

				SET @svrname = @svrname 

				EXEC('insert into ##DBusage_base select '''+@svrname+ ''' as server_name,''' + 
				@DBName+''' as database_name ,'+@DBid+ 
				' as DBid,FileId,(select groupname from ['+@DBName+ '].dbo.sysfilegroups where [' +@DBName+ '].dbo.sysfilegroups.groupid = FileGroup) as FileGroup,TotalExtents,UsedExtents,Name,Filename from ##DBusage_stats;'
		) 

		TRUNCATE TABLE ##DBusage_stats; 
	END 

		FETCH next FROM DB_cursor INTO @DBName 
	END 

	CLOSE DB_cursor 

	DEALLOCATE DB_cursor 

	UPDATE ##DBFile 
	SET    
		   DBFileGroup = a.[filegroup], 
		   SpaceUsedKB = Cast(a.usedextents AS DECIMAL(38, 2)) * 64, 
		   [FileType] = 'Data',
		   RecordedDateTime = @recordeddate
	FROM   ##DBusage_base a 
		   INNER JOIN ##DBFile b 
				   ON Ltrim(Rtrim(a.server_name)) = b.ServerName 
					  AND a.database_name = b.DBName 
					  AND a.[name] = b.DBFilename; 

	/***************************************** 
	* Return loginfo numbers 
	*****************************************/ 
	DECLARE DB_cursor CURSOR FOR 
	  SELECT name 
	  FROM   ##dbnames

	OPEN DB_cursor 

	FETCH next FROM DB_cursor INTO @DBName 

	WHILE @@FETCH_STATUS = 0 
	  BEGIN 
		  IF (SELECT CONVERT(SYSNAME, Databasepropertyex(@DBName, 'status'))) = 
			 'ONLINE' 
			 AND (SELECT CONVERT(SYSNAME, Databasepropertyex(@DBName, 'useraccess ') 
						 )) 
				 = 
				 'MULTI_USER' 
			BEGIN 
				SET @cmd = 'use [' + @DBName 
						   + 
	  '] INSERT INTO ##loginfo EXEC( ''DBCC LOGINFO WITH TABLERESULTS'' ); ' 

	  EXEC(@cmd); 

	  INSERT INTO ##loginfo_results 
	  SELECT a.ServerName, 
			 a.DBName, 
			 b.[name]             AS DBFileName, 
			 ( spaceused * 1024 ) AS SpaceUsedKB 
	  FROM   (SELECT @svrname                ServerName, 
					 @DBName                 AS DBName, 
					 DB_id(@DBName)          AS DBid, 
					 a.fileid, 
					 a.size_mb, 
					 Isnull(b.space_used, 0) AS SpaceUsed 
			  FROM   (SELECT l.fileid, 
							 Count(l.startoffset)              AS 
							 ##VirtualFiles 
							 , 
							 Sum(l.filesize) / 
							 Power(1024., 2) AS Size_MB 
					  FROM   ##loginfo AS l 
					  GROUP  BY l.fileid) a 
					 LEFT OUTER JOIN (SELECT l.fileid, 
											 Sum(l.filesize) / 
											 Power(1024., 2) 
											 AS 
											 Space_Used 
									  FROM   ##loginfo AS l 
									  WHERE  status > 0 
									  GROUP  BY fileid) b 
								  ON a.fileid = b.fileid)a 
			 INNER JOIN master.dbo.sysaltfiles b 
					 ON a.DBid = b.DBid 
						AND a.fileid = b.fileid; 
			END 

		  TRUNCATE TABLE ##loginfo; 

		  FETCH next FROM DB_cursor INTO @DBName 
	  END 

	CLOSE DB_cursor 

	DEALLOCATE DB_cursor 

	UPDATE ##DBFile 
	SET    
	    SpaceUsedKB = a.SpaceUsedKB, 
		   [FileType] = 'Log', 
		   DBFileGroup = 'NA',
		   RecordedDateTime = @recordeddate
	FROM   ##loginfo_results a 
		   INNER JOIN ##DBFile b 
				   ON a.ServerName = b.ServerName 
					  AND a.DBName = b.DBName 
					  AND a.DBFilename = b.DBFilename; 

	select * from ##DBFile as DBFile;
	--SET nocount OFF 
	