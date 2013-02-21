set nocount on;
if exists(select * from tempdb.dbo.sysobjects where name = '##TableStats')
	drop table ##TableStats;

Create table ##TableStats
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
);

DECLARE @table_name VARCHAR(128);
DECLARE @servername VARCHAR(256);
DECLARE @dbname     VARCHAR(256);
DECLARE @cmd		VARCHAR(8000);

CREATE TABLE #dbnames
(
    name NVARCHAR(128)
);

SET @servername = Cast(Serverproperty('servername') AS VARCHAR(256));

insert into #dbnames 
select name
FROM   MASTER.dbo.sysdatabases
WHERE  name NOT IN ( 'master', 'msdb', 'model', 'pubs',
                'northwind', 'tempdb' );

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
				set @cmd = '
				insert into ##TableStats
                SELECT
                    '''+@servername+'''									AS ServerName,
                    '''+@dbname+'''										AS DBName,
                    Object_schema_name(object_id,DB_ID('''+@dbname+'''))  AS SchemaName,
                    Object_name(object_id,DB_ID('''+@dbname+'''))         AS TableName,
                    Sum(CASE
                        WHEN index_id < 2 THEN row_count
                        ELSE 0
                        END)												AS RowCounts,
                    Sum(reserved_page_count) * 8							AS ReservedKB,
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
					object_schema_name(object_id,DB_ID('''+@dbname+''')) <> ''sys''
                GROUP  BY object_id'
				exec(@cmd);
            END
        END

    FETCH NEXT FROM db INTO @dbname
END

CLOSE db

DEALLOCATE db

DROP TABLE #dbnames;
select * from ##TableStats;