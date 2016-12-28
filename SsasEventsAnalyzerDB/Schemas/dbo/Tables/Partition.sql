CREATE TABLE [dbo].[Partition](
	[ID_Partition]			[int] IDENTITY(1,1) NOT NULL,
	[PartitionName]			[VARCHAR](255)		NOT NULL,
	[PartitionGUID]			[VARCHAR](256)		NOT NULL,
	[ID_Table]				[int]				NOT NULL,
	
	[Created]				DATETIME2(3)		NOT NULL,
	[LastUpdated]			DATETIME2(3)		NOT NULL
		
	,CONSTRAINT [PK_dbo_Partition] PRIMARY KEY CLUSTERED ([ID_Partition] ASC)

	,CONSTRAINT [UNQ_dbo_Partition_TableID_Partition] UNIQUE ([ID_Table], [PartitionName])

	,CONSTRAINT FK_dbo_Partition__TableId
		FOREIGN KEY ([ID_Table])
		REFERENCES [dbo].[Table] ([ID_Table])
);
GO

ALTER TABLE [dbo].[Partition]
	ADD CONSTRAINT DF_dbo_Partition_Created
	DEFAULT(GETDATE()) FOR [Created]
;
GO

ALTER TABLE [dbo].[Partition]
	ADD CONSTRAINT DF_dbo_Partition_LastUpdated
	DEFAULT(GETDATE()) FOR [LastUpdated]
;
GO