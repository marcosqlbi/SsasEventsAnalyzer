CREATE TABLE [dbo].[Database](
	[ID_Database]		[int] IDENTITY(1,1) NOT NULL,
	[DatabaseName]		[varchar](128) NOT NULL,
	
	[Created]			DATETIME2(3)		NOT NULL,
	[LastUpdated]		DATETIME2(3)		NOT NULL
		
	,CONSTRAINT [PK_dbo_Database] PRIMARY KEY CLUSTERED ([ID_Database] ASC)
)
;
GO

ALTER TABLE [dbo].[Database]
	ADD CONSTRAINT DF_dbo_Database_Created
	DEFAULT(GETDATE()) FOR [Created]
;
GO

ALTER TABLE [dbo].[Database]
	ADD CONSTRAINT DF_dbo_Database_LastUpdated
	DEFAULT(GETDATE()) FOR [LastUpdated]
;
GO