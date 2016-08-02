-- Poll and start Trace Process
-- Note 2016.08.02 - this procedure is no longer useful by using the 
-- AutoRestart property in the XMLA trace start command
DECLARE @traceProcessActive AS INT = (
    SELECT COUNT(*) FROM 
    OPENROWSET ( 'MSOLAP','DataSource=LOCALHOST\TAB16;Initial Catalog=Contoso',
                 'SELECT * FROM $SYSTEM.DISCOVER_TRACES' )
    WHERE CAST ( [TraceID] AS VARCHAR(100) ) = 'TraceProcess'
);

IF @traceProcessActive = 0 
EXEC msdb.dbo.sp_start_job N'Start Trace Process' ;


-- Poll and start Trace Process
DECLARE @traceQueryActive AS INT = (
    SELECT COUNT(*) FROM 
    OPENROWSET ( 'MSOLAP','DataSource=LOCALHOST\TAB16;Initial Catalog=Contoso',
                 'SELECT * FROM $SYSTEM.DISCOVER_TRACES' )
    WHERE CAST ( [TraceID] AS VARCHAR(100) ) = 'TraceQuery'
);

IF @traceQueryActive = 0 
EXEC msdb.dbo.sp_start_job N'Start Query Process' ;
