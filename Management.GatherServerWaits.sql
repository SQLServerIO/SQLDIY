IF NOT EXISTS (SELECT *
               FROM   dbo.sysobjects
               WHERE  id = Object_id(N'[dbo].[ServerWaits]')
                      AND Objectproperty(id, N'IsUserTable') = 1)
  BEGIN
      CREATE TABLE [dbo].[ServerWaits]
        (
           [RecordID]                             [INT] IDENTITY(1, 1) NOT NULL,
           [ServerName]                           [VARCHAR] (255) NOT NULL,
           [WaitType]                             [NVARCHAR](60),
           [WaitingTasksCount]                    [BIGINT],
           [WaitingTasksCountFromStart]           [BIGINT],
           [WaitTimeInMilliseconds]               [BIGINT],
           [WaitTimeInMillisecondsFromStart]      [BIGINT],
           [MaximumWaitTimeMilliseconds]          [BIGINT],
           [MaximumWaitTimeMillisecondsFromStart] [BIGINT],
           [SignalWaitTimeMilliseconds]           [BIGINT],
           [SignalWaitTimeMillisecondsFromStart]  [BIGINT],
           [RecordedDateTime]                     [DATETIME] NULL,
           [IntervalInMilliseconds]               [BIGINT] NULL,
           [FirstMeasureFromStart]                [BIT] NULL
        )
  END
ELSE
  BEGIN
      PRINT 'Table ServerWaits already exists'
  END

IF NOT EXISTS (SELECT *
               FROM   dbo.sysobjects
               WHERE  id = Object_id(N'[dbo].[ServerWaitsHistory]')
                      AND Objectproperty(id, N'IsUserTable') = 1)
  BEGIN
      CREATE TABLE [dbo].[ServerWaitsHistory]
        (
           [RecordID]                             [INT] NOT NULL,
           [ServerName]                           [VARCHAR] (255) NOT NULL,
           [WaitType]                             [NVARCHAR](60),
           [WaitingTasksCount]                    [BIGINT],
           [WaitingTasksCountFromStart]           [BIGINT],
           [WaitTimeInMilliseconds]               [BIGINT],
           [WaitTimeInMillisecondsFromStart]      [BIGINT],
           [MaximumWaitTimeMilliseconds]          [BIGINT],
           [MaximumWaitTimeMillisecondsFromStart] [BIGINT],
           [SignalWaitTimeMilliseconds]           [BIGINT],
           [SignalWaitTimeMillisecondsFromStart]  [BIGINT],
           [RecordedDateTime]                     [DATETIME] NULL,
           [IntervalInMilliseconds]               [BIGINT] NULL,
           [FirstMeasureFromStart]                [BIT] NULL
        )
  END
ELSE
  BEGIN
      PRINT 'Table ServerWaitsHistory already exists'
  END

IF EXISTS (SELECT *
           FROM   dbo.sysobjects
           WHERE  id = Object_id('[dbo].[GatherServerWaits]')
                  AND Objectproperty(id, 'isprocedure') = 1)
  BEGIN
      DROP PROCEDURE gatherserverwaits
  END

GO

/*
   Uses snapshot of waits to determine what's waiting longest
   Some help with wait_type can be found at
   http://msdn.microsoft.com/en-us/library/ms179984(v=SQL.105).aspx
   http://support.microsoft.com/default.aspx?scid=kb;en-us;Q244455
   Best reference found to date at
   http://blogs.msdn.com/b/jimmymay/archive/2009/04/26/wait-stats-introductory-references.aspx
   http://support.microsoft.com/kb/822101
   http://blogs.msdn.com/b/psssql/archive/2009/11/03/the-sql-server-wait-type-repository.aspx
   http://sqldev.net/misc/WaitTypes.htm
*/
CREATE PROCEDURE GatherServerWaits (@Duration          DATETIME = '01:00:00',
                                    @IntervalInSeconds INT = 120,
                                    @showall           BIGINT = 1)
AS
  SET nocount ON

  DECLARE @StopTime                 DATETIME,
          @LastRecordedDateTime     DATETIME,
          @CurrentDateTime          DATETIME,
          @ErrorNumber              INT,
          @NumberOfRows             INT,
          @ErrorMessageText         NVARCHAR(4000),
          @CurrentServerName        VARCHAR(255),
          @DifferenceInMilliSeconds BIGINT

  SELECT @CurrentServerName = CAST(Serverproperty('servername') AS VARCHAR(255))

  SET @DifferenceInMilliSeconds = Datediff(ms, CONVERT(DATETIME, '00:00:00', 8),
                                  @Duration)

  SELECT @StopTime = Dateadd(ms, @DifferenceInMilliSeconds, Getdate())

  IF EXISTS (SELECT 1
             FROM   dbo.serverwaits)
    BEGIN
        IF EXISTS (SELECT *
                   FROM   dbo.sysobjects
                   WHERE  id = Object_id(N'[dbo].[ServerWaits]')
                          AND Objectproperty(id, N'IsTable') = 1)
          BEGIN
              INSERT INTO dbo.serverwaitshistory
              SELECT *
              FROM   serverwaits;

              TRUNCATE TABLE dbo.serverwaits;
          END
    END

  WHILE Getdate() <= @StopTime
    BEGIN
        SELECT @LastRecordedDateTime = @CurrentDateTime

        SELECT @CurrentDateTime = Getdate()

        INSERT INTO dbo.serverwaits
                    (servername,
                     waittype,
                     waitingtaskscount,
                     waitingtaskscountfromstart,
                     waittimeinmilliseconds,
                     waittimeinmillisecondsfromstart,
                     maximumwaittimemilliseconds,
                     maximumwaittimemillisecondsfromstart,
                     signalwaittimemilliseconds,
                     signalwaittimemillisecondsfromstart,
                     recordeddatetime,
                     intervalinmilliseconds,
                     firstmeasurefromstart)
        SELECT @CurrentServerName,
               ws.wait_type,
               ws.waiting_tasks_count - mws.WaitingTasksCountFromStart			AS               waitingtaskscount,
               ws.waiting_tasks_count											AS               signalwaittimemillisecondsfromstart,
               ws.wait_time_ms - mws.WaitTimeInMillisecondsFromStart			AS               waittimeinmilliseconds,
               ws.wait_time_ms													AS               signalwaittimemillisecondsfromstart,
               ws.max_wait_time_ms - mws.MaximumWaitTimeMillisecondsFromStart	AS               maximumwaittimemilliseconds,
               ws.max_wait_time_ms												AS               signalwaittimemillisecondsfromstart,
               ws.signal_wait_time_ms - mws.SignalWaitTimeMillisecondsFromStart AS               signalwaittimemilliseconds,
               ws.signal_wait_time_ms											AS               signalwaittimemillisecondsfromstart,
               @CurrentDateTime,
               CASE
                 WHEN @LastRecordedDateTime IS NULL THEN NULL
                 ELSE Datediff(ms, mws.recordeddatetime, @CurrentDateTime)
               END																AS               intervalinmilliseconds,
               CASE
                 WHEN @LastRecordedDateTime IS NULL THEN 1
                 ELSE 0
               END																AS               firstmeasurefromstart
        FROM   sys.dm_os_wait_stats ws
               LEFT OUTER JOIN dbo.ServerWaits mws
                 ON ws.wait_type = mws.WaitType
        WHERE  ( @LastRecordedDateTime IS NULL
                  OR mws.RecordedDateTime = @LastRecordedDateTime )
--               AND ( ws.wait_time_ms - mws.waittimeinmilliseconds ) >= @showall

        SELECT @ErrorNumber = @@ERROR,
               @NumberOfRows = @@ROWCOUNT

        IF @ErrorNumber != 0
          BEGIN
              SET @ErrorMessageText = 'Error ' + CONVERT(VARCHAR(10),
                                                 @ErrorNumber
                                                 )
                                      +
                                      ' failed to insert server waits data!'

              RAISERROR (@ErrorMessageText,
                         16,
                         1) WITH LOG

              RETURN @ErrorNumber
          END

        WAITFOR delay @IntervalInSeconds
    END
GO 