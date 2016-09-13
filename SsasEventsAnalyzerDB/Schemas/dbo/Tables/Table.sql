CREATE TABLE [dbo].[Table](
	[ID_Table]				[int] IDENTITY(1,1) NOT NULL,
	[TableName]				[varchar](255)		NOT NULL,
	[TableGUID]				[varchar](256)		NOT NULL,
	[ID_Database]			[int]				NOT NULL,
	
	[Created]				DATETIME2(3)		NOT NULL,
	[LastUpdated]			DATETIME2(3)		NOT NULL
		
	,CONSTRAINT [PK_dbo_Table] PRIMARY KEY CLUSTERED ([ID_Table] ASC)

	,CONSTRAINT [UNQ_dbo_Table_DatabaseID_Table] UNIQUE ([ID_Database], [TableName])

	,CONSTRAINT FK_dbo_Table__DatabaseId
		FOREIGN KEY ([ID_Database])
		REFERENCES [dbo].[Database] (ID_Database)
)
;
GO

ALTER TABLE [dbo].[Table]
	ADD CONSTRAINT DF_dbo_Table_Created
	DEFAULT(GETDATE()) FOR [Created]
;
GO

ALTER TABLE [dbo].[Table]
	ADD CONSTRAINT DF_dbo_Table_LastUpdated
	DEFAULT(GETDATE()) FOR [LastUpdated]
;
GO

