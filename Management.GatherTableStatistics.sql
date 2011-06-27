/************************************************************************************************
Table Stats
By Wesley D. Brown
Date 06/27/2011
Mod
**Description**
Gathers space usage for each table in the database specified. 
Functions:
**End Discription**
**Change Log**

Bug Fix:
**End Change Log**
************************************************************************************************/
DROP PROCEDURE gathertablestatistics

GO

CREATE PROCEDURE Gathertablestatistics @DatabaseList           VARCHAR(MAX),
                                       @ExcludeSystemDatabases tinyint = 1
AS
  SET nocount ON

  DECLARE @cmd VARCHAR(8000)

  /*****************************************
  * Truncate holding tables
  *****************************************/
  IF EXISTS (SELECT 1
             FROM   dbo.tablestats)
    BEGIN
        INSERT INTO dbo.tablestatshistory
        SELECT *
        FROM   tablestats;

        TRUNCATE TABLE dbo.tablestats;
    END

  DECLARE @table_name VARCHAR(128),
          @servername VARCHAR(256),
          @dbname     VARCHAR(256),
          @schemaname NVARCHAR(128),
          @tablename  NVARCHAR(128)

  CREATE TABLE #tblholding
    (
       tblname    VARCHAR(500),
       schemaname NVARCHAR(128),
       tablename  NVARCHAR(128)
    )

  CREATE TABLE #stats
    (
       tablename  VARCHAR(300),
       schemaname NVARCHAR(128),
       tblname    NVARCHAR(128),
       rowcounts  VARCHAR(18),
       reserved   VARCHAR(18),
       data       VARCHAR(18),
       indexsize  VARCHAR(18),
       unused     VARCHAR(18)
    )

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
    END
    

  CREATE TABLE #dbnames
    (
       name NVARCHAR(128)
    )

  INSERT INTO #dbnames
  EXEC('select name from master.dbo.sysdatabases where name in ('+@DatabaseList+
  ')')

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
                    INSERT INTO #tblholding
                    EXEC('
				select 
					''[''+b.name+''].[''+a.name+'']'' as tblname,
					b.name as SchemaName,
					a.name as TableName
				from
				['+@dbname+'].sys.objects a
				inner join
				['+@dbname+'].sys.schemas b
				on
					a.schema_id = b.schema_id
				where
					type = ''U''
				order by
					a.name
				')

                    WHILE (SELECT COUNT(*)
                           FROM   #tblholding) > 0
                      BEGIN
                          SET @table_name = (SELECT TOP 1 tblname
                                             FROM   #tblholding)

                          SELECT @schemaname = schemaname,
                                 @tablename = tablename
                          FROM   #tblholding
                          WHERE  tblname = @table_name

                          TRUNCATE TABLE #stats

                          EXEC('use '+@dbname+'
							insert into #Stats
							(tblname,RowCounts,Reserved,Data,IndexSize,Unused)
							exec sp_spaceused '''+
							@table_name+'''')

                          UPDATE #stats
                          SET    schemaname = @schemaname,
                                 tablename = @tablename
                          WHERE  schemaname IS NULL
                                 AND tablename IS NULL

                          SET @cmd ='insert into dbo.TableStats
							select ''' + @servername + ''',''' +
                          @dbname+''',SchemaName,Tablename,'+
                          'RowCounts,left(Reserved,len(Reserved) - 3),'+
                          'left(Data,len(Data) - 3),left(IndexSize,len(IndexSize) - 3),'+
                          'left(Unused,len(Unused) - 3),getdate() from #Stats'

						 EXEC(@cmd)

						DELETE FROM #tblholding
						WHERE  tblname = @table_name
					 END
				END
			END
		FETCH NEXT FROM db INTO @dbname
	END

	CLOSE db
	DEALLOCATE db

	DROP TABLE #tblholding
	DROP TABLE #stats

	SET nocount OFF 
