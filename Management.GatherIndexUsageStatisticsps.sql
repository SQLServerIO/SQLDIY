IF EXISTS (SELECT *
               FROM   tempdb.dbo.sysobjects
               WHERE  name = '##IndexUsageStatistics')
	DROP TABLE ##IndexUsageStatistics

CREATE TABLE ##IndexUsageStatistics(
	ServerName					nvarchar(128),
	DBName						nvarchar(128),
	SchemaName					nvarchar(128),
	TableName					nvarchar(128),
	IndexName					nvarchar(128),
	IsUsed						bit,
	IsExpensive					bit,
	TypeDescription				nvarchar(60),
	UserReads					bigint,
	UserWrites					bigint,
	Reads						bigint,
	LeafWrites					bigint,
	LeafPageSplits				bigint,
	NonleafWrites				bigint,
	NonleafPageSplits			bigint,
	UserSeeks					bigint,
	UserScans					bigint,
	UserLookups					bigint,
	UserUpdates					bigint,
	LastUserSeek				datetime,
	LastUserScan				datetime,
	LastUserLookup				datetime,
	LastUserUpdate				datetime,
	RecordCount					bigint,
	TotalPageCount				bigint,
	IndexSizeInMegabytes		float,
	AverageRecordSizeInBytes	float,
	IndexDepth					int,
	RecordedDateTime			datetime
) 

DECLARE		@cmd VARCHAR(8000)
DECLARE 	@servername VARCHAR(256)
DECLARE 	@dbname     VARCHAR(256)
DECLARE 	@recordeddatetime datetime
		
CREATE TABLE #dbnames
(
	name NVARCHAR(128)
);

SET @recordeddatetime = GETDATE();
SET @servername = CAST(Serverproperty('servername') AS VARCHAR(256));


DECLARE db CURSOR FAST_FORWARD FOR
SELECT name
FROM   master.dbo.sysdatabases where name not in('master','tempdb','model','msdb')

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
				INSERT INTO ##IndexUsageStatistics
				SELECT   *
						,'''+convert(varchar,@recordeddatetime, 121)+'''
				FROM     (SELECT '''+@servername+''' AS ''ServerName'',
								 '''+@dbname+''' AS ''DBName'',
								Object_schema_name(so.object_id,DB_ID('''+@dbname+''')) as ''SchemaName'',
								OBJECT_NAME(so.object_id,db_id('''+@dbname+''')) as ''TableName'',
								 i.name AS ''IndexName'',
								 Convert(BIT,CASE 
														 WHEN u.object_id IS NULL
														 THEN 0
														 ELSE 1
													   END) as ''IsUsed'',
								 Convert(BIT,CASE 
															  WHEN (i.type_desc <> ''HEAP''
																	AND (leaf_insert_count
																		   + leaf_update_count
																		   + leaf_delete_count) > (range_scan_count
																									 + singleton_lookup_count))
															  THEN 1
															  ELSE 0
															END) as ''IsExpensive'',
								 i.type_desc,
								 u.user_seeks
												+ u.user_scans
												+ u.user_lookups as ''UserReads'',
								 u.user_updates as ''UserWrites'',
								 Reads = range_scan_count
										   + singleton_lookup_count,
								 leaf_insert_count
												   + leaf_update_count
												   + leaf_delete_count as''LeafWrites'',
								 leaf_allocation_count as ''LeafPageSplits'',
								 nonleaf_insert_count
								 + nonleaf_update_count
								 + nonleaf_delete_count as ''NonleafWrites'',
								  nonleaf_allocation_count as ''NonleafPageSplits'',
								 u.user_seeks,
								 u.user_scans,
								 u.user_lookups,
								 u.user_updates,
								 u.last_user_seek,
								 u.last_user_scan,
								 u.last_user_lookup,
								 u.last_user_update,
								 f.record_count,
								 f.page_count,
								 f.IndexSizeInMegabytes,
								 f.AverageRecordSizeInBytes,
								 f.IndexDepth
						  FROM   ['+@dbname+'].sys.indexes i
								 INNER JOIN ['+@dbname+'].sys.objects so
								   ON so.object_id = i.object_id
								 INNER JOIN (SELECT   object_id,
													  index_id,
													  Sum(record_count) AS record_count,
													  Sum(page_count) AS page_count,
													  Convert(FLOAT,Sum(page_count))
														* 8192
														/ 1024
														/ 1024 AS ''IndexSizeInMegabytes'',
													  Avg(avg_record_size_in_bytes) AS ''AverageRecordSizeInBytes'',
													  Sum(index_depth) AS ''IndexDepth''
											 FROM     sys.Dm_db_index_physical_stats(DB_ID('''+@dbname+'''),NULL,NULL,NULL,''SAMPLED'') f
											 GROUP BY object_id,
													  index_id) f
								   ON i.object_id = f.object_id
									  AND i.index_id = f.index_id
								 LEFT JOIN ['+@dbname+'].sys.dm_db_index_usage_stats u
								   ON f.object_id = u.object_id
									  AND f.index_id = u.index_id
									  AND u.database_id = DB_ID('''+@dbname+''')
								 INNER JOIN sys.Dm_db_index_operational_stats(DB_ID('''+@dbname+'''),NULL,NULL,NULL) s
								   ON i.object_id = s.object_id
									  AND i.index_id = s.index_id
						  WHERE  so.TYPE = ''U''
						  ) indexes
						ORDER BY 
							TableName,
							IndexName'
				 EXEC(@cmd)
			END
		END
	FETCH NEXT FROM db INTO @dbname
END

CLOSE db
DEALLOCATE db

DROP TABLE #dbnames
select * from ##IndexUsageStatistics