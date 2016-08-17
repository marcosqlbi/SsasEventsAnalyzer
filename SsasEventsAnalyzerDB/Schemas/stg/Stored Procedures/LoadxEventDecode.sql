CREATE PROCEDURE [stg].[LoadxEventDecode]
	@filepath_TraceDefinitinion		VARCHAR(300) = N'C:\Program Files\Microsoft SQL Server\MSAS13.SSAS_MD\OLAP\bin\Resources\1033\tracedefinition130.xml'
AS
BEGIN;
	--
	-- DESCRIPTION
	--      extracts Class & Subclass descriptions from the specified tracedefinition file
	--		and loads into the stg.xEventDecode table
	--
	-- PARAMETERS
	--		@filepath_TraceDefinitinion
	--			* specifies the filepath for the tracedefinition file
	--			* default value: 'C:\Program Files\Microsoft SQL Server\MSAS13.SSAS_MD\OLAP\bin\Resources\1033\tracedefinition130.xml'
	--
	-- RETURN VALUE
	--         0 - No Error.
	--
	SET NOCOUNT ON;

	BEGIN TRY

		IF OBJECT_ID('tempdb..#xEventClass', 'U') IS NOT NULL
			DROP TABLE #xEventClass;
		CREATE TABLE #xEventClass (
			 EventClassId INT NOT NULL,
			 EventClassName NVARCHAR(50) NULL,
			 EventClassDescription NVARCHAR(500) NULL
		);
		IF OBJECT_ID('tempdb..#xEventSubclass', 'U') IS NOT NULL
			DROP TABLE #xEventSubclass;
		CREATE TABLE #xEventSubclass (
			 EventClassId INT NOT NULL,
			 EventSubClassId INT NOT NULL,
			 EventSubClassName NVARCHAR(50) NULL
		);

		DECLARE @cmd NVARCHAR(MAX);
		DECLARE @rc INT;
		DECLARE @xmlSSAS_TraceDefinition XML;

		SET     @cmd = 'SELECT  @Content = CASE 
											   WHEN BulkColumn LIKE ''%xml version="1.0" encoding="UTF%'' THEN BulkColumn 
											   ELSE ''<?xml version="1.0" encoding="UTF-8"?>'' + BulkColumn 
										   END 
						FROM    OPENROWSET(BULK ' + QUOTENAME(@filepath_TraceDefinitinion, '''') + ', SINGLE_CLOB) AS f' ;

		-- Read the file and get the content in a XML variable
		EXEC @rc = sp_executesql @cmd, N'@Content XML OUTPUT', @Content = @xmlSSAS_TraceDefinition OUTPUT;


		/* shred the XML variable and insert values into tables created at beginning of script */
		INSERT  INTO #xEventClass
				( EventClassId,
				  EventClassName,
				  EventClassDescription
				)
		SELECT  EventClassId = t.c.value('./ID[1]', 'INT'),
				EventClassName = t.c.value('./NAME[1]', 'VARCHAR(50)'),
				EventClassDescription = t.c.value('./DESCRIPTION[1]', 'VARCHAR(500)')
		FROM    @xmlSSAS_TraceDefinition.nodes('/TRACEDEFINITION/EVENTCATEGORYLIST/EVENTCATEGORY/EVENTLIST/EVENT') AS t ( c );

		INSERT  INTO #xEventSubclass
				( EventClassId,
				  EventSubClassId,
				  EventSubClassName
				)
		SELECT  EventClassId = t.c.value('../../../../ID[1]', 'INT'),
				EventSubClassId = t.c.value('./ID[1]', 'INT'),
				EventSubClassName = t.c.value('./NAME[1]', 'VARCHAR(50)')
		FROM    @xmlSSAS_TraceDefinition.nodes('/TRACEDEFINITION/EVENTCATEGORYLIST/EVENTCATEGORY/EVENTLIST/EVENT/EVENTCOLUMNLIST/EVENTCOLUMN/EVENTCOLUMNSUBCLASSLIST/EVENTCOLUMNSUBCLASS')
				AS t ( c );


		INSERT INTO stg.xEventDecode ( 
					 EventClassId
					,EventSubclassId
					,EventClassName
					,EventSubclassName
					,EventClassDescription
			)
			SELECT  c.EventClassId,
					EventSubclassId = ISNULL(sc.EventSubclassId,-1),
					c.EventClassName,
					EventSubClassName = ISNULL(sc.EventSubClassName,'no subclass'),
					c.EventClassDescription
			FROM    #xEventClass c
					LEFT OUTER JOIN #xEventSubclass sc
						ON	sc.EventClassId = c.EventClassId
		;

		DROP TABLE #xEventClass;
		DROP TABLE #xEventSubclass;

	END TRY
	BEGIN CATCH
	
		/* capture error variables */
		DECLARE  @lErrorNumber INT = ERROR_NUMBER()
				,@lErrorSeverity INT = ERROR_SEVERITY()
				,@lErrorState INT = ERROR_STATE()
				,@lErrorProcedure VARCHAR(128) = ERROR_PROCEDURE()
				,@lErrorLine INT = ERROR_LINE()
				,@lErrorMessage VARCHAR(4000) = ERROR_MESSAGE()
		;
		/* log error */
		EXEC [log].[LogError]
				 @ErrorNumber = @lErrorNumber
				,@ErrorSeverity = @lErrorSeverity
				,@ErrorState = @lErrorState
				,@ErrorProcedure = @lErrorProcedure
				,@ErrorLine = @lErrorLine
				,@ErrorMessage = @lErrorMessage
		;
		/* re-throw exception to parent */
		THROW;

	END CATCH

	RETURN 0;

END
;