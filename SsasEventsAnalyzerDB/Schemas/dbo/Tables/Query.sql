CREATE TABLE [dbo].[Query] (
	[ID_Query]				[int]				IDENTITY(1,1) NOT NULL,
	[QueryString]			[VARCHAR](max)		NOT NULL,
	[QueryType]				[VARCHAR](3)		NOT NULL,
	[NK_QueryChecksum]		[varbinary](8)		NOT NULL,
	
	[Created]				DATETIME2(3)		NOT NULL,
	[LastUpdated]			DATETIME2(3)		NOT NULL
		
	,CONSTRAINT [PK_dbo_Query] PRIMARY KEY CLUSTERED ([ID_Query] ASC)
	,CONSTRAINT UNQ_dbo_QueryChecksum UNIQUE ([NK_QueryChecksum])

)
;
GO

ALTER TABLE [dbo].[Query]
	ADD CONSTRAINT DF_dbo_Query_Created
	DEFAULT(GETDATE()) FOR [Created]
;
GO

ALTER TABLE [dbo].[Query]
	ADD CONSTRAINT DF_dbo_Query_LastUpdated
	DEFAULT(GETDATE()) FOR [LastUpdated]
;
GO
