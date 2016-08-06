CREATE TABLE [dbo].[QueryExecution](
	[ID_QueryExecution]			[int]				IDENTITY(1,1) NOT NULL,
	[ID_Query]					[int]				NOT NULL,
	[QueryStartDate]			[date]				NOT NULL,
	[QueryStartTime]			[time]				NOT NULL,
	[QueryStartDT]				[datetimeoffset]	NOT NULL,

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
	
	[Created]					DATETIME2(3)		NOT NULL
		CONSTRAINT DF_dbo_QueryExecution_Created DEFAULT(GETDATE()),
	[LastUpdated]				DATETIME2(3)		NOT NULL
		CONSTRAINT DF_dbo_QueryExecution_Updated DEFAULT(GETDATE())
		
	,CONSTRAINT [PK_dbo_QueryExecution] PRIMARY KEY CLUSTERED ([ID_QueryExecution] ASC)

	,CONSTRAINT FK_dbo_QueryExecution__QueryId
		FOREIGN KEY ([ID_Query])
		REFERENCES [dbo].[Query] ([ID_Query])
)
;
GO

CREATE NONCLUSTERED INDEX NCIDX_dbo_QueryExecution__QueryID_StartTime
	ON	dbo.QueryExecution ([ID_Query], [QueryStartDT])
;