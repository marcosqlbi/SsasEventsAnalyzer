/* step 1: move from log dir to processing dir */
/* step 2: process files
		SPROC: dbo.LoadxEventTraceProcessData
		SPROC: dbo.LoadxEventTraceQueryData

		future state: query xEventFileAuditLog for unprocessed files (process in order if batching)
*/

/* step 3: archive files */




