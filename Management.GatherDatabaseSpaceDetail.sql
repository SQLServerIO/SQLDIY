/************************************************************************************************
Database Space Detail
By Wesley D. Brown
Date 06/27/2011
**Mod**
**Description**
This script through the use of system tables and system procedures pulls all the space detail
numbers for every database on the server. 
Functions:
Finds MDF,NDF, and LDF file sizes and space used in each file.
**End Discription**

**Change Log**
Bug Fix:
**End Change Log**
************************************************************************************************/
/************************************************************************************************
* Create these tables first if they don't exist in your system. 
CREATE TABLE [dbo].[DBFile] (
       DBFileName           varchar(255),
       DBName               varchar(255),
       ServerName           varchar(255),
       DriveName            char(1) ,
       CreateDate           datetime ,
       LastActiveDate       datetime ,
       DBFileGroup          varchar(255),
       FileSizeKB           dec(38,2),
       SpaceUsedKB          dec(38,2),
       FileType             varchar(10),
       RecordedDateTime		datetime
)

CREATE TABLE [dbo].[DBFileHistory] (
       DBFileName           varchar(255),
       DBName               varchar(255),
       ServerName           varchar(255),
       DriveName            char(1) ,
       CreateDate           datetime ,
       LastActiveDate       datetime ,
       DBFileGroup          varchar(255),
       FileSizeKB           dec(38,2),
       SpaceUsedKB          dec(38,2),
       FileType             varchar(10),
       RecordedDateTime		datetime
)
************************************************************************************************/
IF EXISTS (
  SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE SPECIFIC_NAME = N'GatherDatabaseSpaceDetail' 
)
DROP PROCEDURE GatherDatabaseSpaceDetail
GO


-- exec GatherDatabaseSpaceDetail 'Management',1
CREATE PROCEDURE GatherDatabaseSpaceDetail
				@DatabaseList           VARCHAR(MAX),
				@ExcludeSystemDatabases tinyint = 1
AS
  SET NOCOUNT ON

  DECLARE @dletter VARCHAR(2),
          @fspace  INT,
          @tspace  BIGINT,
          @oFSO    INT,
          @oDrive  INT,
          @drsize  VARCHAR(500),
          @ret     INT,
          @dbname  AS VARCHAR(255),
          @cmd     AS VARCHAR(8000),
          @date    AS VARCHAR(10),
          @dbid    AS VARCHAR(3),
          @svrname AS VARCHAR(255)

  SET @svrname = CONVERT(VARCHAR(255), Serverproperty('servername'))
  SET @date = CAST(Datepart(YEAR, Getdate())AS CHAR(4)) + '-' + CAST(
                          Datepart(MONTH, Getdate()) AS VARCHAR(2)) + '-' + CAST
              (
              Datepart(DAY, Getdate()) AS VARCHAR(2))

  /*****************************************
  * Truncate holding tables
  *****************************************/
  IF EXISTS (SELECT 1
             FROM   dbo.DBFile)
    BEGIN
        INSERT INTO dbo.DBFileHistory
        SELECT *
        FROM   DBFile;

        TRUNCATE TABLE dbo.DBFile;
    END

  /*****************************************
  * Create temp tables
  *****************************************/
  CREATE TABLE ##loginfo
    (
       fileid      INT,
       filesize    DECIMAL(28, 6),
       startoffset DECIMAL(28, 0),
       fseqno      DECIMAL(28, 0),
       status      TINYINT,
       parity      TINYINT,
       createlsn   VARCHAR(50)
    )

  CREATE TABLE ##loginfo_results
    (
       servername  VARCHAR(255),
       dbname      VARCHAR(255),
       dbfilename  VARCHAR(255),
       spaceusedkb DECIMAL(38, 2)
    )

  CREATE TABLE ##space
    (
       dletter VARCHAR(2),
       fspace  INT,
       tspace  BIGINT
    )

  CREATE TABLE ##dbusage
    (
       server_name   VARCHAR(255),
       database_name VARCHAR(255),
       dbid          INT,
       fileid        INT,
       filegroup     VARCHAR(255),
       totalextents  DECIMAL(10, 2),
       usedextents   DECIMAL(10, 2),
       [name]        VARCHAR(250),
       filename      VARCHAR(350)
    )

  CREATE TABLE ##dbusage_stats
    (
       fileid       INT,
       filegroup    INT,
       totalextents DECIMAL(10, 2),
       usedextents  DECIMAL(10, 2),
       name         VARCHAR(250),
       filename     VARCHAR(350)
    )

	CREATE TABLE #dbnames
	(
		name NVARCHAR(128)
	)

  /*****************************************
  * populate temp tables space
  *****************************************/
  INSERT INTO ##space
              (dletter,
               fspace)
  EXEC MASTER.dbo.Xp_fixeddrives

  /*****************************************
  * Get list of databases
  *****************************************/
    IF Upper(@DatabaseList) = 'ALL'
    BEGIN
        IF @ExcludeSystemDatabases = 1
          BEGIN
              SET @DatabaseList = '';

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
        
		INSERT INTO #dbnames
		EXEC('select name from master.dbo.sysdatabases where name in ('+@DatabaseList+')')

    END
    --found at http://mangalpardeshi.blogspot.com/2009/03/how-to-split-comma-delimited-string.html
		;WITH Cte AS
		(
			select CAST('<M>' + REPLACE( @DatabaseList,  ',' , '</M><M>') + '</M>' AS XML) AS DatabaseNames
		)
		
		insert into #dbnames
		SELECT
		Split.a.value('.', 'VARCHAR(100)') AS DatabaseNames
		FROM Cte
		CROSS APPLY DatabaseNames.nodes('/M') Split(a)

    IF not exists(select 1 from #dbnames)
    BEGIN
		insert into #dbnames select @DatabaseList
    END
    
  /*****************************************
  * Return disk space info
  *****************************************/
  INSERT INTO dbo.[DBFile]
              (dbfilename,
               dbname,
               servername,
               drivename,
               createdate,
               lastactivedate,
               filesizekb,
               recordeddatetime)
  SELECT af.[name]                             AS [DBFileName],
         db.[name]                             AS [DBName],
         @svrname                              AS servername,
         LEFT(af.filename, 1),
         CAST(@date AS DATETIME)               AS createdate,
         CAST(@date AS DATETIME)               AS lastactivedate,
         CAST(af.[size] AS DECIMAL(38, 2)) * 8 AS [FileSize],
         Getdate()
  FROM   MASTER.sys.sysaltfiles af WITH(nolock)
         INNER JOIN master.sys.databases db WITH(nolock)
           ON af.dbid = db.database_id
         INNER JOIN #dbnames dbn
         on db.[name] = dbn.name
  ORDER  BY db.[name],
            af.[name]

  /*****************************************
  * Return file dbusage_numbers
  *****************************************/
  DECLARE db_cursor CURSOR FOR
    SELECT name
    FROM   #dbnames

  OPEN db_cursor

  FETCH NEXT FROM db_cursor INTO @dbname

  WHILE @@FETCH_STATUS = 0
    BEGIN
        IF (SELECT CONVERT(SYSNAME, Databasepropertyex(@dbname, 'status'))) =
           'ONLINE'
           AND (SELECT CONVERT(SYSNAME, Databasepropertyex(@dbname,
                       'useraccess ')
                       ))
               =
               'MULTI_USER'
          BEGIN
              SET @cmd = 'use [' + @dbname +
              '] insert into ##dbusage_stats exec(''dbcc showfilestats'')'

              EXEC(@cmd)

              SELECT @dbid = Db_id(@dbname)

              SET @svrname = @svrname

              EXEC('insert into ##dbusage select '''+@svrname+
              ''' as server_name,'''
              +
              @dbname+''' as database_name ,'+ @dbid+
              ' as dbid,FileId,(select [name] from ['+@dbname+
              '].sys.filegroups where ['+ @dbname+
'].sys.filegroups.data_space_id = FileGroup) as FileGroup,TotalExtents,UsedExtents,Name,Filename from ##dbusage_stats'
    )

    TRUNCATE TABLE ##dbusage_stats
END

    FETCH NEXT FROM db_cursor INTO @dbname
END

  CLOSE db_cursor

  DEALLOCATE db_cursor

  UPDATE dbo.[DBFile]
  SET    dbfilegroup = a.[FileGroup],
         spaceusedkb = CAST(a.usedextents AS DECIMAL(38, 2)) * 64,
         filetype = 'Data'
  FROM   ##dbusage a
         INNER JOIN dbo.dbfile b
           ON Ltrim(Rtrim(a.server_name)) = b.servername
              AND a.database_name = b.dbname
              AND a.[name] = b.dbfilename

  /*****************************************
  * Return loginfo numbers
  *****************************************/
  SET @dbname = ''

  DECLARE db_cursor CURSOR FOR
    SELECT name
    FROM   #dbnames

  OPEN db_cursor

  FETCH NEXT FROM db_cursor INTO @dbname

  WHILE @@FETCH_STATUS = 0
    BEGIN
        IF (SELECT CONVERT(SYSNAME, Databasepropertyex(@dbname, 'status'))) =
           'ONLINE'
           AND (SELECT CONVERT(SYSNAME, Databasepropertyex(@dbname,
                       'useraccess ')
                       ))
               =
               'MULTI_USER'
          BEGIN
              SET @cmd = 'use [' + @dbname +
    '] INSERT INTO ##loginfo EXEC( ''DBCC LOGINFO WITH TABLERESULTS'' ) '

    EXEC(@cmd)

    INSERT INTO ##loginfo_results
    SELECT a.servername,
           a.dbname,
           b.[name]             AS dbfilename,
           ( spaceused * 1024 ) AS spaceusedkb
    FROM   (SELECT @svrname                servername,
                   @dbname                 AS dbname,
                   Db_id(@dbname)          AS dbid,
                   a.fileid,
                   a.size_mb,
                   Isnull(b.space_used, 0) AS spaceused
            FROM   (SELECT l.fileid,
                           COUNT(l.startoffset)              AS
                           ##virtualfiles
                           ,
                           SUM(l.filesize) /
                           Power(1024., 2) AS size_mb
                    FROM   ##loginfo AS l
                    GROUP  BY l.fileid) a
                   LEFT OUTER JOIN (SELECT l.fileid,
                                           SUM(l.filesize) /
                                           Power(1024., 2)
                                           AS
                                           space_used
                                    FROM   ##loginfo AS l
                                    WHERE  status > 0
                                    GROUP  BY fileid) b
                     ON a.fileid = b.fileid)a
           INNER JOIN MASTER.dbo.sysaltfiles b
             ON a.dbid = b.dbid
                AND a.fileid = b.fileid
          END

        TRUNCATE TABLE ##loginfo

        FETCH NEXT FROM db_cursor INTO @dbname
    END

  CLOSE db_cursor

  DEALLOCATE db_cursor

  UPDATE dbo.[DBFile]
  SET    spaceusedkb = a.spaceusedkb,
         filetype = 'Log',
         dbfilegroup = 'NA'
  FROM   ##loginfo_results a
         INNER JOIN dbo.dbfile b
           ON a.servername = b.servername
              AND a.dbname = b.dbname
              AND a.dbfilename = b.dbfilename

  /*****************************************
  * Drop temporary tables
  *****************************************/
  DROP TABLE ##dbusage

  DROP TABLE ##dbusage_stats

  DROP TABLE ##space

  DROP TABLE ##loginfo

  DROP TABLE ##loginfo_results 
