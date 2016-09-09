/* step 1: move from log dir to processing dir 
	service account for SQL Agent will need access to 
	specified directories in order to move files around
*/

/* step 2: process files
	service account for SQL Server DB engine will need 
	access to  specified directories in order to read files 

		SPROC: dbo.LoadxEventTraceProcessData
		SPROC: dbo.LoadxEventTraceQueryData

		future state: query xEventFileAuditLog for unprocessed files (process in order if batching)
*/

/* step 3: archive files 
	service account for SQL Agent will need access to 
	specified directories in order to move files around
*/


DECLARE @Process_xEventFiles_JobName VARCHAR(128) = N'$(Process_xEventFiles_JobName)';
DECLARE @Process_xEventFiles_JobId BINARY(16);
DECLARE @Process_xEventFiles_cmd VARCHAR(2048);

SELECT	@Process_xEventFiles_JobId = job_id
FROM	msdb.dbo.sysjobs
WHERE	name = @Process_xEventFiles_JobName
;

IF (@Process_xEventFiles_JobId IS NOT NULL)
BEGIN;
	PRINT N'Delete Existing Job: $(Process_xEventFiles_JobName)';
	EXEC msdb.dbo.sp_delete_job 
		@job_id=@Process_xEventFiles_JobId, 
		@delete_unused_schedule=1
	;
END
;

/* Create Job */
PRINT N'Creating Job: $(Process_xEventFiles_JobName)';
SET @Process_xEventFiles_JobId = NULL;
EXEC msdb.dbo.sp_add_job 
		@job_name=@Process_xEventFiles_JobName, 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Processes xEvent Files.', 
		--@owner_login_name=N'sa', 
		@job_id = @Process_xEventFiles_JobId OUTPUT
;
/* Build TraceCollection cmdExec command */
PRINT N'Building : (Step01) Move xEvent Files from log_dir to processing_dir';
SET @Process_xEventFiles_cmd = N'';
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'$(powershell_exe_path) ' 
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'"'
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'$(powershell_script_dir)' 
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'Move-xEventTraceFiles.ps1 '
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'-xevent_src_trace_dir ''$(xevent_trace_dir)'' '
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'-xevent_tgt_trace_dir ''$(xevent_trace_processing_dir)'' '
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'-ssas_event_analyzer_server ''$(ssas_events_analyzer_server)'' '
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'-ssas_event_analyzer_db ''$(DatabaseName)'' '
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'-archive_flag 0 '
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'"'

/* Create Job Steps */
PRINT N'Creating Job Step: (Step01) Move xEvent Files from log_dir to processing_dir';
EXEC msdb.dbo.sp_add_jobstep 
		@job_id=@Process_xEventFiles_JobId, 
		@step_name=N'(Step01) Move xEvent Files from log_dir to processing_dir', 
		@step_id=1, 
		@cmdexec_success_code=0,
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, 
		@subsystem=N'CmdExec', 
		@command=@Process_xEventFiles_cmd,
		@flags=0
;


PRINT N'Building : (Step02) Load xEventProcess Trace Files';
SET @Process_xEventFiles_cmd = N'';
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'DECLARE @src_path VARCHAR(2048) = N''$(xevent_trace_processing_dir)'';' + CHAR(13) + CHAR(10);
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'' + CHAR(13) + CHAR(10);
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'/* Process ProcessTrace Files */' + CHAR(13) + CHAR(10);
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'EXEC stg.LoadxEventTraceProcessData @path_to_trace_file = @src_path; ' + CHAR(13) + CHAR(10);
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'' + CHAR(13) + CHAR(10);
/* Create Job Steps */
PRINT N'Creating Job Step: (Step02) Load xEventProcess Trace Files';
EXEC msdb.dbo.sp_add_jobstep 
		@job_id=@Process_xEventFiles_JobId, 
		@step_name=N'(Step02) Load xEventProcess Trace Files', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, 
		@subsystem=N'TSQL', 
		@command=@Process_xEventFiles_cmd, 
		@database_name='$(DatabaseName)',
		@flags=0
;

PRINT N'Building : (Step03) Load xEventQuery Trace Files';
SET @Process_xEventFiles_cmd = N'';
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'DECLARE @src_path VARCHAR(2048) = N''$(xevent_trace_processing_dir)'';' + CHAR(13) + CHAR(10);
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'' + CHAR(13) + CHAR(10);
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'/* Process QueryTrace Files */' + CHAR(13) + CHAR(10);
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'EXEC stg.LoadxEventTraceQueryData @path_to_trace_file = @src_path; ' + CHAR(13) + CHAR(10);
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'' + CHAR(13) + CHAR(10);

/* Create Job Steps */
PRINT N'Creating Job Step: (Step03) Load xEventQuery Trace Files';
EXEC msdb.dbo.sp_add_jobstep 
		@job_id=@Process_xEventFiles_JobId, 
		@step_name=N'(Step03) Load xEventQuery Trace Files', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, 
		@subsystem=N'TSQL', 
		@command=@Process_xEventFiles_cmd, 
		@database_name='$(DatabaseName)',
		@flags=0
;
PRINT N'Building : (Step04) Archive Trace Files';
SET @Process_xEventFiles_cmd = N'';
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'$(powershell_exe_path) ' 
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'"'
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'$(powershell_script_dir)' 
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'Move-xEventTraceFiles.ps1 '
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'-xevent_src_trace_dir ''$(xevent_trace_processing_dir)'' '
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'-xevent_tgt_trace_dir ''$(xevent_trace_archive_dir)'' '
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'-ssas_event_analyzer_server ''$(ssas_events_analyzer_server)'' '
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'-ssas_event_analyzer_db ''$(DatabaseName)'' '
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'-archive_flag 1 '
SET @Process_xEventFiles_cmd = @Process_xEventFiles_cmd + N'"'

/* Create Job Steps */
PRINT N'Creating Job Step: (Step04) Archive Trace Files';
EXEC msdb.dbo.sp_add_jobstep 
		@job_id=@Process_xEventFiles_JobId, 
		@step_name=N'(Step04) Archive Trace Files', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_fail_action=2, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, 
		@subsystem=N'CmdExec', 
		@command=@Process_xEventFiles_cmd,
		@flags=0
;






EXEC msdb.dbo.sp_update_job 
		@job_id = @Process_xEventFiles_JobId, 
		@start_step_id = 1
;
EXEC msdb.dbo.sp_add_jobserver 
		@job_id = @Process_xEventFiles_JobId, 
		@server_name = N'(local)'
;