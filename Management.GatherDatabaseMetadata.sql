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
CREATE TABLE [dbo].[DatabaseMetadata] (
	[ServerName] [varchar] (256),
	[DBName] [varchar] (256),
	[TableName] [varchar] (128),
	[Schema] [varchar] (128),
	[TableDescription] [varchar] (2000),
	[RecordedDateTime]		[datetime]        
)

CREATE TABLE [dbo].[DatabaseMetadataHistory] (
	[ServerName] [varchar] (256),
	[DBName] [varchar] (256),
	[TableName] [varchar] (128),
	[Schema] [varchar] (128),
	[TableDescription] [varchar] (2000),
	[RecordedDateTime]		[datetime]        
)
************************************************************************************************/
IF EXISTS (
  SELECT 1
    FROM INFORMATION_SCHEMA.ROUTINES 
   WHERE SPECIFIC_NAME = N'GatherDatabaseMetadata' 
)
DROP PROCEDURE GatherDatabaseMetadata
GO

CREATE PROCEDURE GatherDatabaseMetadata
				@DatabaseList           VARCHAR(MAX),
				@ExcludeSystemDatabases tinyint = 1
AS
  SET NOCOUNT ON
/*****************************************
* Truncate holding tables
*****************************************/
  IF EXISTS (SELECT 1
             FROM   dbo.DatabaseMetadata)
    BEGIN
        INSERT INTO dbo.DatabaseMetadataHistory
        SELECT *
        FROM   DatabaseMetadata;

        TRUNCATE TABLE dbo.DatabaseMetadata;
    END

  DECLARE @cmd VARCHAR(8000),
		@table_name VARCHAR(128),
		@servername VARCHAR(256),
		@dbname     VARCHAR(256),
		@schemaname NVARCHAR(128),
		@tablename  NVARCHAR(128),
		@recordeddatetime datetime

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
					insert into dbo.DatabaseMetadata
					SELECT
					  '''+@servername+'''                                                          AS ''ServerName'',
					  '''+@dbname+'''                                                              AS ''DBName'',
					  o.name    			                                                       AS ''TableName'',
					  Object_schema_name(o.object_id,DB_ID('''+@dbname+'''))                       AS ''SchemaName'',
					  Replace(Replace(Cast(e.value AS VARCHAR(2000)), Char(13), ''''), Char(11), '''') AS ''TableDescription'',
					  '''+convert(varchar,@recordeddatetime, 121)+'''
					FROM
					  ['+@dbname+'].sys.objects o
					LEFT JOIN  ['+@dbname+'].sys.extended_properties e
					  ON o.object_id = e.major_id
						 AND e.minor_id = 0
					WHERE
					  o.type = ''U''
					ORDER      BY
					  Object_schema_name(o.object_id,DB_ID('''+@dbname+''')),
					  o.object_id'
					 EXEC(@cmd)
				END
			END
		FETCH NEXT FROM db INTO @dbname
	END

	CLOSE db
	DEALLOCATE db
	
	DROP TABLE #dbnames
	SET nocount OFF 