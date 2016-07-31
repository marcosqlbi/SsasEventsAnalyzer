-- Retrieve all event description from SSAS 2016
-- Original code by Bill Anton
-- http://byobi.com/blog/2013/02/sql-profiler-eventclass-eventsubclass-column-descriptions-for-ssas-2012/
--

USE tempdb;
GO


IF OBJECT_ID('dbo.ProfilerEventClass_SSAS2012', 'U') IS NOT NULL
    DROP TABLE dbo.ProfilerEventClass_SSAS2012;
CREATE TABLE dbo.ProfilerEventClass_SSAS2012 (
     EventClassId INT NOT NULL,
     EventClassName NVARCHAR(50) NULL,
     EventClassDescription NVARCHAR(500) NULL,
     CONSTRAINT PK_dbo_ProfilerEventClass_SSAS2012 PRIMARY KEY CLUSTERED ( EventClassId )
    );
IF OBJECT_ID('dbo.ProfilerEventSubClass_SSAS2012', 'U') IS NOT NULL
    DROP TABLE dbo.ProfilerEventSubClass_SSAS2012;
CREATE TABLE dbo.ProfilerEventSubClass_SSAS2012 (
     EventClassId INT NOT NULL,
     EventSubClassId INT NOT NULL,
     EventSubClassName NVARCHAR(50) NULL,
     CONSTRAINT PK_dbo_ProfilerEventSubClass_SSAS2012 PRIMARY KEY CLUSTERED ( EventClassId, EventSubClassId )
    );

/*
Altered code from here: http://www.sqlteam.com/forums/topic.asp?TOPIC_ID=130743
to read in file contents of Trace Definition
*/
DECLARE @fnTraceDefinitinionFileName NVARCHAR(300);
/* Note: this file needs to be in a directory that the SQL Server service account has read permissions */
SET @fnTraceDefinitinionFileName = N'C:\Program Files\Microsoft SQL Server\MSAS13.TAB16\OLAP\bin\Resources\1033\tracedefinition130.xml';

-- Initialize command string, return code and file content
DECLARE @cmd NVARCHAR(MAX),
    @rc INT,
    @xmlSSAS110_TraceDefinition XML;

BEGIN;
-- Make sure accents are preserved if encoding is missing by adding encoding information UTF-8
    SET @cmd = 'SELECT @Content = CASE
WHEN BulkColumn LIKE ''%xml version=&amp;amp;amp;amp;quot;1.0&amp;amp;amp;amp;quot; encoding=&amp;amp;amp;amp;quot;UTF%'' THEN BulkColumn
ELSE ''&amp;amp;amp;amp;lt;?xml version=&amp;amp;amp;amp;quot;1.0&amp;amp;amp;amp;quot; encoding=&amp;amp;amp;amp;quot;UTF-8&amp;amp;amp;amp;quot;?&amp;amp;amp;amp;gt;'' + BulkColumn
END
FROM OPENROWSET(BULK ' + QUOTENAME(@fnTraceDefinitinionFileName, '''') + ', SINGLE_CLOB) AS f';

-- Read the file and get the content in a XML variable
    EXEC @rc = sp_executesql @cmd, N'@Content XML OUTPUT', @Content = @xmlSSAS110_TraceDefinition OUTPUT;
END;

/* shred the XML variable and insert values into tables created at beginning of script */
INSERT  INTO dbo.ProfilerEventClass_SSAS2012
        ( EventClassId,
          EventClassName,
          EventClassDescription
        )
SELECT  EventClassId = t.c.value('./ID[1]', 'INT'),
        EventClassName = t.c.value('./NAME[1]', 'VARCHAR(50)'),
        EventClassDescription = t.c.value('./DESCRIPTION[1]', 'VARCHAR(500)')
FROM    @xmlSSAS110_TraceDefinition.nodes('/TRACEDEFINITION/EVENTCATEGORYLIST/EVENTCATEGORY/EVENTLIST/EVENT') AS t ( c );

INSERT  INTO dbo.ProfilerEventSubClass_SSAS2012
        ( EventClassId,
          EventSubClassId,
          EventSubClassName
        )
SELECT  EventClassId = t.c.value('../../../../ID[1]', 'INT'),
        EventSubClassId = t.c.value('./ID[1]', 'INT'),
        EventSubClassName = t.c.value('./NAME[1]', 'VARCHAR(50)')
FROM    @xmlSSAS110_TraceDefinition.nodes('/TRACEDEFINITION/EVENTCATEGORYLIST/EVENTCATEGORY/EVENTLIST/EVENT/EVENTCOLUMNLIST/EVENTCOLUMN/EVENTCOLUMNSUBCLASSLIST/EVENTCOLUMNSUBCLASS')
        AS t ( c );

SELECT  EventKey = CAST (c.EventClassId AS VARCHAR(10)) + '.' + CAST (sc.EventSubClassId AS VARCHAR(10)),
        c.EventClassId,
        c.EventClassName,
        c.EventClassDescription,
        sc.EventSubClassId,
        sc.EventSubClassName
FROM    dbo.ProfilerEventClass_SSAS2012 c
INNER JOIN dbo.ProfilerEventSubClass_SSAS2012 sc
        ON sc.EventClassId = c.EventClassId;
