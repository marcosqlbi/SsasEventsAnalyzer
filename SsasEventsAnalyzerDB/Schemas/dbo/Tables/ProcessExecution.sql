CREATE TABLE [dbo].[ProcessExecution](
	[ID_ProcessExecution]		[int] IDENTITY(1,1) NOT NULL,
	[ID_Process]				[int]				NOT NULL,
	[ProcessStartDate]			[date]				NOT NULL,
	[ProcessStartTime]			[time]				NOT NULL,
	[ProcessStartDT]			[datetimeoffset]	NOT NULL,

	[Duration]					[time]				NULL,
	[CPUTime]					[time]				NULL,
	[Duration_ms]				[int]				NULL,
	[CPUTime_ms]				[int]				NULL,
	[Database]					[varchar](255)		NULL,
    [Domain]					[varchar](255)		NULL,
    [User]						[varchar](255)		NULL,
    [Server]					[varchar](255)		NULL,
    [Success]					[int]				NULL,
    [Severity]					[int]				NULL,
	
	[Created]					DATETIME2(3)		NOT NULL,
	[LastUpdated]				DATETIME2(3)		NOT NULL
	
	,CONSTRAINT [PK_ssastab_ProcessingExecution] PRIMARY KEY CLUSTERED ([ID_ProcessExecution] ASC)
	,CONSTRAINT FK_dbo_ProcessExecution__ProcessId
		FOREIGN KEY ([ID_Process])
		REFERENCES [dbo].[Process] ([ID_Process])
)
;
GO

ALTER TABLE [dbo].[ProcessExecution]
	ADD CONSTRAINT DF_dbo_ProcessExecution_Created
	DEFAULT(GETDATE()) FOR [Created]
;
GO

ALTER TABLE [dbo].[ProcessExecution]
	ADD CONSTRAINT DF_dbo_ProcessExecution_LastUpdated
	DEFAULT(GETDATE()) FOR [LastUpdated]
;
GO