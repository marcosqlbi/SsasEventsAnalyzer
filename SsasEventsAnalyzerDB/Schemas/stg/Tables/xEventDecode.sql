CREATE TABLE [stg].[xEventDecode] (
     EventClassId				INT NOT NULL,
     EventSubclassId			INT NOT NULL,
     EventClassName				VARCHAR(50) NULL,
     EventSubclassName			VARCHAR(50) NULL,
     EventClassDescription		VARCHAR(500) NULL,
     CONSTRAINT PK_stg_xEventDecode PRIMARY KEY CLUSTERED ( EventClassId, EventSubclassId )
);