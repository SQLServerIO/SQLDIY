/************************************************************************************************
Metadata
By Wesley D. Brown
Date 06/27/2011

**Description**
This uses sys.extended_properties to pull back comments attached to columns and tables.
It requires that MS_Description be the name of the property. 
It also pulls back all column definitions stored in the systables for for that database.
Functions:
**End Discription**
**Change Log**
Bug Fix:
**End Change Log**
************************************************************************************************/
/************************************************************************************************
* Create these tables first if they don't exist in your system. 
CREATE TABLE [dbo].[TableMetadata] (
	[ServerName] [varchar] (256),
	[DBName] [varchar] (256),
	[TableName] [varchar] (128),
	[Schema] [varchar] (128),
	[ColumnOrder] [int],
	[ColumnName] [varchar] (128),
	[ColumnType] [varchar] (128),
	[ColumnLength] [int] ,
	[ColumnDescription] [varchar] (2000),
	RecordedDateTime		datetime        
)

CREATE TABLE [dbo].[TableMetadataHistory] (
	[ServerName] [varchar] (256),
	[DBName] [varchar] (256),
	[TableName] [varchar] (128),
	[Schema] [varchar] (128),
	[ColumnOrder] [int],
	[ColumnName] [varchar] (128),
	[ColumnType] [varchar] (128),
	[ColumnLength] [int] ,
	[ColumnDescription] [varchar] (2000),
	RecordedDateTime		datetime        
)
************************************************************************************************/
IF EXISTS (
  SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE SPECIFIC_NAME = N'GatherTableMetadata' 
)
DROP PROCEDURE GatherTableMetadata
GO


-- exec GatherTableMetadata 'ALL',1
CREATE PROCEDURE GatherTableMetadata
				@DatabaseList           VARCHAR(MAX),
				@ExcludeSystemDatabases tinyint = 1
AS
  SET NOCOUNT ON
/*****************************************
* Truncate holding tables
*****************************************/
  IF EXISTS (SELECT 1
             FROM   dbo.TableMetadata)
    BEGIN
        INSERT INTO dbo.TableMetadataHistory
        SELECT *
        FROM   TableMetadata;

        TRUNCATE TABLE dbo.TableMetadata;
    END

  DECLARE @cmd VARCHAR(8000),
		@table_name VARCHAR(128),
		@servername VARCHAR(256),
		@dbname     VARCHAR(256),
		@schemaname NVARCHAR(128),
		@tablename  NVARCHAR(128),
		@recordeddatetime datetime

  CREATE TABLE #tblholding
    (
       tblname    VARCHAR(500),
       schemaname NVARCHAR(128),
       tablename  NVARCHAR(128)
    )

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
					set @cmd ='
					insert into dbo.TableMetadata
					SELECT
					  '''+@servername+'''                                                          AS ''ServerName'',
					  '''+@dbname+'''                                                              AS ''DBName'',
					  Object_name(o.object_id)                                                     AS ''TableName'',
					  Object_schema_name(o.object_id)                                              AS ''SchemaName'',
					  c.column_id                                                                  AS ''ColumnOrder'',
					  c.name                                                                       AS ''ColumnName'',
					  s.name                                                                       AS ''ColumnType'',
					  c.max_length                                                                 AS ''ColumnLength'',
					  Replace(Replace(Cast(e.value AS VARCHAR(2000)), Char(13), ''''), Char(11), '''') AS ''ColumnDescription'',
					  '''+convert(varchar,@recordeddatetime, 121)+'''
					FROM
					  ['+@dbname+'].sys.objects o
					INNER JOIN ['+@dbname+'].sys.columns c
					  ON o.object_id = c.object_id
					INNER JOIN ['+@dbname+'].sys.types s
					  ON c.system_type_id = s.system_type_id
					LEFT JOIN  ['+@dbname+'].sys.extended_properties e
					  ON c.object_id = e.major_id
						 AND c.column_id = e.minor_id
					WHERE
					  o.type = ''U''
					ORDER      BY
					  Object_schema_name(o.object_id),
					  o.object_id,
					  c.column_id'
					 EXEC(@cmd)
					print (@cmd)
				END
			END
		FETCH NEXT FROM db INTO @dbname
	END

	CLOSE db
	DEALLOCATE db
	
	DROP TABLE #dbnames
	DROP TABLE #tblholding

	SET nocount OFF 