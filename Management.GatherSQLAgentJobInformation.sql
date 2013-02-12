/************************************************************************************************
Gather SQL Agent Job Information
By Wesley D. Brown
Date 08/24/2004
**Mod**
**Description**
This script looks through the ServerJobs tables in msdb to pull all job information including
job history.
Functions:
Dump job information on fileshare for pickup by primary management server
**End Discription**

**Change Log**
Bug Fix:
**End Change Log**
************************************************************************************************/
if exists (select * from  dbo.sysobjects where id = object_id(N' [dbo].[ServerJobs]')  and xtype = 'U')
begin
	drop table  [dbo].[ServerJobs]
end
CREATE TABLE  [dbo].[ServerJobs] (
	[ServerName] [nvarchar] (128) NOT NULL ,
	[JobName] [nvarchar] (128) NOT NULL ,
	[JobEnabled] [tinyint] NOT NULL ,
	[JobDescription] [nvarchar] (512) NULL ,
	[LastRunOutcome] [tinyint] NOT NULL ,
	[LastOutcomeMessage] [nvarchar] (1024) NULL ,
	[LastRunDate] [int] NOT NULL ,
	[lastRunTime] [int] NOT NULL ,
	[JobDuration] [int] NOT NULL 
) 


if exists (select * from  dbo.sysobjects where id = object_id(N' [dbo].[ServerJobSchedules]')  and xtype = 'U')
begin
	drop table  [dbo].[ServerJobSchedules]
end
create table  [dbo].[ServerJobSchedules] (
	[ServerName] [nvarchar] (128) NOT NULL ,
	[JobName] [nvarchar] (128) NOT NULL ,
	[ScheduleName] [nvarchar] (128) NULL ,
	[ScheduleEnabled] [int] NULL ,
	[JobFrequency] [varchar] (36) NULL ,
	[MonthlyFrequency] [varchar] (6) NULL ,
	[RunsOn] [varchar] (100) NULL ,
	[IntervalType] [varchar] (21) NULL ,
	[TimeInterval] [int] NULL ,
	[OccursEvery] [varchar] (11) NULL ,
	[BeginDateExecutingJob] [varchar] (10) NULL ,
	[ExecutingAt] [varchar] (8) NULL ,
	[EndDateExecutingJob] [varchar] (10) NULL ,
	[EndTimeEexecutingJob] [varchar] (8) NULL ,
	[ScheduleCreated] [datetime] NULL 
) ON [PRIMARY]

if exists (select * from  dbo.sysobjects where id = object_id(N' [dbo].[ServerJobSteps]')  and xtype = 'U')
begin
	drop table  [dbo].[ServerJobSteps]
end
CREATE TABLE  [dbo].[ServerJobSteps] (
	[ServerName] [nvarchar] (128) NOT NULL ,
	[ServerJobName] [varchar] (128) NOT NULL ,
	[JobStep] [varchar] (128) NULL ,
	[SubSystem] [varchar] (40) NULL ,
	[DatabaseName] [varchar] (128) NULL ,
	[DatabaseUser] [varchar] (128) NULL ,
	[LastRunOutcome] [int] NULL ,
	[LastRunDuration] [char] (8) NULL ,
	[LastRunDate] [int] NULL ,
	[LastRunTime] [char] (8) NOT NULL 
) ON [PRIMARY]

if exists (select * from  dbo.sysobjects where id = object_id(N' [dbo].[ServerJobHistory]')  and xtype = 'U')
begin
	drop table  [dbo].[ServerJobHistory]
end
CREATE TABLE  [dbo].[ServerJobHistory] (
	InstanceId int NOT NULL,
	[ServerName] [nvarchar] (128) NOT NULL ,
	[ServerJobName] [nvarchar] (128) NOT NULL ,
	[StepName] [nvarchar] (128) NULL ,
	[ErrorMessageId] [int] NULL ,
	[ErrorSeverityLevel] [int] NULL ,
	[ErrorMessage] [nvarchar] (1024) NULL ,
	[RunStatus] [int] NULL ,
	[RunDate] [int] NULL ,
	[RunTime] [char] (8) NULL ,
	[RunDuration] [char] (8) NULL ,
	[RetriesAttempted] [int] NULL 
) ON [PRIMARY]
