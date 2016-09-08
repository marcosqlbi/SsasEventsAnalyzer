CREATE TABLE [dbo].[Process] (
	[ID_Process]				[int] IDENTITY(1,1) NOT NULL,
	[ProcessString]				[varchar](max)		NOT NULL,
	[NK_ProcessChecksum]		[varbinary](8)		NOT NULL,
	
	[Created]					DATETIME2(3)		NOT NULL,
	[LastUpdated]				DATETIME2(3)		NOT NULL
		
	,CONSTRAINT [PK_dbo_Process] PRIMARY KEY CLUSTERED ([ID_Process] ASC)
	,CONSTRAINT UNQ_dbo_ProcessChecksum UNIQUE ([NK_ProcessChecksum])

);
GO

ALTER TABLE [dbo].[Process]
	ADD CONSTRAINT DF_dbo_Process_Created
	DEFAULT(GETDATE()) FOR [Created]
;
GO

ALTER TABLE [dbo].[Process]
	ADD CONSTRAINT DF_dbo_Process_LastUpdated
	DEFAULT(GETDATE()) FOR [LastUpdated]
;
GO
