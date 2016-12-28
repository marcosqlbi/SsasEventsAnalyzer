CREATE TABLE [dbo].[Column] (
	[ID_Column]				[int] IDENTITY(1,1)	NOT NULL,
	[ID_Table]				[int]				NOT NULL,
	[ColumnName]			[VARCHAR](255)		NOT NULL,
	
	[Created]				DATETIME2(3)		NOT NULL,
	[LastUpdated]			DATETIME2(3)		NOT NULL
		
	,CONSTRAINT [PK_dbo_Column] PRIMARY KEY CLUSTERED ([ID_Column] ASC)

	,CONSTRAINT [UNQ_dbo_Column_TableID_Column] UNIQUE ([ID_Table], [ColumnName])

	,CONSTRAINT FK_dbo_Column__TableId
		FOREIGN KEY ([ID_Table])
		REFERENCES [dbo].[Table] ([ID_Table])
);
GO

ALTER TABLE [dbo].[Column]
	ADD CONSTRAINT DF_dbo_Column_Created
	DEFAULT(GETDATE()) FOR [Created]
;
GO

ALTER TABLE [dbo].[Column]
	ADD CONSTRAINT DF_dbo_Column_LastUpdated
	DEFAULT(GETDATE()) FOR [LastUpdated]
;
GO