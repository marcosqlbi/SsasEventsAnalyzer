
DECLARE @StopProcessTrace_JobName VARCHAR(128) = N'$(StopProcessTrace_JobName)';
DECLARE @StopProcessTrace_JobId BINARY(16);
DECLARE @StopProcessTrace_cmd VARCHAR(2048);

SELECT	@StopProcessTrace_JobId = job_id
FROM	msdb.dbo.sysjobs
WHERE	name = @StopProcessTrace_JobName
;

IF (@StopProcessTrace_JobId IS NOT NULL)
BEGIN;
	PRINT N'Delete Existing Job: $(StopProcessTrace_JobName)';
	EXEC msdb.dbo.sp_delete_job 
		@job_id=@StopProcessTrace_JobId, 
		@delete_unused_schedule=1
	;
END
;



/* Create Job */
PRINT N'Creating Job: $(StopProcessTrace_JobName)';
SET @StopProcessTrace_JobId = NULL;
EXEC msdb.dbo.sp_add_job 
		@job_name=@StopProcessTrace_JobName, 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Stops SSAS xEvent trace collecting process data.', 
		--@owner_login_name=N'sa', 
		@job_id = @StopProcessTrace_JobId OUTPUT
;
/* Build TraceCollection cmdExec command */
PRINT N'Building : (Step01) $(StopProcessTrace_JobName)';
SET @StopProcessTrace_cmd = N'';
SET @StopProcessTrace_cmd = @StopProcessTrace_cmd + N'<Delete xmlns="http://schemas.microsoft.com/analysisservices/2003/engine"> ';
SET @StopProcessTrace_cmd = @StopProcessTrace_cmd + N'  <Object> ';
SET @StopProcessTrace_cmd = @StopProcessTrace_cmd + N'    <TraceID>TraceProcess</TraceID> ';
SET @StopProcessTrace_cmd = @StopProcessTrace_cmd + N'  </Object> ';
SET @StopProcessTrace_cmd = @StopProcessTrace_cmd + N'</Delete> ';

/* Create Job Steps */
PRINT N'Creating Job Step: (Step01) $(StopProcessTrace_JobName)';
EXEC msdb.dbo.sp_add_jobstep 
		@job_id=@StopProcessTrace_JobId, 
		@step_name=N'(Step01) $(StopProcessTrace_JobName)', 
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
		@command=@StopProcessTrace_cmd,
		@server=N'$(ssas_instance)',  
		@flags=0
;
EXEC msdb.dbo.sp_update_job 
		@job_id = @StopProcessTrace_JobId, 
		@start_step_id = 1
;
EXEC msdb.dbo.sp_add_jobserver 
		@job_id = @StopProcessTrace_JobId, 
		@server_name = N'(local)'
;