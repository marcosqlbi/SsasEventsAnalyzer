CREATE TABLE [log].[Error]
(
	 [ID_Log]			INT IDENTITY(1,1)	NOT NULL 
	,[ErrorDatetime]	DATETIME2(3)		NOT NULL
	,[ErrorNumber]		INT					NULL	
	,[ErrorSeverity]	INT					NULL
	,[ErrorState]		INT					NULL
	,[ErrorProcedure]	VARCHAR(128)		NULL
	,[ErrorLine]		INT					NULL
	,[ErrorMessage]		VARCHAR(4000)		NULL

	,CONSTRAINT PK_log_Error PRIMARY KEY CLUSTERED ([ID_Log])
)
GO

ALTER TABLE [log].[Error]
	ADD CONSTRAINT DF_log_Error_ErrorDatetime
	DEFAULT(GETDATE()) FOR [ErrorDatetime]
;
GO