/************************************************************************************************
Statistics Information
By Wesley D. Brown
Date 06/27/2011

**Description**
Uses DMV's to get information on the statistics stored down to the column level with the last
time the statisistics were updated. 
Functions:
**End Discription**
**Change Log**
Bug Fix:
**End Change Log**
************************************************************************************************/
/************************************************************************************************
Tables Needed:
DROP TABLE dbo.StatisticsInformation
DROP TABLE dbo.StatisticsInformationHistory

CREATE TABLE dbo.StatisticsInformation
  (
     ServerName       NVARCHAR(128),
     DBName           NVARCHAR(128),
     SchemaName       NVARCHAR(128),
     TableName        NVARCHAR(128),
     StatisticsName   NVARCHAR(128),
     ColumnName       NVARCHAR(128),
     LastUpdatedDate  DATETIME,
     RecordedDateTime DATETIME
  ); 

CREATE TABLE dbo.StatisticsInformationHistory
  (
     ServerName       NVARCHAR(128),
     DBName           NVARCHAR(128),
     SchemaName       NVARCHAR(128),
     TableName        NVARCHAR(128),
     StatisticsName   NVARCHAR(128),
     ColumnName       NVARCHAR(128),
     LastUpdatedDate  DATETIME,
     RecordedDateTime DATETIME
  ); 
************************************************************************************************/

IF EXISTS (
  SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE SPECIFIC_NAME = N'GatherStatisticsInformation' 
)
DROP PROCEDURE GatherStatisticsInformation
GO

/*
exec GatherStatisticsInformation 'ALL',1
select * from dbo.StatisticsInformation
*/
CREATE PROCEDURE GatherStatisticsInformation
				@DatabaseList           VARCHAR(MAX),
				@ExcludeSystemDatabases tinyint = 1
AS
  SET NOCOUNT ON
/*****************************************
* Truncate holding tables
*****************************************/
  IF EXISTS (SELECT 1
             FROM   dbo.StatisticsInformation)
    BEGIN
        INSERT INTO dbo.StatisticsInformationHistory
        SELECT *
        FROM   StatisticsInformation;

        TRUNCATE TABLE dbo.StatisticsInformation;
    END

    /* Declare Parameters */
DECLARE
  @cmd              VARCHAR(8000),
  @servername       VARCHAR(256),
  @dbname           VARCHAR(256),
  @recordeddatetime DATETIME 
        
	CREATE TABLE #statsinfo
	  (
		 ServerName       NVARCHAR(128),
		 DBName           NVARCHAR(128),
		 SchemaName       NVARCHAR(128),
		 TableName        NVARCHAR(128),
		 StatisticsName   NVARCHAR(128),
		 ColumnName       NVARCHAR(128),
		 LastUpdatedDate  DATETIME,
		 RecordedDateTime DATETIME
	  ); 


	CREATE TABLE #dbnames
	(
		name NVARCHAR(128)
	)
	
  SET @recordeddatetime = GETDATE()
  SET @servername = CAST(Serverproperty('servername') AS VARCHAR(256))

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

  DECLARE db CURSOR FAST_FORWARD FOR
    SELECT name
    FROM   #dbnames

  OPEN db

  FETCH NEXT FROM db INTO @dbname

  WHILE ( @@FETCH_STATUS <> -1 )
    BEGIN
        IF ( @@FETCH_STATUS <> -2 )
          BEGIN
              IF (SELECT CONVERT(SYSNAME, Databasepropertyex(@dbname, 'status'))
                 )
                 =
                 'ONLINE'
                BEGIN
					set @cmd = '
					USE '+@dbname+'
					INSERT INTO #statsinfo
					SELECT
					  '''+@servername+'''				AS ''ServerName''
					  ,'''+@dbname+'''					AS ''DatabaseName''
					  ,ss.name                             AS ''SchemaName''
					  ,o.name                              AS ''TableName''
					  ,s.name                              AS ''StatisticsName''
					  ,c.name                              AS ''ColumnName''
					  ,Stats_date(i.object_id, i.index_id) AS ''LastUpdateDate''
					  , '''+convert(varchar,@recordeddatetime, 121)+''' AS ''RecordedDateTime''
					FROM
					  ['+@dbname+'].sys.stats AS s
					INNER JOIN ['+@dbname+'].sys.stats_columns AS sc
					  ON s.object_id = sc.object_id
						 AND s.stats_id = sc.stats_id
					INNER JOIN ['+@dbname+'].sys.columns AS c
					  ON sc.object_id = c.object_id
						 AND c.column_id = sc.column_id
					INNER JOIN ['+@dbname+'].sys.objects AS o
					  ON c.object_id = o.object_id
						 AND o.type = ''U''
					INNER JOIN ['+@dbname+'].sys.indexes i
					  ON i.object_id = o.object_id
					INNER JOIN ['+@dbname+'].sys.schemas ss
					  ON o.schema_id = ss.schema_id
					ORDER      BY
					  ss.name
					  ,o.name
					  ,s.name
					  ,c.name'
					  exec(@cmd)
				END
			END
		FETCH NEXT FROM db INTO @dbname
	END

	CLOSE db
	DEALLOCATE db

	  insert into dbo.StatisticsInformation
	  select * from #statsinfo	
	  
	DROP TABLE #dbnames
	SET nocount OFF                 