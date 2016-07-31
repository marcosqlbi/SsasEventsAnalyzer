WITH    XmlEvents
          AS ( SELECT   CAST (event_data AS XML) AS E
               FROM     sys.fn_xe_file_target_read_file('K:\DevTemp\XEvents\*.xel', NULL, NULL, NULL)
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
             ),
        TabularTimeEvents
          AS ( SELECT   te.[Text],
                        te.CPUTime,
                        te.CurrentTime,
                        te.DatabaseName,
                        te.Duration,
                        EndTime = CAST (CASE WHEN te.EndTime >= CAST ('20100101' AS DATETIMEOFFSET) THEN te.EndTime
                                             ELSE NULL
                                        END AS DATETIME),
                        te.ErrorType,
                        te.EventClass,
                        te.EventSubclass,
                        te.IntegerData,
                        te.NTCanonicalUserName,
                        te.NTDomainName,
                        te.NTUserName,
                        te.ServerName,
                        te.ObjectPath,
                        StartTime = CAST (CASE WHEN te.StartTime >= CAST ('20100101' AS DATETIMEOFFSET)
                                               THEN te.StartTime
                                               ELSE NULL
                                          END AS DATETIME),
                        te.Success,
                        te.Severity,
                        te.RequestID,
                        te.ActivityIDxfer,
                        te.ActivityID
               FROM     TabularEvents te
             )
    SELECT  [Query Text] = [Text],
            [Query Checksum] = CONVERT (VARBINARY(8), CHECKSUM([Text])), -- use this to store string in Tabular
            [Date] = CAST ([StartTime] AS DATE),
            [Time] = CAST ([StartTime] AS TIME(0)),
            [Duration] = CAST ( CAST ( [Duration] / 86400000.0 AS DATETIME ) AS TIME(3)),
            [CPU Time] = CAST ( CAST ( [CPUTime] / 86400000.0 AS DATETIME ) AS TIME(3)),
            [Database] = [DatabaseName],
			[Object] = [ObjectPath],
            [Rows] = [IntegerData],
			[EventKey] = CAST ( [EventClass] AS VARCHAR(10) ) + '.' + CAST ( [EventSubclass] AS VARCHAR(10) ),
            [Class] = CASE [EventClass] WHEN 6 THEN 'Progress Report End' WHEN 16 THEN 'Command End' ELSE '?' END ,
            [Subclass] = CAST ( [EventSubclass] AS VARCHAR(10) ),
            [Domain] = [NTDomainName],
            [User] = [NTUserName],
            [Server] = [ServerName],
            [Success],
            [Severity]
    FROM    TabularTimeEvents
    WHERE   EventClass IN (6, 16) -- Command End, Progress Report End


