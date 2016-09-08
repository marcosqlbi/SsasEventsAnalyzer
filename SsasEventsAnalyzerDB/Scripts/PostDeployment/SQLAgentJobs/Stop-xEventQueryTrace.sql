
DECLARE @StopQueryTrace_JobName VARCHAR(128) = N'$(StopQueryTrace_JobName)';
DECLARE @StopQueryTrace_JobId BINARY(16);
DECLARE @StopQueryTrace_cmd VARCHAR(2048);

SELECT	@StopQueryTrace_JobId = job_id
FROM	msdb.dbo.sysjobs
WHERE	name = @StopQueryTrace_JobName
;

IF (@StopQueryTrace_JobId IS NOT NULL)
BEGIN;
	PRINT N'Delete Existing Job: $(StopQueryTrace_JobName)';
	EXEC msdb.dbo.sp_delete_job 
		@job_id=@StopQueryTrace_JobId, 
		@delete_unused_schedule=1
	;
END
;



/* Create Job */
PRINT N'Creating Job: $(StopQueryTrace_JobName)';
SET @StopQueryTrace_JobId = NULL;
EXEC msdb.dbo.sp_add_job 
		@job_name=@StopQueryTrace_JobName, 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Starts SSAS xEvent trace collecting query data.', 
		--@owner_login_name=N'sa', 
		@job_id = @StopQueryTrace_JobId OUTPUT
;
/* Build TraceCollection cmdExec command */
PRINT N'Building : (Step01) $(StopQueryTrace_JobName)';
SET @StopQueryTrace_cmd = N'';
SET @StopQueryTrace_cmd = @StopQueryTrace_cmd + N'<Delete xmlns="http://schemas.microsoft.com/analysisservices/2003/engine"> ';
SET @StopQueryTrace_cmd = @StopQueryTrace_cmd + N'  <Object> ';
SET @StopQueryTrace_cmd = @StopQueryTrace_cmd + N'    <TraceID>TraceQuery</TraceID> ';
SET @StopQueryTrace_cmd = @StopQueryTrace_cmd + N'  </Object> ';
SET @StopQueryTrace_cmd = @StopQueryTrace_cmd + N'</Delete> ';

/* Create Job Steps */
PRINT N'Creating Job Step: (Step01) $(StopQueryTrace_JobName)';
EXEC msdb.dbo.sp_add_jobstep 
		@job_id=@StopQueryTrace_JobId, 
		@step_name=N'(Step01) $(StopQueryTrace_JobName)', 
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
		@command=@StopQueryTrace_cmd,
		@server=N'$(ssas_instance)',  
		@flags=0
;
EXEC msdb.dbo.sp_update_job 
		@job_id = @StopQueryTrace_JobId, 
		@start_step_id = 1
;
EXEC msdb.dbo.sp_add_jobserver 
		@job_id = @StopQueryTrace_JobId, 
		@server_name = N'(local)'
;