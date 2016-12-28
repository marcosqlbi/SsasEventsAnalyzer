param(
    [string]$xevent_src_trace_dir, 
    [string]$xevent_tgt_trace_dir,
    [string]$ssas_event_analyzer_server,
    [string]$ssas_event_analyzer_db,
    [int]$archive_flag
)


Function Get-FileLockStatus {
    #https://stackoverflow.com/questions/24992681/powershell-check-if-a-file-is-locked
    param (
        [parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)][string]$FilePath
    )

    $oFile = New-Object System.IO.FileInfo $FilePath

    if ((Test-Path -Path $FilePath) -eq $false)
    {
        return $false
    }

    try {
        $oStream = $oFile.Open([System.IO.FileMode]::Open, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
        if ($oStream) {
            $oStream.Close()
        }
        $false
    }
    catch {
        # file is locked by a process.
        return $true
    }
}

Function Move-xEventTraceFiles {
    param(
        [Parameter(Position=0,mandatory=$true)][string] $xevent_src_trace_dir,
        [Parameter(Position=1,mandatory=$true)][string] $xevent_tgt_trace_dir,
        [Parameter(Position=2,mandatory=$true)][string] $ssas_event_analyzer_server,
        [Parameter(Position=3,mandatory=$true)][string] $ssas_event_analyzer_db,
        [Parameter(Position=4,mandatory=$true)][int] $archive_flag
    )

    Get-ChildItem -Path $xevent_src_trace_dir -Filter *.xel | 
        ForEach-Object {
            $file_in_use = (Get-FileLockStatus -FilePath $_.FullName)

            if( -Not ($file_in_use) ) {
                Write-Debug("File: {0} | InUse: {1}" -f $_.Name, $file_in_use)
                
                # move file to processing dir
                Move-Item -Path $_.FullName -Destination $xevent_tgt_trace_dir

                # add file to processing table
				if ( $archive_flag -ne 1 ) {
					$sql_stmt = "INSERT INTO [log].[xEventFileAuditLog] (xEventFileName) VALUES ('" + $_.Name + "');"
				} else {
					$sql_stmt = "UPDATE [log].[xEventFileAuditLog] SET [Archived_DT] = GETDATE() WHERE [xEventFileName] = '" + $_.Name + "';";
				}
				Invoke-Sqlcmd -ServerInstance $ssas_event_analyzer_server -Database $ssas_event_analyzer_db -Query $sql_stmt
            }
        }
}


## TEST parmater values
# $xevent_src_trace_dir = "C:\Program Files\Microsoft SQL Server\MSAS13.SSAS_TAB\OLAP\Log\"
# $xevent_tgt_trace_dir = "C:\Program Files\Microsoft SQL Server\MSAS13.SSAS_TAB\OLAP\Log\xevent_trace_processing"
# $ssas_event_analyzer_server = "SQL-DEV-02"
# $ssas_event_analyzer_db = "SsasEventsAnalyzerDB"
# $archive_flag = 1

# function call
Move-xEventTraceFiles `
    -xevent_src_trace_dir $xevent_src_trace_dir `
    -xevent_tgt_trace_dir $xevent_tgt_trace_dir `
    -ssas_event_analyzer_server $ssas_event_analyzer_server `
    -ssas_event_analyzer_db $ssas_event_analyzer_db `
    -archive_flag $archive_flag