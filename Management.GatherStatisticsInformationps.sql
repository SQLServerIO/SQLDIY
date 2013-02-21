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

insert into #dbnames 
select name from master.dbo.sysdatabases

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

select * from #statsinfo	
drop TABLE #statsinfo	  
DROP TABLE #dbnames
