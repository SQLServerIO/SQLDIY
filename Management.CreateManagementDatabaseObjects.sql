USE [Management]
GO

/****** Object:  Table [dbo].[BlockingChains]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[BlockingChains](
	[ServerName] [varchar](255) NOT NULL,
	[SampleTime] [datetime] NOT NULL,
	[Spid] [int] NULL,
	[SpidBlocked] [int] NULL,
	[WaitType] [varchar](255) NULL,
	[WaitTime] [bigint] NULL,
	[PhysicalIO] [bigint] NULL,
	[CPUInSeconds] [bigint] NULL,
	[MemoryUsed] [bigint] NULL,
	[Name] [nvarchar](128) NOT NULL,
	[NumberOfOpenTransactions] [tinyint] NULL,
	[Status] [varchar](20) NULL,
	[HostName] [varchar](50) NULL,
	[ProgramName] [varchar](100) NULL,
	[CommandIssued] [varchar](100) NULL,
	[DomainName] [varchar](100) NULL,
	[DomainUserName] [varchar](200) NULL,
	[LoginName] [varchar](100) NULL,
	[EventTpe] [varchar](255) NULL,
	[Parameters] [varchar](255) NULL,
	[EventInfo] [varchar](4000) NULL,
	[CommandText] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Table [dbo].[BlockingChainsHistory]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[BlockingChainsHistory](
	[ServerName] [varchar](255) NOT NULL,
	[SampleTime] [datetime] NOT NULL,
	[Spid] [int] NULL,
	[SpidBlocked] [int] NULL,
	[WaitType] [varchar](255) NULL,
	[WaitTime] [bigint] NULL,
	[PhysicalIO] [bigint] NULL,
	[CPUInSeconds] [bigint] NULL,
	[MemoryUsed] [bigint] NULL,
	[Name] [nvarchar](128) NOT NULL,
	[NumberOfOpenTransactions] [tinyint] NULL,
	[Status] [varchar](20) NULL,
	[HostName] [varchar](50) NULL,
	[ProgramName] [varchar](100) NULL,
	[CommandIssued] [varchar](100) NULL,
	[DomainName] [varchar](100) NULL,
	[DomainUserName] [varchar](200) NULL,
	[LoginName] [varchar](100) NULL,
	[EventTpe] [varchar](255) NULL,
	[Parameters] [varchar](255) NULL,
	[EventInfo] [varchar](4000) NULL,
	[CommandText] [varchar](max) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Table [dbo].[DatabaseMetadata]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[DatabaseMetadata](
	[ServerName] [varchar](256) NULL,
	[DBName] [varchar](256) NULL,
	[TableName] [varchar](128) NULL,
	[Schema] [varchar](128) NULL,
	[TableDescription] [varchar](2000) NULL,
	[RecordedDateTime] [datetime] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Table [dbo].[DatabaseMetadataHistory]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[DatabaseMetadataHistory](
	[ServerName] [varchar](256) NULL,
	[DBName] [varchar](256) NULL,
	[TableName] [varchar](128) NULL,
	[Schema] [varchar](128) NULL,
	[TableDescription] [varchar](2000) NULL,
	[RecordedDateTime] [datetime] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Table [dbo].[DB]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[DB](
	[DBName] [varchar](255) NOT NULL,
	[ServerName] [varchar](255) NOT NULL,
	[CreateDate] [datetime] NULL,
	[LastActiveDate] [datetime] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Table [dbo].[DBFile]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[DBFile](
	[DBFileName] [varchar](255) NULL,
	[DBName] [varchar](255) NULL,
	[ServerName] [varchar](255) NULL,
	[DriveName] [char](1) NULL,
	[CreateDate] [datetime] NULL,
	[LastActiveDate] [datetime] NULL,
	[DBFileGroup] [varchar](255) NULL,
	[FileSizeKB] [decimal](38, 2) NULL,
	[SpaceUsedKB] [decimal](38, 2) NULL,
	[FileType] [varchar](10) NULL,
	[RecordedDateTime] [datetime] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Table [dbo].[DBFileHistory]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[DBFileHistory](
	[DBFileName] [varchar](255) NULL,
	[DBName] [varchar](255) NULL,
	[ServerName] [varchar](255) NULL,
	[DriveName] [char](1) NULL,
	[CreateDate] [datetime] NULL,
	[LastActiveDate] [datetime] NULL,
	[DBFileGroup] [varchar](255) NULL,
	[FileSizeKB] [decimal](38, 2) NULL,
	[SpaceUsedKB] [decimal](38, 2) NULL,
	[FileType] [varchar](10) NULL,
	[RecordedDateTime] [datetime] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Table [dbo].[IndexFragmentationLevels]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[IndexFragmentationLevels](
	[ServerName] [nvarchar](128) NULL,
	[DBName] [nvarchar](128) NULL,
	[PartitionNumber] [smallint] NULL,
	[SchemaName] [nvarchar](128) NULL,
	[TableName] [nvarchar](128) NULL,
	[IndexName] [nvarchar](128) NULL,
	[Fragmentation] [float] NULL,
	[PageTotalCount] [int] NULL,
	[RangeScanCount] [bigint] NULL,
	[RecordedDateTime] [datetime] NULL
) ON [PRIMARY]

GO

/****** Object:  Table [dbo].[IndexFragmentationLevelsHistory]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[IndexFragmentationLevelsHistory](
	[ServerName] [nvarchar](128) NULL,
	[DBName] [nvarchar](128) NULL,
	[PartitionNumber] [smallint] NULL,
	[SchemaName] [nvarchar](128) NULL,
	[TableName] [nvarchar](128) NULL,
	[IndexName] [nvarchar](128) NULL,
	[Fragmentation] [float] NULL,
	[PageTotalCount] [int] NULL,
	[RangeScanCount] [bigint] NULL,
	[RecordedDateTime] [datetime] NULL
) ON [PRIMARY]

GO

/****** Object:  Table [dbo].[IndexUsageStatistics]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[IndexUsageStatistics](
	[ServerName] [nvarchar](128) NULL,
	[DBName] [nvarchar](128) NULL,
	[SchemaName] [nvarchar](128) NULL,
	[TableName] [nvarchar](128) NULL,
	[IndexName] [nvarchar](128) NULL,
	[IsUsed] [bit] NULL,
	[IsExpensive] [bit] NULL,
	[TypeDescription] [nvarchar](60) NULL,
	[UserReads] [bigint] NULL,
	[UserWrites] [bigint] NULL,
	[Reads] [bigint] NULL,
	[LeafWrites] [bigint] NULL,
	[LeafPageSplits] [bigint] NULL,
	[NonleafWrites] [bigint] NULL,
	[NonleafPageSplits] [bigint] NULL,
	[UserSeeks] [bigint] NULL,
	[UserScans] [bigint] NULL,
	[UserLookups] [bigint] NULL,
	[UserUpdates] [bigint] NULL,
	[LastUserSeek] [datetime] NULL,
	[LastUserScan] [datetime] NULL,
	[LastUserLookup] [datetime] NULL,
	[LastUserUpdate] [datetime] NULL,
	[RecordCount] [bigint] NULL,
	[TotalPageCount] [bigint] NULL,
	[IndexSizeInMegabytes] [float] NULL,
	[AverageRecordSizeInBytes] [float] NULL,
	[IndexDepth] [int] NULL,
	[RecordedDateTime] [datetime] NULL
) ON [PRIMARY]

GO

/****** Object:  Table [dbo].[IndexUsageStatisticsHistory]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[IndexUsageStatisticsHistory](
	[ServerName] [nvarchar](128) NULL,
	[DBName] [nvarchar](128) NULL,
	[SchemaName] [nvarchar](128) NULL,
	[TableName] [nvarchar](128) NULL,
	[IndexName] [nvarchar](128) NULL,
	[IsUsed] [bit] NULL,
	[IsExpensive] [bit] NULL,
	[TypeDescription] [nvarchar](60) NULL,
	[UserReads] [bigint] NULL,
	[UserWrites] [bigint] NULL,
	[Reads] [bigint] NULL,
	[LeafWrites] [bigint] NULL,
	[LeafPageSplits] [bigint] NULL,
	[NonleafWrites] [bigint] NULL,
	[NonleafPageSplits] [bigint] NULL,
	[UserSeeks] [bigint] NULL,
	[UserScans] [bigint] NULL,
	[UserLookups] [bigint] NULL,
	[UserUpdates] [bigint] NULL,
	[LastUserSeek] [datetime] NULL,
	[LastUserScan] [datetime] NULL,
	[LastUserLookup] [datetime] NULL,
	[LastUserUpdate] [datetime] NULL,
	[RecordCount] [bigint] NULL,
	[TotalPageCount] [bigint] NULL,
	[IndexSizeInMegabytes] [float] NULL,
	[AverageRecordSizeInBytes] [float] NULL,
	[IndexDepth] [int] NULL,
	[RecordedDateTime] [datetime] NULL
) ON [PRIMARY]

GO

/****** Object:  Table [dbo].[ServerDrive]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[ServerDrive](
	[DriveName] [varchar](20) NOT NULL,
	[ServerName] [varchar](255) NOT NULL,
	[FreeSpace] [decimal](38, 2) NULL,
	[TotalSpace] [decimal](38, 2) NULL,
	[CreateDate] [datetime] NULL,
	[LastActiveDate] [datetime] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Table [dbo].[ServerJobHistory]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[ServerJobHistory](
	[InstanceId] [int] NOT NULL,
	[ServerName] [nvarchar](128) NOT NULL,
	[ServerJobName] [nvarchar](128) NOT NULL,
	[StepName] [nvarchar](128) NULL,
	[ErrorMessageId] [int] NULL,
	[ErrorSeverityLevel] [int] NULL,
	[ErrorMessage] [nvarchar](1024) NULL,
	[RunStatus] [int] NULL,
	[RunDate] [int] NULL,
	[RunTime] [char](8) NULL,
	[RunDuration] [char](8) NULL,
	[RetriesAttempted] [int] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Table [dbo].[ServerJobs]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[ServerJobs](
	[ServerName] [nvarchar](128) NOT NULL,
	[JobName] [nvarchar](128) NOT NULL,
	[JobEnabled] [tinyint] NOT NULL,
	[JobDescription] [nvarchar](512) NULL,
	[LastRunOutcome] [tinyint] NOT NULL,
	[LastOutcomeMessage] [nvarchar](1024) NULL,
	[LastRunDate] [int] NOT NULL,
	[lastRunTime] [int] NOT NULL,
	[JobDuration] [int] NOT NULL
) ON [PRIMARY]

GO

/****** Object:  Table [dbo].[ServerJobSchedules]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[ServerJobSchedules](
	[ServerName] [nvarchar](128) NOT NULL,
	[JobName] [nvarchar](128) NOT NULL,
	[ScheduleName] [nvarchar](128) NULL,
	[ScheduleEnabled] [int] NULL,
	[JobFrequency] [varchar](36) NULL,
	[MonthlyFrequency] [varchar](6) NULL,
	[RunsOn] [varchar](100) NULL,
	[IntervalType] [varchar](21) NULL,
	[TimeInterval] [int] NULL,
	[OccursEvery] [varchar](11) NULL,
	[BeginDateExecutingJob] [varchar](10) NULL,
	[ExecutingAt] [varchar](8) NULL,
	[EndDateExecutingJob] [varchar](10) NULL,
	[EndTimeEexecutingJob] [varchar](8) NULL,
	[ScheduleCreated] [datetime] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Table [dbo].[ServerJobSteps]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[ServerJobSteps](
	[ServerName] [nvarchar](128) NOT NULL,
	[ServerJobName] [varchar](128) NOT NULL,
	[JobStep] [varchar](128) NULL,
	[SubSystem] [varchar](40) NULL,
	[DatabaseName] [varchar](128) NULL,
	[DatabaseUser] [varchar](128) NULL,
	[LastRunOutcome] [int] NULL,
	[LastRunDuration] [char](8) NULL,
	[LastRunDate] [int] NULL,
	[LastRunTime] [char](8) NOT NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Table [dbo].[Serverlist]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[Serverlist](
	[QueriedServer] [varchar](255) NULL,
	[ReturnedServer] [varchar](255) NULL,
	[Version] [varchar](500) NULL,
	[PingFailed] [bit] NULL,
	[LoginFailed] [bit] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Table [dbo].[ServerWaits]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[ServerWaits](
	[RecordID] [int] IDENTITY(1,1) NOT NULL,
	[ServerName] [varchar](255) NOT NULL,
	[WaitType] [nvarchar](60) NULL,
	[WaitingTasksCount] [bigint] NULL,
	[WaitingTasksCountFromStart] [bigint] NULL,
	[WaitTimeInMilliseconds] [bigint] NULL,
	[WaitTimeInMillisecondsFromStart] [bigint] NULL,
	[MaximumWaitTimeMilliseconds] [bigint] NULL,
	[MaximumWaitTimeMillisecondsFromStart] [bigint] NULL,
	[SignalWaitTimeMilliseconds] [bigint] NULL,
	[SignalWaitTimeMillisecondsFromStart] [bigint] NULL,
	[RecordedDateTime] [datetime] NULL,
	[IntervalInMilliseconds] [bigint] NULL,
	[FirstMeasureFromStart] [bit] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Table [dbo].[ServerWaitsHistory]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[ServerWaitsHistory](
	[RecordID] [int] NOT NULL,
	[ServerName] [varchar](255) NOT NULL,
	[WaitType] [nvarchar](60) NULL,
	[WaitingTasksCount] [bigint] NULL,
	[WaitingTasksCountFromStart] [bigint] NULL,
	[WaitTimeInMilliseconds] [bigint] NULL,
	[WaitTimeInMillisecondsFromStart] [bigint] NULL,
	[MaximumWaitTimeMilliseconds] [bigint] NULL,
	[MaximumWaitTimeMillisecondsFromStart] [bigint] NULL,
	[SignalWaitTimeMilliseconds] [bigint] NULL,
	[SignalWaitTimeMillisecondsFromStart] [bigint] NULL,
	[RecordedDateTime] [datetime] NULL,
	[IntervalInMilliseconds] [bigint] NULL,
	[FirstMeasureFromStart] [bit] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Table [dbo].[StatisticsInformation]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE TABLE [dbo].[StatisticsInformation](
	[ServerName] [nvarchar](128) NULL,
	[DBName] [nvarchar](128) NULL,
	[SchemaName] [nvarchar](128) NULL,
	[TableName] [nvarchar](128) NULL,
	[StatisticsName] [nvarchar](128) NULL,
	[ColumnName] [nvarchar](128) NULL,
	[LastUpdatedDate] [datetime] NULL,
	[RecordedDateTime] [datetime] NULL
) ON [PRIMARY]

GO

/****** Object:  Table [dbo].[TableStats]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[TableStats](
	[ServerName] [varchar](255) NULL,
	[DBName] [varchar](255) NULL,
	[SchemaName] [nvarchar](128) NULL,
	[TableName] [nvarchar](128) NULL,
	[RowCounts] [numeric](38, 0) NULL,
	[ReservedKB] [numeric](38, 0) NULL,
	[DataKB] [numeric](38, 0) NULL,
	[IndexSizeKB] [numeric](38, 0) NULL,
	[UnusedKB] [numeric](38, 0) NULL,
	[RecordedDateTime] [datetime] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Table [dbo].[VirtualFileStats]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[VirtualFileStats](
	[RecordID] [int] IDENTITY(1,1) NOT NULL,
	[ServerName] [varchar](255) NOT NULL,
	[DBID] [int] NOT NULL,
	[FileID] [int] NOT NULL,
	[Reads] [bigint] NULL,
	[ReadsFromStart] [bigint] NULL,
	[Writes] [bigint] NULL,
	[WritesFromStart] [bigint] NULL,
	[BytesRead] [bigint] NULL,
	[BytesReadFromStart] [bigint] NULL,
	[BytesWritten] [bigint] NULL,
	[BytesWrittenFromStart] [bigint] NULL,
	[IostallInMilliseconds] [bigint] NULL,
	[IostallInMillisecondsFromStart] [bigint] NULL,
	[IostallReadsInMilliseconds] [bigint] NULL,
	[IostallReadsInMillisecondsFromStart] [bigint] NULL,
	[IostallWritesInMilliseconds] [bigint] NULL,
	[IostallWritesInMillisecondsFromStart] [bigint] NULL,
	[RecordedDateTime] [datetime] NULL,
	[IntervalInMilliseconds] [bigint] NULL,
	[FirstMeasureFromStart] [bit] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

/****** Object:  Table [dbo].[VirtualFileStatsHistory]    Script Date: 2/28/2013 2:11:43 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[VirtualFileStatsHistory](
	[RecordID] [int] NOT NULL,
	[ServerName] [varchar](255) NOT NULL,
	[DBID] [int] NOT NULL,
	[FileID] [int] NOT NULL,
	[Reads] [bigint] NULL,
	[ReadsFromStart] [bigint] NULL,
	[Writes] [bigint] NULL,
	[WritesFromStart] [bigint] NULL,
	[BytesRead] [bigint] NULL,
	[BytesReadFromStart] [bigint] NULL,
	[BytesWritten] [bigint] NULL,
	[BytesWrittenFromStart] [bigint] NULL,
	[IostallInMilliseconds] [bigint] NULL,
	[IostallInMillisecondsFromStart] [bigint] NULL,
	[IostallReadsInMilliseconds] [bigint] NULL,
	[IostallReadsInMillisecondsFromStart] [bigint] NULL,
	[IostallWritesInMilliseconds] [bigint] NULL,
	[IostallWritesInMillisecondsFromStart] [bigint] NULL,
	[RecordedDateTime] [datetime] NULL,
	[IntervalInMilliseconds] [bigint] NULL,
	[FirstMeasureFromStart] [bit] NULL
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO


