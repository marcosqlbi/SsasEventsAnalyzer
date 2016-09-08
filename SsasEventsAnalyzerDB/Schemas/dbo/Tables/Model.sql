CREATE TABLE [dbo].[Model](
	[ID_Model]			[int] IDENTITY(1,1) NOT NULL,
	[ModelName]			[varchar](128) NOT NULL,
	[ID_Database]		[int] NOT NULL,
	
	[Created]			DATETIME2(3)		NOT NULL,
	[LastUpdated]		DATETIME2(3)		NOT NULL
		
	,CONSTRAINT [PK_dbo_Model] PRIMARY KEY CLUSTERED ([ID_Model] ASC)
	,CONSTRAINT FK_dbo_Model__DatabaseId
		FOREIGN KEY ([ID_Database])
		REFERENCES [dbo].[Database] ([ID_Database])
)
;
GO

ALTER TABLE [dbo].[Model]
	ADD CONSTRAINT DF_dbo_Model_Created
	DEFAULT(GETDATE()) FOR [Created]
;
GO

ALTER TABLE [dbo].[Model]
	ADD CONSTRAINT DF_dbo_Model_LastUpdated
	DEFAULT(GETDATE()) FOR [LastUpdated]
;
GO