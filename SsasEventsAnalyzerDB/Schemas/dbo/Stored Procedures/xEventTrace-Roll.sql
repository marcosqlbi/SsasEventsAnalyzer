CREATE PROCEDURE [dbo].[xEventTrace-Roll]
	@xevent_trace_type	VARCHAR(128)
AS
BEGIN;

	SET NOCOUNT ON;
	BEGIN TRY
	
		DECLARE @msg VARCHAR(1024);
		DECLARE @stop_job_name VARCHAR(128);
		DECLARE @start_job_name VARCHAR(128);

		/* validate parameter: xevent_trace_type */
		IF( @xevent_trace_type NOT IN ('query','process') )
		BEGIN;
			/* Raise Error */
			SET @msg = 'xEventTrace-Roll: invalid trace type. Valid trace type values include  (query, process)';
			RAISERROR(@msg, 16, 0)
		END
		;

		/* set job name */
		IF( @xevent_trace_type = 'query' )
		BEGIN;
			SET @start_job_name = '$(StartQueryTrace_JobName)';
			SET @stop_job_name = '$(StopQueryTrace_JobName)';
		END
		;
		IF( @xevent_trace_type = 'process' )
		BEGIN;
			SET @start_job_name = '$(StartProcessTrace_JobName)';
			SET @stop_job_name = '$(StopProcessTrace_JobName)';
		END
		;
 
		/* Stop/Start job */
		EXEC [dbo].[StartAgentJob] @job_name = @stop_job_name;
		EXEC [dbo].[StartAgentJob] @job_name = @start_job_name;

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