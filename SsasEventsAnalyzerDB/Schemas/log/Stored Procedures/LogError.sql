CREATE PROCEDURE [log].[LogError]
	 @ErrorNumber INT
	,@ErrorSeverity INT
	,@ErrorState INT
	,@ErrorProcedure VARCHAR(128)
	,@ErrorLine INT
	,@ErrorMessage VARCHAR(4000)
AS
BEGIN;

	SET NOCOUNT ON;

	INSERT INTO [log].[Error] (
				 [ErrorNumber]
				,[ErrorSeverity]
				,[ErrorState]
				,[ErrorProcedure]
				,[ErrorLine]
				,[ErrorMessage]
		)
		SELECT	 [ErrorNumber] = @ErrorNumber
				,[ErrorSeverity] = @ErrorSeverity
				,[ErrorState] = @ErrorState
				,[ErrorProcedure] = @ErrorProcedure
				,[ErrorLine] = @ErrorLine
				,[ErrorMessage] = @ErrorMessage
	;

END
;