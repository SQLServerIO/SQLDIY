/************************************************************************************************
Index Fragmentation
By Wesley D. Brown
Date 06/27/2011

**Description**
Uses Index DMV's to track index fragmentation over time.
Functions:
**End Discription**
**Change Log**
Bug Fix:
**End Change Log**
************************************************************************************************/
/************************************************************************************************
Tables Needed:
DROP TABLE dbo.IndexFragmentationLevels
DROP TABLE dbo.IndexFragmentationLevelsHistory

CREATE TABLE dbo.IndexFragmentationLevels
  (
     ServerName       NVARCHAR(128),
     DBName           NVARCHAR(128),
     PartitionNumber  SMALLINT,
     SchemaName       NVARCHAR(128),
     TableName        NVARCHAR(128),
     IndexName        NVARCHAR(128),
     Fragmentation    FLOAT,
     PageTotalCount   INT,
     RangeScanCount   BIGINT,
     RecordedDateTime DATETIME
  ); 


CREATE TABLE dbo.IndexFragmentationLevelsHistory
  (
     ServerName       NVARCHAR(128),
     DBName           NVARCHAR(128),
     PartitionNumber  SMALLINT,
     SchemaName       NVARCHAR(128),
     TableName        NVARCHAR(128),
     IndexName        NVARCHAR(128),
     Fragmentation    FLOAT,
     PageTotalCount   INT,
     RangeScanCount   BIGINT,
     RecordedDateTime DATETIME
  ); 
************************************************************************************************/

IF EXISTS (
  SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE SPECIFIC_NAME = N'GatherIndexFragmentationLevels' 
)
DROP PROCEDURE GatherIndexFragmentationLevels
GO

/*
exec GatherIndexFragmentationLevels 'ALL',1
select * from IndexFragmentationLevels
*/
CREATE PROCEDURE GatherIndexFragmentationLevels
				@DatabaseList           VARCHAR(MAX),
				@ExcludeSystemDatabases tinyint = 1,  
				@ScanType         VARCHAR(10) = 'LIMITED',
				@MinimumPageCount  INT = 8,
				@NumberOfThreads TINYINT = 4

AS
  SET NOCOUNT ON
  /************************************************************************************************
        @ScanType             sys.dm_db_index_physical_stats takes a parameter to determine how
							aggresively to scan the index and determine fragmentation levels.
                            LIMITED	 -	only scans parent level of the b-tree quickest and least
											impacting
                            SAMPLED  -	takes a one percent sample of all data pages. 
                            DETAILED -	scans all data pages. This can kill your disk system
										with heavy IO loads. use with much care!

      @minPageCount         default 8 generally, trying to defrag an index that is smaller than 
							an extent is pointless
 ************************************************************************************************/
/*****************************************
* Truncate holding tables
*****************************************/
  IF EXISTS (SELECT 1
             FROM   dbo.IndexFragmentationLevels)
    BEGIN
        INSERT INTO dbo.IndexFragmentationLevelsHistory
        SELECT *
        FROM   IndexFragmentationLevels;

        TRUNCATE TABLE dbo.IndexFragmentationLevels;
    END

    /* Declare Parameters */
DECLARE
  @tablename        VARCHAR(4000) = NULL,
  @cmd              VARCHAR(8000),
  @servername       VARCHAR(256),
  @dbname           VARCHAR(256),
  @schemaname       NVARCHAR(128),
  @recordeddatetime DATETIME 
        

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
					INSERT INTO dbo.IndexFragmentationLevels
					SELECT
						'''+@servername+'''				AS ''ServerName''
						,'''+@dbname+'''					AS ''DatabaseName''
						, ps.partition_number AS ''PartitionNumber''
						, Object_schema_name(ps.object_id,DB_ID('''+@dbname+'''))
						, OBJECT_NAME(ps.object_id,db_id('''+@dbname+'''))
						, si.name
						, SUM(ps.avg_fragmentation_in_percent) AS ''Fragmentation''
						, SUM(ps.page_count) AS ''PageTotalCount''
						, os.range_scan_count
						, '''+convert(varchar,@recordeddatetime, 121)+'''
					FROM sys.dm_db_index_physical_stats(DB_ID('''+@dbname+'''),NULL, NULL , NULL, '''+@ScanType+''') AS ps
					INNER JOIN sys.dm_db_index_operational_stats(DB_ID('''+@dbname+'''), NULL, NULL , NULL) AS os
						ON ps.database_id = os.database_id
						AND ps.[object_id] = os.[object_id]
						AND ps.index_id = os.index_id
						AND ps.partition_number = os.partition_number
					INNER JOIN ['+@dbname+'].sys.indexes si
					on
					ps.object_id = si.object_id
					and
					ps.index_id = si.index_id
					WHERE
						ps.index_id > 0
						AND ps.page_count > '+cast(@MinimumPageCount as varchar(10))+'
						AND ps.index_level = 0
					GROUP BY ps.database_id 
						, DB_NAME(ps.database_id) 
						, ps.[object_id]
						, ps.index_id 
						, ps.partition_number 
						, os.range_scan_count
						, si.name
						OPTION (MAXDOP '+cast(@NumberOfThreads as varchar(3))+');'
						exec(@cmd)
				END
			END
		FETCH NEXT FROM db INTO @dbname
	END

	CLOSE db
	DEALLOCATE db
	
	DROP TABLE #dbnames
	SET nocount OFF                 