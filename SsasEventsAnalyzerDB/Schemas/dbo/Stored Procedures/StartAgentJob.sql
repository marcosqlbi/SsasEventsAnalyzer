CREATE PROCEDURE [dbo].[StartAgentJob]
	 @job_name	VARCHAR(128)
	,@wait		BIT = 0
AS
BEGIN;

	SET NOCOUNT ON;
	BEGIN TRY

		DECLARE @job_id UNIQUEIDENTIFIER;
		DECLARE @prev_max_id INT;
		DECLARE @curr_max_id INT;
		DECLARE @cmd VARCHAR(4000);
		DECLARE @msg VARCHAR(1024);

		SET	@job_id = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = @job_name);
		
		/* Check that job exists */
		IF @job_id IS NULL
		BEGIN;
			/* Raise Error */
			SET @msg = 'StartAgentJob: no job by that name (@job_name = ' + @job_name + ')';
			RAISERROR(@msg, 16, 0)
		END
		;

		/* Check if job is already running */
		IF EXISTS(     
			SELECT	TOP 1 'Exists'
			FROM	msdb.dbo.sysjobs_view job  
					INNER JOIN msdb.dbo.sysjobactivity activity 
						ON	job.job_id = activity.job_id 
			WHERE	activity.run_Requested_date IS NOT NULL AND 
					activity.stop_execution_date IS NULL AND 
					job.name = @job_name 
		) 
		BEGIN;
			/* Raise Error */
			SET @msg = 'StartAgentJob: job (@job_name = ' + @job_name + ') is already running';
			RAISERROR(@msg, 16, 0)
		END
		;
		
		/* Start Job */
		EXEC msdb.dbo.sp_start_job @job_name = @job_name;
		WAITFOR DELAY '0:0:01'; -- wait for job to start

		IF @wait = CONVERT(BIT,1)
		BEGIN;
				
			/* Get InstanceId of Last Run */
			SET @prev_max_id = (
				SELECT	ISNULL(MAX(instance_id),-1) 
				FROM	msdb.dbo.sysjobhistory 
				WHERE	job_id = @job_id AND 
						step_id = 0
			);
			SET @curr_max_id = @prev_max_id;

			/* wait for job to finish */
			WHILE (@curr_max_id <= @prev_max_id)
			BEGIN;

				WAITFOR DELAY '00:00:01';

				/* Get InstanceId of Last Run */
				SET @curr_max_id = (
					SELECT	ISNULL(MAX(instance_id),-1) 
					FROM	msdb.dbo.sysjobhistory 
					WHERE	job_id = @job_id AND 
							step_id = 0
				);

			END
			;
		END
		;

	END TRY
	BEGIN CATCH
	
		/* capture error variables */
		DECLARE  @lErrorNumber INT = ERROR_NUMBER()
				,@lErrorSeverity INT = ERROR_SEVERITY()
				,@lErrorState INT = ERROR_STATE()
				,@lErrorProcedure VARCHAR(128) = ERROR_PROCEDURE()
				,@lErrorLine INT = ERROR_LINE()
				,@lErrorMessage VARCHAR(4000) = ERROR_MESSAGE()
		;
		/* log error */
		EXEC [log].[LogError]
				 @ErrorNumber = @lErrorNumber
				,@ErrorSeverity = @lErrorSeverity
				,@ErrorState = @lErrorState
				,@ErrorProcedure = @lErrorProcedure
				,@ErrorLine = @lErrorLine
				,@ErrorMessage = @lErrorMessage
		;
		/* re-throw exception to parent */
		THROW;

	END CATCH

END
;