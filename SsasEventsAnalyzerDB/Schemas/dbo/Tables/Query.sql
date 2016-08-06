CREATE TABLE [dbo].[Query] (
	[ID_Query]				[int]				IDENTITY(1,1) NOT NULL,
	[QueryString]			[VARCHAR](max)		NOT NULL,
	[QueryType]				[VARCHAR](3)		NOT NULL,
	[NK_QueryChecksum]		[varbinary](8)		NOT NULL,
	
	[Created]				DATETIME2(3)		NOT NULL
		CONSTRAINT DF_dbo_Query_Created DEFAULT(GETDATE()),
	[LastUpdated]			DATETIME2(3)		NOT NULL
		CONSTRAINT DF_dbo_Query_Updated DEFAULT(GETDATE())
		
	,CONSTRAINT [PK_dbo_Query] PRIMARY KEY CLUSTERED ([ID_Query] ASC)

)
