CREATE TABLE [log].[xEventFileAuditLog] (
	[ID_xEventFileAuditLog]			INT IDENTITY(1,1)	NOT NULL,
	[xEventFileName]				NVARCHAR(260)		NOT NULL,

	[Moved_DT]						DATETIME2(3)		NOT NULL,
	[Processed_DT]					DATETIME2(3)		NULL,

	[Created]						DATETIME2(3)		NOT NULL,
	[LastUpdated]					DATETIME2(3)		NOT NULL

	,CONSTRAINT PK_log_xEventFileAuditLog PRIMARY KEY NONCLUSTERED ([xEventFileName])
)
;
GO

CREATE CLUSTERED INDEX CIDX_log_xEventFileAuditLog 
	ON	[log].[xEventFileAuditLog] ([ID_xEventFileAuditLog])
;
GO

ALTER TABLE [log].[xEventFileAuditLog]
	ADD CONSTRAINT DF_log_xEventFileAuditLog_Moved
	DEFAULT(GETDATE()) FOR [Moved_DT]
;
GO

ALTER TABLE [log].[xEventFileAuditLog]
	ADD CONSTRAINT DF_log_xEventFileAuditLog_Created
	DEFAULT(GETDATE()) FOR [Created]
;
GO

ALTER TABLE [log].[xEventFileAuditLog]
	ADD CONSTRAINT DF_log_xEventFileAuditLog_LastUpdated
	DEFAULT(GETDATE()) FOR [LastUpdated]
;
GO
