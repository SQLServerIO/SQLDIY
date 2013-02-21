IF EXISTS (SELECT *
               FROM   tempdb.dbo.sysobjects
               WHERE  name = '##ServerJobs')
drop table ##ServerJobs;

  CREATE TABLE  ##ServerJobs (
	[ServerName] [nvarchar] (128) NOT NULL ,
	[JobName] [nvarchar] (128) NOT NULL ,
	[JobEnabled] [tinyint] NOT NULL ,
	[JobDescription] [nvarchar] (512) NULL ,
	[LastRunOutcome] [tinyint] NOT NULL ,
	[LastOutcomeMessage] [nvarchar] (1024) NULL ,
	[LastRunDate] [int] NOT NULL ,
	[lastRunTime] [int] NOT NULL ,
	[JobDuration] [int] NOT NULL 
);

IF EXISTS (SELECT *
               FROM   tempdb.dbo.sysobjects
               WHERE  name = '##ServerJobSchedules')
	drop table ##ServerJobschedules;

create table  ##ServerJobSchedules (
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
);

IF EXISTS (SELECT *
               FROM   tempdb.dbo.sysobjects
               WHERE  name = '##ServerJobSteps')
	drop table ##ServerJobsteps;
CREATE TABLE  ##ServerJobSteps (
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
);

IF EXISTS (SELECT *
               FROM   tempdb.dbo.sysobjects
               WHERE  name = '##ServerJobHistory')
	drop table ##ServerJobHistory;

CREATE TABLE  ##ServerJobHistory (
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
);

insert into ##ServerJobs
select 
	@@servername as ServerName
	,a.name as JobName
	,a.enabled as JobEnabled
	,a.description as JobDescription
	,b.last_run_outcome as LastRunOutcome
	,b.last_outcome_message as LastOutcomeMessage
	,b.last_run_date as LastRunDate
	,b.last_run_time as lastRunTime
	,b.last_run_duration as JobDuration
from
	msdb.dbo.sysjobservers b
inner join
	msdb.dbo.sysjobs a
on
	a.job_id = b.job_id;

declare @x int;
declare @y int;
declare @z int;
declare @counter smallint;
declare @days varchar(100);
declare @day varchar(10);
declare @jname sysname;
declare @freq_interval int;
declare @jid varchar(50);

IF EXISTS (select * from tempdb.dbo.sysobjects where name = '##temp')
drop table ##temp;

create table ##temp
(
	jid varchar(50)  COLLATE database_default, 
	jname sysname  COLLATE database_default, 
	jdays varchar(100)  COLLATE database_default
);

declare c cursor for 
select 
	job_id, 
	name, 
	freq_interval 
from 
	msdb.dbo.sysschedules
inner join
	msdb.dbo.sysjobschedules
on
	msdb.dbo.sysjobschedules.schedule_id = msdb.dbo.sysschedules.schedule_id
where 
	freq_type = 8
open c
fetch next from c into @jid, @jname, @freq_interval
while @@fetch_status = 0
begin
	set @counter = 0
	set @x = 64
	set @y = @freq_interval
	set @z = @y
	set @days = '
	set @day = '
	
	while @y <> 0
	begin
		select @y = @y - @x
		select @counter = @counter + 1
		if @y < 0 
		begin
			set @y = @z
			goto start
		end;
	
	
		select @day = case @x
		when 1 then 'sunday'
		when 2 then 'monday'
		when 4 then 'tuesday'
		when 8 then 'wednesday'
		when 16 then 'thursday'
		when 32 then 'friday'
		when 64 then 'saturday'
		end;
	
		select @days = @day + ',' + @days
		start:
		select @x = case @counter
		when 1 then 32
		when 2 then 16
		when 3 then 8
		when 4 then 4
		when 5 then 2
		when 6 then 1
	end;
	
	set @z = @y;
	if @y = 0 break
	end;
	
	insert into ##temp select @jid, @jname, left(@days,len(@days)-1);
	fetch next from c into @jid, @jname, @freq_interval;
	
end
close c
deallocate c

insert into ##ServerJobSchedules
select 
	@@servername as ServerName,
	b.name JobName, 
	isnull(a.name,'No Schedule') as ScheduleName, 
	a.enabled as ScheduleEnabled,
	case freq_type 
	when 1 then 'once'
	when 4 then 'daily'
	when 8 then 'weekly'
	when 16 then 'monthly'
	when 32 then 'monthly relative'
	when 64 then 'execute when sql server agent starts'
	when 128 then 'execute when sql agent is idle'
	end as [JobFrequency],
	case freq_type 
	when 32 then case freq_relative_interval
	when 1 then 'first'
	when 2 then 'second'
	when 4 then 'third'
	when 8 then 'fourth'
	when 16 then 'last'
	end
	else 'NA'
	end as [MonthlyFrequency],
	case freq_type
		when 4 then 'every '+ cast(freq_interval as varchar(2))+ ' day(s)'
		when 16 then cast(freq_interval as char(2)) + 'th day of month'
		when 32 then case freq_interval 
		when 1 then 'sunday'
		when 2 then 'monday'
		when 3 then 'tuesday'
		when 4 then 'wednesday'
		when 5 then 'thursday'
		when 6 then 'friday'
		when 7 then 'saturday'
		when 8 then 'day'
		when 9 then 'weekday'
		when 10 then 'weekend day'
	end
	when 8 then c.jdays
	else 'NA'
	end as [RunsOn],
	case freq_subday_type
	when 0 then 'NA'
	when 1 then 'at the specified time'
	when 2 then 'seconds'
	when 4 then 'minutes'
	when 8 then 'hours'
	end as [IntervalType], 
	case freq_subday_type 
	when 1 then 0
	else freq_subday_interval 
	end as [TimeInterval],

	case freq_type 
	when 8 then cast(freq_recurrence_factor as char(2)) + ' week(s)'
	when 16 then cast(freq_recurrence_factor as char(2))+ ' month(s)'
	when 32 then cast(freq_recurrence_factor as char(2))+ ' month(s)'
	else 'NA'
	end as [OccursEvery],

	left(active_start_date,4) + '-' + substring(cast(active_start_date as char),5,2) + '-' + right(active_start_date,2) [BeginDateExecutingJob],

	left(replicate('0', 6-len(active_start_time)) + cast(active_start_time as char(6)),2) + ':' + substring(replicate('0', 6-len(active_start_time)) + cast(active_start_time as char(6)),3,2) + ':' + substring(replicate('0', 6-len(active_start_time)) + cast(active_start_time as char(6)),5,2) [ExecutingAt],

	left(active_end_date,4) + '-' + substring(cast(active_end_date as char),5,2) + '-' + right(active_end_date,2) [EndDateExecutingJob],

	left(replicate('0', 6-len(active_end_time)) + cast(active_end_time as char(6)),2) + ':' + substring(replicate('0', 6-len(active_end_time)) + cast(active_end_time as char(6)),3,2) + ':' + substring(replicate('0', 6-len(active_end_time)) + cast(active_end_time as char(6)),5,2) [EndTimeExecutingJob],

	a.date_created [ScheduleCreated]
from 
 	msdb..sysschedules a 
inner join
	msdb.dbo.sysjobschedules sj
on 
	a.schedule_id = sj.schedule_id
right outer join 
	msdb..sysjobs b 
on 
	sj.job_id = b.job_id 
left outer join 
	##temp c 
on 
	a.name = c.jname collate Latin1_General_BIN
and 
	sj.job_id = c.jid collate Latin1_General_BIN;

insert into ##ServerJobSteps
select 
	@@servername as ServerName
	,b.name as ServerJobName
	,step_name as JobStep
	,subsystem as SubSystem
	,isnull(database_name,'NA') as DatabaseName
	,isnull(database_user_name,'NA') as DatabaseUser
	,last_run_outcome as LastRunOutcome
	,case len(last_run_duration)
		when 1 then cast('00:00:0' + cast(last_run_duration as char) as char (8))
		when 2 then cast('00:00:' + cast(last_run_duration as char) as char (8))
		when 3 then cast('00:0'	+ left(right(last_run_duration,3),1)	+':' + right(last_run_duration,2) as char (8))
		when 4 then cast('00:' 	+ left(right(last_run_duration,4),2)  +':' + right(last_run_duration,2) as char (8))
		when 5 then cast('0' + left(right(last_run_duration,5),1) +':' + left(right(last_run_duration,4),2) +':' + right(last_run_duration,2) as char (8))
		when 6 then cast(left(right(last_run_duration,6),2) +':' + left(right(last_run_duration,4),2) +':' + right(last_run_duration,2) as char (8))
	end as 'LastRunDuration'
	,last_run_date as LastRunDate
	,last_run_time as LastRunTime
from 
	msdb.dbo.sysjobsteps a
right outer join 
	msdb..sysjobs b 
on 
	a.job_id = b.job_id;

insert into ##ServerJobHistory
select distinct
	InstanceId
	,ServerName
	,ServerJobName
	,StepName
	,ErrorMessageId
	,ErrorSeverityLevel
	,ErrorMessage
	,RunStatus
	,RunDate
	,RunTime
	,RunDuration 
	,RetriesAttempted
from
(
	select
		a.instance_id as InstanceId
		,@@servername as ServerName
		,b.name as ServerJobName
		,step_name as StepName
		,sql_message_id as ErrorMessageId
		,sql_severity as ErrorSeverityLevel
		, message as ErrorMessage
		,run_status as RunStatus
		,run_date as RunDate
		,case len(run_time)
			when 1 then cast('00:00:0' + cast(run_time as char) as char (8))
			when 2 then cast('00:00:' + cast(run_time as char) as char (8))
			when 3 then cast('00:0'	+ left(right(run_time,3),1)	+':' + right( run_time,2) as char (8))
			when 4 then cast('00:' 	+ left(right( run_time,4),2)  +':' + right(run_time,2) as char (8))
			when 5 then cast('0' + left(right( run_time,5),1) +':' + left(right(run_time,4),2) +':' + right(run_time,2) as char (8))
			when 6 then cast(left(right( run_time,6),2) +':' + left(right(run_time,4),2) +':' + right(run_time,2) as char (8))
			else
			'00:00:00'
		end as 'RunTime'
	
		,case len(run_duration)
			when 1 then cast('00:00:0' + cast(run_duration as char) as char (8))
			when 2 then cast('00:00:' + cast(run_duration as char) as char (8))
			when 3 then cast('00:0'	+ left(right(run_duration,3),1)	+':' + right( run_duration,2) as char (8))
			when 4 then cast('00:' 	+ left(right( run_duration,4),2)  +':' + right( run_duration,2) as char (8))
			when 5 then cast('0' + left(right( run_duration,5),1) +':' + left(right( run_duration,4),2) +':' + right( run_duration,2) as char (8))
			when 6 then cast(left(right( run_duration,6),2) +':' + left(right( run_duration,4),2) +':' + right( run_duration,2) as char (8))
			else
			'00:00:00'
		end as 'RunDuration'
		,retries_attempted as RetriesAttempted
	from 
		msdb.dbo.sysjobhistory a
	right outer join 
		msdb..sysjobs b 
	on 
		a.job_id = b.job_id
) a
Where
	a.StepName is not null
	and
	a.StepName not like '(Job outcome)';

Select * from ##ServerJobs as ServerJobs;
Select * from ##ServerJobschedules as ServerJobschedules;
Select * from ##ServerJobsteps ServerJobsteps;
select * from ##ServerJobHistory ServerJobHistory;