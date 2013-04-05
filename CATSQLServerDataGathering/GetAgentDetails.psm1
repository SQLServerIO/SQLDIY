<#
.SYNOPSIS
    Pulls details about all SQL Server Agent Jobs
.DESCRIPTION
    A detailed description of the module.
#>

function GetAgentDetails {
    [CmdletBinding()]
    param(
		[Parameter(Position=0, Mandatory=$true)]
		[string]$rserver,
		[Parameter(Position=2, Mandatory=$true)]		
		[string]$rdatabase,
		[Parameter(Position=3, Mandatory=$false)]		
		[string]$server
    )
    begin {
    }
    process {
        Import-Module C:\projects\source\OpenSource\SQLDIY\CATSQLServerDataGathering\Out-DataTable.psm1
        Import-Module C:\projects\source\OpenSource\SQLDIY\CATSQLServerDataGathering\Write-DataTable.psm1
        Import-Module C:\projects\source\OpenSource\SQLDIY\CATSQLServerDataGathering\Agent\Agent.psd1

        [datetime]$compdate = get-date "1/1/0001 12:00:00 AM" -Format "yyyy-MM-dd hh:mm:ss"
        [datetime]$rdate =get-date "1/1/1900 12:00:00" -Format "yyyy-MM-dd hh:mm:ss"

        $dt = $null
        $dt = Get-AgentJob -jobserver $server | 
        select @{n='ServerName';e={$server}}, Category, CategoryType, CurrentRunRetryAttempt, CurrentRunStatus, CurrentRunStep, 
            @{n='DateCreated';e={if((get-date $compdate) -lt (get-date  $_.DateCreated)){get-date $_.DateCreated} else{get-date $rdate}}},
            @{n='DateLastModified';e={if((get-date $compdate) -lt (get-date  $_.DateLastModified)){get-date $_.DateLastModified} else{get-date $rdate}}}, 
            DeleteLevel, Description, EmailLevel, EventLogLevel, HasSchedule, HasServer, HasStep, IsEnabled, JobID, JobType, 
            @{n='LastRunDate';e={if((get-date $compdate) -lt (get-date $_.LastRunDate)){get-date $_.LastRunDate} else{get-date $rdate}}},   
            LastRunOutcome, NetSendLevel, 
            @{n='NextRunDate';e={if((get-date $compdate) -lt (get-date $_.NextRunDate)){get-date $_.NextRunDate} else{get-date $rdate}}},   
            NextRunScheduleID, OperatorToEmail, OperatorToNetSend, OperatorToPage, OriginatingServer, OwnerLoginName, PageLevel, StartStepID, 
            VersionNumber, Name, CategoryID, State ,@{n='SampleDate';e={get-date -Format "yyyy-MM-dd hh:mm:ss"}} | Out-DataTable
        Write-DataTable -ServerInstance $rserver -Database $rdatabase -TableName "AgentJobs" -Data $dt


        $dt = $null
        $dt = Get-AgentJob $rserver | Get-AgentJobSchedule | 
        Select @{n='ServerName';e={$server}}, ActiveEndDate,ActiveEndTimeOfDay,ActiveStartDate,ActiveStartTimeOfDay,DateCreated,
               FrequencyInterval,FrequencyRecurrenceFactor,FrequencyRelativeIntervals,FrequencySubDayInterval,FrequencySubDayTypes,
               FrequencyTypes,IsEnabled,JobCount,ScheduleUid,ID,Name ,@{n='SampleDate';e={get-date -Format "yyyy-MM-dd hh:mm:ss"}} | Out-DataTable
        #Add-SqlTable -ServerInstance $rserver -Database $rdatabase -TableName AgentJobSchedules -DataTable $dt
        Write-DataTable -ServerInstance $rserver -Database $rdatabase -TableName "AgentJobSchedules" -Data $dt

        $dt = $null
        $dt = Get-AgentJob $rserver | Get-AgentJobStep |
        select @{n='ServerName';e={$server}}, Command, CommandExecutionSuccessCode, DatabaseName, DatabaseUserName, ID, JobStepFlags, 
            @{n='LastRunDate';e={if((get-date $compdate) -lt (get-date $_.LastRunDate)){get-date $_.LastRunDate} else{get-date $rdate}}},   
            LastRunDuration,LastRunOutcome,LastRunRetries,OnFailAction,OnFailStep,OnSuccessAction,OnSuccessStep,OSRunPriority,OutputFileName,
            ProxyName,RetryAttempts,RetryInterval,Server,SubSystem,Name ,@{n='SampleDate';e={get-date -Format "yyyy-MM-dd hh:mm:ss"}} | Out-DataTable
        Write-DataTable -ServerInstance $rserver -Database $rdatabase -TableName "AgentJobSteps" -Data $dt

        $dt = $null
        $dt = Get-AgentSchedule -jobserver $server | 
        select ActiveEndDate,ActiveEndTimeOfDay,ActiveStartDate,ActiveStartTimeOfDay,DateCreated,FrequencyInterval,FrequencyRecurrenceFactor,
            FrequencyRelativeIntervals,FrequencySubDayInterval,FrequencySubDayTypes,FrequencyTypes,IsEnabled,JobCount,ScheduleUid,ID,
            Name,@{n='SampleDate';e={get-date -Format "yyyy-MM-dd hh:mm:ss"}} | Out-DataTable
        Write-DataTable -ServerInstance $rserver -Database $rdatabase -TableName "AgentSchedules" -Data $dt

        $dt = $null
        $dt = Get-AgentAlertCategory -jobserver $server | select ID,Name,@{n='SampleDate';e={get-date -Format "yyyy-MM-dd hh:mm:ss"}} | Out-DataTable
        Write-DataTable -ServerInstance $rserver -Database $rdatabase -TableName "AgentAlertCategories" -Data $dt

        $dt = $null
        $dt = Get-AgentOperatorCategory -jobserver $server | select ID,Name,@{n='SampleDate';e={get-date -Format "yyyy-MM-dd hh:mm:ss"}} | Out-DataTable
        Write-DataTable -ServerInstance $rserver -Database $rdatabase -TableName "AgentOperatorCategories" -Data $dt

#not implemented yet
        #Get-AgentAlert -jobserver $server
        #Get-AgentJobHistory -jobserver $server
        #Get-AgentOperator -jobserver $server
        #Get-AgentProxyAccount -jobserver $server
        #Get-AgentTargetServer -jobserver $server
        #Get-AgentTargetServerGroup -jobserver $server
    }
    end {
    }
}
Export-ModuleMember -Function GetAgentDetails