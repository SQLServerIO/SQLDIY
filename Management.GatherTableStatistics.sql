/************************************************************************************************
Table Stats
By Wesley D. Brown
Date 06/27/2011
**Mod**
**Description**
Gathers space usage for each table in the database specified. 
Functions:
**End Discription**
**Change Log**

Bug Fix:
**End Change Log**
************************************************************************************************/
/************************************************************************************************
* Create these tables first if they don't exist in your system. 
Create table [dbo].[TableStats]
	(
		ServerName varchar(255)
		,DBName varchar(255)
		,SchemaName nvarchar(128)
		,TableName nvarchar(128)
		,RowCounts numeric(38,0)
		,ReservedKB numeric(38,0)
		,DataKB numeric(38,0)
		,IndexSizeKB numeric(38,0)
		,UnusedKB numeric(38,0)
		,RecordedDateTime datetime
	)
	
		Create table [dbo].[TableStatsHistory]
	(
		ServerName varchar(255)
		,DBName varchar(255)
		,SchemaName nvarchar(128)
		,TableName nvarchar(128)
		,RowCounts numeric(38,0)
		,ReservedKB numeric(38,0)
		,DataKB numeric(38,0)
		,IndexSizeKB numeric(38,0)
		,UnusedKB numeric(38,0)
		,RecordedDateTime datetime
	)
************************************************************************************************/

IF EXISTS (SELECT
             1
           FROM
             INFORMATION_SCHEMA.ROUTINES
           WHERE
            SPECIFIC_NAME = N'GatherTableStatistics')
  DROP PROCEDURE GatherTableStatistics

GO

GO

CREATE PROCEDURE Gathertablestatistics
  @DatabaseList           VARCHAR(MAX),
  @ExcludeSystemDatabases TINYINT = 1
AS
  SET nocount ON

  DECLARE @cmd VARCHAR(8000)

  /*****************************************
  * Truncate holding tables
  *****************************************/
  IF EXISTS (SELECT
               1
             FROM
               dbo.TableStats)
    BEGIN
        INSERT INTO dbo.TableStatsHistory
        SELECT
          *
        FROM
          TableStats;

        TRUNCATE TABLE dbo.TableStats;
    END

  DECLARE
    @table_name VARCHAR(128),
    @servername VARCHAR(256),
    @dbname     VARCHAR(256)

  CREATE TABLE #stats
    (
	  ServerName varchar(255)
		,DBName varchar(255)
		,SchemaName nvarchar(128)
		,TableName nvarchar(128)
		,RowCounts numeric(38,0)
		,ReservedKB numeric(38,0)
		,DataKB numeric(38,0)
		,IndexSizeKB numeric(38,0)
		,UnusedKB numeric(38,0)
		,RecordedDateTime datetime
    )

  CREATE TABLE #dbnames
    (
       name NVARCHAR(128)
    )

  SET @servername = Cast(Serverproperty('servername') AS VARCHAR(256))

  IF Upper(@DatabaseList) = 'ALL'
    BEGIN
        IF @ExcludeSystemDatabases = 1
          BEGIN
              SET @DatabaseList = '';

              SELECT
                @DatabaseList = @DatabaseList + '''' + name + ''','
              FROM
                MASTER.dbo.sysdatabases
              WHERE
                name NOT IN ( 'master', 'msdb', 'model', 'pubs',
                              'northwind', 'tempdb' );
          END
        ELSE
          BEGIN
              SELECT
                @DatabaseList = @DatabaseList + '''' + name + ''','
              FROM
                MASTER.dbo.sysdatabases;
          END

        SET @DatabaseList = LEFT(@DatabaseList, Len(@DatabaseList) - 2) + ''''

        INSERT INTO #dbnames
        EXEC('select name from master.dbo.sysdatabases where name in ('+@DatabaseList+')')

    END
  --found at http://mangalpardeshi.blogspot.com/2009/03/how-to-split-comma-delimited-string.html
  ;

  WITH Cte
       AS (SELECT
             Cast('<M>' + Replace(@DatabaseList, ',', '</M><M>') + '</M>' AS XML) AS DatabaseNames)
  INSERT INTO #dbnames
  SELECT
    Split.a.value('.', 'VARCHAR(100)') AS DatabaseNames
  FROM
    Cte
  CROSS APPLY DatabaseNames.nodes('/M') Split(a)

  IF NOT EXISTS(SELECT
                  1
                FROM
                  #dbnames)
    BEGIN
        INSERT INTO #dbnames
        SELECT
          @DatabaseList
    END

  DECLARE db CURSOR FAST_FORWARD FOR
    SELECT
      name
    FROM
      #dbnames

  OPEN db

  FETCH NEXT FROM db INTO @dbname

  WHILE ( @@FETCH_STATUS <> -1 )
    BEGIN
        IF ( @@FETCH_STATUS <> -2 )
          BEGIN
              IF (SELECT
                    CONVERT(SYSNAME, Databasepropertyex(@dbname, 'status'))) = 'ONLINE'
                BEGIN
					exec('
					USE ['+@dbname+']
					insert into #stats
                    SELECT
                      '''+@servername+'''                            AS ServerName,
                      '''+@dbname+'''                                AS DBName,
                      Object_schema_name(object_id)                  AS SchemaName,
                      Object_name(object_id)                         AS TableName,
                      Sum(CASE
                            WHEN index_id < 2 THEN row_count
                            ELSE 0
                          END)                                       AS RowCounts,
                      Sum(reserved_page_count) * 8                   AS ReservedKB,
                      Sum(CASE
                            WHEN index_id < 2 THEN in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count
                            ELSE lob_used_page_count + row_overflow_used_page_count
                          END) * 8                                   AS DataKB,
                      ( Sum(used_page_count) - Sum(CASE
                                                     WHEN index_id < 2 THEN in_row_data_page_count + lob_used_page_count + row_overflow_used_page_count
                                                     ELSE lob_used_page_count + row_overflow_used_page_count
                                                   END) ) * 8        AS IndexSizeKB,
                      Sum(reserved_page_count - used_page_count) * 8 AS UnusedKB,
                      Getdate()                                      AS RecordedDateTime
                    FROM
                      ['+@dbname+'].sys.dm_db_partition_stats
                    WHERE
                      Objectproperty(object_id, ''IsUserTable'') = 1
                    GROUP  BY object_id')
					insert into dbo.TableStats
					select * from #stats
					truncate table #stats
                END
          END

        FETCH NEXT FROM db INTO @dbname
    END

  CLOSE db

  DEALLOCATE db

  DROP TABLE #stats

  SET nocount OFF 
