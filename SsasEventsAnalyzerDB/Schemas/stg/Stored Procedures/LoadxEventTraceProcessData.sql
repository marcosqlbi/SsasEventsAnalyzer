CREATE PROCEDURE [stg].[LoadxEventTraceProcessData]
	 @path_to_trace_file		VARCHAR(1024) = 'C:\Program Files\Microsoft SQL Server\MSAS13.TAB16\OLAP\Log\'
AS
BEGIN;
	--
	-- DESCRIPTION
	--      extracts data from xEvent trace file (based on TraceProcess.xmla) and 
	--		loads into a staging table (stg.xEventTraceProcess)
	--
	-- PARAMETERS
	--		@path_to_trace_file
	--			* specifies the path from where the xEvent trace files (*.xel) are stored
	--			* must contain trailing backslash
	--			* default value: 'C:\Program Files\Microsoft SQL Server\MSAS13.TAB16\OLAP\Log\'
	--
	-- RETURN VALUE
	--         0 - No Error.
	--
	SET NOCOUNT ON;

	BEGIN TRY

		-- ==============================================================
		-- Extract RAW xEvent data into staging table
		-- ==============================================================
		DECLARE @xe_file_target VARCHAR(1024) = @path_to_trace_file + 'TraceProcess*.xel';

		WITH    XmlEvents
				  AS ( SELECT   CAST (event_data AS XML) AS E
					   FROM     sys.fn_xe_file_target_read_file(@xe_file_target, NULL, NULL, NULL)
					 ),
				TabularEvents
				  AS ( SELECT   [Text] = E.value('(/event/data[@name="TextData"]/value)[1]', 'varchar(max)'),
								[CPUTime] = E.value('(/event/data[@name="CPUTime"]/value)[1]', 'int'),
								[CurrentTime] = E.value('(/event/data[@name="CurrentTime"]/value)[1]', 'datetime'),
								[DatabaseName] = E.value('(/event/data[@name="DatabaseName"]/value)[1]', 'varchar(255)'),
								[Duration] = E.value('(/event/data[@name="Duration"]/value)[1]', 'int'),
								[EndTime] = E.value('(/event/data[@name="EndTime"]/value)[1]', 'datetimeoffset'),
								[ErrorType] = E.value('(/event/data[@name="ErrorType"]/value)[1]', 'int'),
								[EventClass] = E.value('(/event/data[@name="EventClass"]/value)[1]', 'int'),
								[EventSubclass] = E.value('(/event/data[@name="EventSubclass"]/value)[1]', 'int'),
								[IntegerData] = E.value('(/event/data[@name="IntegerData"]/value)[1]', 'int'),
								[NTCanonicalUserName] = E.value('(/event/data[@name="NTCanonicalUserName"]/value)[1]',
																'varchar(255)'),
								[NTDomainName] = E.value('(/event/data[@name="NTDomainName"]/value)[1]', 'varchar(255)'),
								[NTUserName] = E.value('(/event/data[@name="NTUserName"]/value)[1]', 'varchar(255)'),
								[ServerName] = E.value('(/event/data[@name="ServerName"]/value)[1]', 'varchar(255)'),
								[ObjectPath] = E.value('(/event/data[@name="ObjectPath"]/value)[1]', 'varchar(255)'),
								[StartTime] = E.value('(/event/data[@name="StartTime"]/value)[1]', 'datetimeoffset'),
								[Success] = E.value('(/event/data[@name="Success"]/value)[1]', 'int'),
								[Severity] = E.value('(/event/data[@name="Severity"]/value)[1]', 'int'),
								[RequestID] = E.value('(/event/data[@name="RequestID"]/value)[1]', 'varchar(255)'),
								[ActivityIDxfer] = E.value('(/event/action[@name="attach_activity_id_xfer"]/value)[1]',
														   'varchar(255)'),
								[ActivityID] = E.value('(/event/action[@name="attach_activity_id"]/value)[1]', 'varchar(255)')
					   FROM     XmlEvents
					 )
		INSERT INTO stg.[xEventTraceProcess] (
					 [ActivityID]
					,[ActivityIDxfer]
					,[CPUTime]
					,[CurrentTime]
					,[DatabaseName]
					,[Duration]
					,[EndTime]
					,[ErrorType]
					,[EventClass]
					,[EventSubclass]
					,[IntegerData]
					,[NTCanonicalUserName]
					,[NTDomainName]
					,[NTUserName]
					,[ObjectPath]
					,[RequestID]
					,[StartTime]
					,[ServerName]
					,[Severity]
					,[Success]
					,[Text]
			)
			SELECT	 te.ActivityIDxfer
					,te.ActivityID
					,te.CPUTime
					,te.CurrentTime
					,te.DatabaseName
					,te.Duration
					,EndTime = CAST (CASE WHEN te.EndTime >= CAST ('20100101' AS DATETIMEOFFSET) THEN te.EndTime
											ELSE NULL
									END AS DATETIME)
					,te.ErrorType
					,te.EventClass
					,te.EventSubclass
					,te.IntegerData
					,te.NTCanonicalUserName
					,te.NTDomainName
					,te.NTUserName
					,te.ObjectPath
					,te.RequestID
					,StartTime = CAST (CASE WHEN te.StartTime >= CAST ('20100101' AS DATETIMEOFFSET)
											THEN te.StartTime
											ELSE NULL
										END AS DATETIME)
					,te.ServerName
					,te.Severity
					,te.Success
					,te.[Text]
			FROM    TabularEvents te
			WHERE   te.EventClass IN (6, 16) -- Command End, Progress Report End
		;
		
			
		-- ==============================================================
		-- Cleanup
		-- ==============================================================
		--TRUNCATE TABLE stg.[xEventTraceProcess]

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