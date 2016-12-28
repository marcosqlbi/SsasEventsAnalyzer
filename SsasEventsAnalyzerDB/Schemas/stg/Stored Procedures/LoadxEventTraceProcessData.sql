CREATE PROCEDURE [stg].[LoadxEventTraceProcessData]
	 @path_to_trace_file		VARCHAR(1024) = 'C:\Program Files\Microsoft SQL Server\MSAS13.TAB16\OLAP\Log\'
AS
BEGIN;
	--
	-- DESCRIPTION
	--      extracts data from xEvent trace file (based on TraceProcess.xmla) and 
	--		loads into a staging table (stg.xEventTraceProcess). Process and 
	--		ProcessExecution tables are populated from staging table
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
	
		DECLARE @xe_file_target VARCHAR(1024);

		/* add trailing slash if missing */
		IF (RIGHT(@path_to_trace_file,1) != '\')
			SET @xe_file_target = @path_to_trace_file + '\' + 'TraceProcess*.xel';
		ELSE
			SET @xe_file_target = @path_to_trace_file + 'TraceProcess*.xel';

		-- ==============================================================
		-- Extract RAW xEvent data into staging table
		-- ==============================================================

		WITH    XmlEvents
				  AS ( SELECT   CAST (event_data AS XML) AS E
					   FROM     sys.fn_xe_file_target_read_file(@xe_file_target, NULL, NULL, NULL)
					 ),
				TabularEvents
				  AS ( SELECT   [ActivityID] = E.value('(/event/action[@name="attach_activity_id"]/value)[1]', 'varchar(255)'),
								[ActivityIDxfer] = E.value('(/event/action[@name="attach_activity_id_xfer"]/value)[1]', 'varchar(255)'),
								[ConnectionID] = E.value('(/event/data[@name="ConnectionID"]/value)[1]', 'int'),
								[CPUTime] = E.value('(/event/data[@name="CPUTime"]/value)[1]', 'int'),
								[CurrentTime] = E.value('(/event/data[@name="CurrentTime"]/value)[1]', 'datetime'),
								[DatabaseName] = E.value('(/event/data[@name="DatabaseName"]/value)[1]', 'varchar(255)'),
								[Duration] = E.value('(/event/data[@name="Duration"]/value)[1]', 'int'),
								[EndTime] = E.value('(/event/data[@name="EndTime"]/value)[1]', 'datetimeoffset'),
								[ErrorType] = E.value('(/event/data[@name="ErrorType"]/value)[1]', 'int'),
								[EventClass] = E.value('(/event/data[@name="EventClass"]/value)[1]', 'int'),
								[EventSubclass] = E.value('(/event/data[@name="EventSubclass"]/value)[1]', 'int'),
								[IntegerData] = E.value('(/event/data[@name="IntegerData"]/value)[1]', 'int'),
								[NTCanonicalUserName] = E.value('(/event/data[@name="NTCanonicalUserName"]/value)[1]', 'varchar(255)'),
								[NTDomainName] = E.value('(/event/data[@name="NTDomainName"]/value)[1]', 'varchar(255)'),
								[NTUserName] = E.value('(/event/data[@name="NTUserName"]/value)[1]', 'varchar(255)'),
								[ObjectID] = E.value('(/event/data[@name="ObjectID"]/value)[1]', 'varchar(255)'),
								[ObjectName] = E.value('(/event/data[@name="ObjectName"]/value)[1]', 'varchar(255)'),
								[ObjectPath] = E.value('(/event/data[@name="ObjectPath"]/value)[1]', 'varchar(255)'),
								[ObjectType] = E.value('(/event/data[@name="ObjectType"]/value)[1]', 'int'),
								[ProgressTotal] = E.value('(/event/data[@name="ProgressTotal"]/value)[1]', 'int'),
								[RequestID] = E.value('(/event/data[@name="RequestID"]/value)[1]', 'varchar(255)'),
								[ServerName] = E.value('(/event/data[@name="ServerName"]/value)[1]', 'varchar(255)'),
								[SessionID] = E.value('(/event/data[@name="SessionID"]/value)[1]', 'varchar(255)'),
								[Severity] = E.value('(/event/data[@name="Severity"]/value)[1]', 'int'),
								[StartTime] = E.value('(/event/data[@name="StartTime"]/value)[1]', 'datetimeoffset'),
								[Success] = E.value('(/event/data[@name="Success"]/value)[1]', 'int'),
								[Text] = E.value('(/event/data[@name="TextData"]/value)[1]', 'varchar(max)')
					   FROM     XmlEvents
					 )
		INSERT INTO stg.[xEventTraceProcess] (
					 [ActivityID]
					,[ActivityIDxfer]
					,[ConnectionID]
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
					,[ObjectID]
					,[ObjectName]
					,[ObjectPath]
					,[ObjectType]
					,[ProgressTotal]
					,[RequestID]
					,[ServerName]
					,[SessionID]
					,[Severity]
					,[StartTime]
					,[Success]
					,[Text]
					,[NK_ProcessChecksum]

					,[ModelName]
					,[TableName]
					,[PartitionName]
					,[PartitionTableGUID]
					,[ColumnName]
			)
			SELECT	 te.ActivityID
					,te.ActivityIDxfer
					,te.ConnectionID
					,te.CPUTime
					,te.CurrentTime
					,te.DatabaseName
					,te.Duration
					,EndTime = CAST (CASE WHEN te.EndTime >= CAST ('20100101' AS DATETIMEOFFSET) THEN te.EndTime ELSE NULL END AS DATETIME)
					,te.ErrorType
					,te.EventClass
					,te.EventSubclass
					,te.IntegerData
					,te.NTCanonicalUserName
					,te.NTDomainName
					,te.NTUserName
					,te.ObjectID
					,te.ObjectName
					,te.ObjectPath
					,te.ObjectType
					,te.ProgressTotal
					,te.RequestID
					,te.ServerName
					,te.SessionID
					,te.Severity
					,StartTime = CAST (CASE WHEN te.StartTime >= CAST ('20100101' AS DATETIMEOFFSET) THEN te.StartTime ELSE NULL END AS DATETIME)
					,te.Success
					,te.[Text]
					,NK_ProcessChecksum = CONVERT(VARBINARY(8), CHECKSUM([Text]))

					,[ModelName] = 
						CASE
							WHEN	te.EventClass = 6 AND /* Progress Report End */
									te.EventSubClass != 14 AND /* Query */
									te.ObjectPath IS NOT NULL AND RTRIM(te.ObjectPath) != '' AND
									te.ObjectType IN (100016, 100021)
							THEN
								SUBSTRING(
									 te.ObjectPath
									,CHARINDEX('.', te.ObjectPath, CHARINDEX('.', te.ObjectPath, 0)+1)+1
									,CASE
										WHEN CHARINDEX('.', te.ObjectPath, CHARINDEX('.', te.ObjectPath, CHARINDEX('.', te.ObjectPath, 0)+1)+1) = 0 THEN LEN(te.ObjectPath) 
										ELSE CHARINDEX('.', te.ObjectPath, CHARINDEX('.', te.ObjectPath, CHARINDEX('.', te.ObjectPath, 0)+1)+1)-CHARINDEX('.', te.ObjectPath, CHARINDEX('.', te.ObjectPath, 0)+1)-1 
									 END
								) 
						END
						
					,[TableName] =
						CASE
							WHEN	te.EventClass = 6 AND /* Progress Report End */
									te.EventSubClass != 14 AND /* Query */
									te.ObjectPath IS NOT NULL AND RTRIM(te.ObjectPath) != '' AND
									te.ObjectType IN (100006, 100007, 100008, 100016)
							THEN	te.ObjectName
						END
					,[PartitionName] = CASE WHEN te.ObjectType IN (100021) THEN te.ObjectName END
					,[PartitionTableGUID] = CASE WHEN te.ObjectType IN (100021) THEN REVERSE(LEFT(RIGHT( REVERSE(te.ObjectPath), LEN( REVERSE(te.ObjectPath) ) - CHARINDEX('.',REVERSE(te.ObjectPath)) ), CHARINDEX('.',RIGHT( REVERSE(te.ObjectPath), LEN( REVERSE(te.ObjectPath) ) - CHARINDEX('.',REVERSE(te.ObjectPath)) )) - 1)) END
					,[ColumnName] = 
						CASE
							WHEN	te.EventClass = 6 AND /* Progress Report End */
									te.EventSubclass = 44 /* Compress Segment */
							THEN	SUBSTRING(te.[text], CHARINDEX('''',te.[text]) + 1, (CHARINDEX('''', SUBSTRING(te.[text], CHARINDEX('''',te.[text]) + 1, LEN(te.[Text])-CHARINDEX('''',te.[text]))) - 1) )
						END
			FROM    TabularEvents te
			WHERE   te.EventClass IN (6, 16) -- Command End, Progress Report End
		;

		-- ==============================================================
		-- Database 
		-- ==============================================================
		INSERT INTO [dbo].[Database] (DatabaseName)
			SELECT	stg.DatabaseName
			FROM	stg.xEventTraceProcess stg
					INNER JOIN stg.xEventDecode x 
						ON	x.EventClassId = stg.EventClass AND
							x.EventSubclassId = stg.EventSubclass
					LEFT OUTER JOIN [dbo].[Database] AS d
						ON	stg.DatabaseName = d.DatabaseName
			WHERE	d.[ID_Database] IS NULL AND
					x.EventClassName = 'Command End' AND 
					x.EventSubclassName = 'Process'
			GROUP BY stg.DatabaseName
		;
		-- ==============================================================
		-- Model 
		-- ==============================================================	   
		INSERT INTO [dbo].[Model] (ModelName, [ID_Database])
			SELECT	 trc.ModelName
					,db.[ID_Database] 
			FROM	stg.xEventTraceProcess trc
					INNER JOIN [dbo].[Database] AS db
						ON	trc.DatabaseName = db.DatabaseName
					LEFT JOIN [dbo].[Model] AS m
						ON	m.ModelName = trc.ModelName AND 
							m.[ID_Database] = db.[ID_Database]
			WHERE	m.ModelName IS NULL AND
					trc.ModelName IS NOT NULL
			GROUP BY trc.ModelName
					,db.[ID_Database]
		;
		-- ==============================================================
		-- Table
		-- ==============================================================
		INSERT INTO [dbo].[Table] (TableName, TableGUID, [ID_Database])
			SELECT	 trc.TableName
					,TableGUID = trc.ObjectID
					,db.ID_Database
			FROM	stg.xEventTraceProcess trc
					INNER JOIN [dbo].[Database] AS db
						ON	db.DatabaseName = trc.DatabaseName
					LEFT JOIN [dbo].[Table] AS t
						ON	t.TableName = trc.TableName AND 
							t.TableGUID = trc.ObjectID AND 
							t.[ID_Database] = db.ID_Database
			WHERE	trc.TableName IS NOT NULL AND 
					t.[ID_Table] IS NULL
			GROUP BY trc.TableName
					,trc.ObjectID
					,db.ID_Database
		;

		-- ==============================================================
		-- Partition
		-- ==============================================================
		INSERT INTO [dbo].[Partition] (PartitionName, PartitionGUID, [ID_Table])
			SELECT	 trc.PartitionName
					,PartitionGUID = trc.ObjectID
					,t.[ID_Table]
			FROM	stg.xEventTraceProcess trc
					INNER JOIN [dbo].[Database] AS db
						ON	db.DatabaseName = trc.DatabaseName
					INNER JOIN [dbo].[Table] AS t
						ON	t.TableGUID = trc.PartitionTableGUID AND 
							t.[ID_Database] = db.ID_Database
					LEFT OUTER JOIN dbo.[Partition] p
						ON	p.PartitionGUID = trc.ObjectID AND
							p.ID_Table = t.ID_Table 
			WHERE	trc.PartitionName IS NOT NULL AND
					p.PartitionGUID IS NULL
			GROUP BY trc.PartitionName
					,trc.ObjectID
					,t.[ID_Table]
		;

		-- ==============================================================
		-- Column
		-- ==============================================================
		INSERT INTO [dbo].[Column] (ColumnName, [ID_Table])
			SELECT	 trc.[ColumnName]
					,t.[ID_Table]
			FROM	stg.xEventTraceProcess trc
					INNER JOIN stg.xEventDecode x
						ON	x.EventClassId = trc.EventClass AND
							x.EventSubclassId = trc.EventSubclass
					INNER JOIN [dbo].[Database] AS db
						ON	db.DatabaseName = trc.DatabaseName
					INNER JOIN [dbo].[Table] AS t
						ON	t.TableGUID = trc.PartitionTableGUID AND 
							t.[ID_Database] = db.ID_Database
					LEFT OUTER JOIN [dbo].[Column] c
						ON	c.ID_Table = t.ID_Table AND
							c.ColumnName = trc.[ColumnName]
			WHERE	trc.ColumnName IS NOT NULL AND
					c.ID_Column IS NULL
			GROUP BY trc.[ColumnName]
					,t.[ID_Table]
		;


		-- ==============================================================
		-- Process 
		-- ==============================================================
		INSERT INTO [dbo].[Process] (
					 [ProcessString]
					,NK_ProcessChecksum
			)
			SELECT	 ProcessingString = stg.[Text]
					,NK_ProcessChecksum = stg.NK_ProcessChecksum
			FROM	stg.xEventTraceProcess stg
					LEFT JOIN dbo.[Process] AS p
						ON	p.NK_ProcessChecksum = stg.NK_ProcessChecksum
			WHERE	p.ID_Process IS NULL AND 
					stg.EventClass = 16 AND /* Command End */
					stg.EventSubclass = 3 /* Process */
			GROUP BY stg.[Text]
					,stg.NK_ProcessChecksum
		;

		-- ==============================================================
		-- Process Execution
		-- ==============================================================
		INSERT INTO dbo.[ProcessExecution] (
					 [ID_Process]
					,[ProcessStartDate]
					,[ProcessStartTime]
					,[ProcessStartDT]
					,[Duration]
					,[CPUTime]
					,[Duration_ms]
					,[CPUTime_ms]
					,[ID_Database]
					,[Domain]
					,[User]
					,[Server]
					,[Success]
					,[Severity]
					,[ActivityID]
					,[ActivityIDxfer]
			)
			SELECT   [ID_Process] = q.[ID_Process]
					,[ProcessStartDate] = CAST (stg.[StartTime] AS DATE)
					,[ProcessStartTime] = CAST (stg.[StartTime] AS TIME(0))
					,[ProcessStartDT] = stg.[StartTime]
					,[Duration]	= CAST ( CAST ( stg.[Duration] / 86400000.0 AS DATETIME ) AS TIME(3))
					,[CPUTime] = CAST ( CAST ( stg.[CPUTime] / 86400000.0 AS DATETIME ) AS TIME(3))
					,[Duration_ms] = stg.[Duration]
					,[CPUTime_ms] = stg.[CPUTime]
					,[ID_Database] = d.ID_Database
					,[Domain] = stg.[NTDomainName]
					,[User] = stg.[NTUserName]
					,[Server] = stg.[ServerName]
					,[Success] = stg.[Success]
					,[Severity] = stg.Severity
					,[ActivityID] = stg.ActivityID
					,[ActivityIDxfer] = stg.ActivityIDxfer
			FROM	stg.[xEventTraceProcess] stg
					INNER JOIN dbo.Process q
						ON	q.NK_ProcessChecksum = stg.NK_ProcessChecksum
					INNER JOIN dbo.[Database] d
						ON	d.DatabaseName = stg.DatabaseName
			WHERE	stg.EventClass = 16 AND /* Command End */
					stg.EventSubclass = 3 AND /* Process */
					NOT EXISTS (
						SELECT	TOP 1 'Exists'
						FROM	dbo.ProcessExecution qe
						WHERE	qe.[ID_Process] = q.[ID_Process] AND
								qe.[ProcessStartDT] = stg.[StartTime]
					)
			;
		-- ==============================================================
		-- Cleanup
		-- ==============================================================
		--TRUNCATE TABLE stg.[xEventTraceProcess];

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