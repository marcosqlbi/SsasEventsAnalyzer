
DECLARE @StartProcessTrace_JobName VARCHAR(128) = N'$(StartProcessTrace_JobName)';
DECLARE @StartProcessTrace_JobId BINARY(16);
DECLARE @StartProcessTrace_cmd VARCHAR(2048);

SELECT	@StartProcessTrace_JobId = job_id
FROM	msdb.dbo.sysjobs
WHERE	name = @StartProcessTrace_JobName
;

IF (@StartProcessTrace_JobId IS NOT NULL)
BEGIN;
	PRINT N'Delete Existing Job: $(StartProcessTrace_JobName)';
	EXEC msdb.dbo.sp_delete_job 
		@job_id=@StartProcessTrace_JobId, 
		@delete_unused_schedule=1
	;
END
;



/* Create Job */
PRINT N'Creating Job: $(StartProcessTrace_JobName)';
SET @StartProcessTrace_JobId = NULL;
EXEC msdb.dbo.sp_add_job 
		@job_name=@StartProcessTrace_JobName, 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Starts SSAS xEvent trace collecting process data.', 
		--@owner_login_name=N'sa', 
		@job_id = @StartProcessTrace_JobId OUTPUT
;
/* Build TraceCollection cmdExec command */
PRINT N'Building : (Step01) $(StartProcessTrace_JobName)';
SET @StartProcessTrace_cmd = N'';
SET @StartProcessTrace_cmd = @StartProcessTrace_cmd + N'<Create xmlns="http://schemas.microsoft.com/analysisservices/2003/engine"> ';
SET @StartProcessTrace_cmd = @StartProcessTrace_cmd + N'  <ObjectDefinition> ';
SET @StartProcessTrace_cmd = @StartProcessTrace_cmd + N'    <Trace> ';
SET @StartProcessTrace_cmd = @StartProcessTrace_cmd + N'      <AutoRestart>true</AutoRestart> ';
SET @StartProcessTrace_cmd = @StartProcessTrace_cmd + N'      <ID>TraceProcess</ID> ';
SET @StartProcessTrace_cmd = @StartProcessTrace_cmd + N'      <Name>TraceProcess</Name> ';
SET @StartProcessTrace_cmd = @StartProcessTrace_cmd + N'      <XEvent xmlns="http://schemas.microsoft.com/analysisservices/2011/engine/300/300"> ';
SET @StartProcessTrace_cmd = @StartProcessTrace_cmd + N'        <event_session name="TraceProcess" dispatchLatency="0" maxEventSize="0" maxMemory="4" memoryPartition="none" eventRetentionMode="AllowSingleEventLoss" trackCausality="true" xmlns="http://schemas.microsoft.com/analysisservices/2003/engine"> ';
SET @StartProcessTrace_cmd = @StartProcessTrace_cmd + N'          <event package="AS" name="CommandEnd" /> ';
SET @StartProcessTrace_cmd = @StartProcessTrace_cmd + N'          <event package="AS" name="ProgressReportEnd" /> ';
SET @StartProcessTrace_cmd = @StartProcessTrace_cmd + N'          <target package="package0" name="event_file"> ';
SET @StartProcessTrace_cmd = @StartProcessTrace_cmd + N'            <parameter name="filename" value="$(xevent_trace_dir)TraceQuery.xel" /> ';
SET @StartProcessTrace_cmd = @StartProcessTrace_cmd + N'            <parameter name="max_file_size" value="4096" /> ';
SET @StartProcessTrace_cmd = @StartProcessTrace_cmd + N'          </target> ';
SET @StartProcessTrace_cmd = @StartProcessTrace_cmd + N'        </event_session> ';
SET @StartProcessTrace_cmd = @StartProcessTrace_cmd + N'      </XEvent> ';
SET @StartProcessTrace_cmd = @StartProcessTrace_cmd + N'    </Trace> ';
SET @StartProcessTrace_cmd = @StartProcessTrace_cmd + N'  </ObjectDefinition> ';
SET @StartProcessTrace_cmd = @StartProcessTrace_cmd + N'</Create> ';

/* Create Job Steps */
PRINT N'Creating Job Step: (Step01) $(StartProcessTrace_JobName)';
EXEC msdb.dbo.sp_add_jobstep 
		@job_id=@StartProcessTrace_JobId, 
		@step_name=N'(Step01) $(StartProcessTrace_JobName)', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, 
		@subsystem=N'ANALYSISCOMMAND', 
		@command=@StartProcessTrace_cmd,
		@server=N'$(ssas_instance)',  
		@flags=0
;
EXEC msdb.dbo.sp_update_job 
		@job_id = @StartProcessTrace_JobId, 
		@start_step_id = 1
;
EXEC msdb.dbo.sp_add_jobserver 
		@job_id = @StartProcessTrace_JobId, 
		@server_name = N'(local)'
;