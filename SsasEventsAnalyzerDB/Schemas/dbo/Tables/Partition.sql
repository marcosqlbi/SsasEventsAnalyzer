CREATE TABLE [dbo].[Partition](
	[ID_Partition]			[int] IDENTITY(1,1) NOT NULL,
	[PartitionName]			[VARCHAR](128) NOT NULL,
	[PartitionGUID]			[VARCHAR](256) NOT NULL,
	[ID_Table]				[int] NOT NULL,
	
	[Created]				DATETIME2(3)		NOT NULL
		CONSTRAINT DF_dbo_Partition_Created DEFAULT(GETDATE()),
	[LastUpdated]			DATETIME2(3)		NOT NULL
		CONSTRAINT DF_dbo_Partition_Updated DEFAULT(GETDATE())
		
	,CONSTRAINT [PK_dbo_Partition] PRIMARY KEY CLUSTERED ([ID_Partition] ASC)

	,CONSTRAINT FK_dbo_Partition__TableId
		FOREIGN KEY ([ID_Table])
		REFERENCES [dbo].[Table] ([ID_Table])
) 
