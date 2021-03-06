function Write-Log {  
  [CmdletBinding(SupportsShouldProcess, SupportsPaging)]
  param(
    # The type of message to be logged. Alias is 'type'.
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName)]
    [ValidateSet('Error', 'Warn', 'Info', 'Verbose')]
    [ValidateNotNullOrEmpty()]
    [string] $Level = 'Info',

    # The message to be logged.
    [Parameter(ValueFromPipeline, ValueFromPipelineByPropertyName, Mandatory, HelpMessage = 'No message specified.')]
    [ValidateNotNullOrEmpty()]
    [string] $Message,

    # Specifies that $message should not the sent to the log file.
    [Parameter(ValueFromPipelineByPropertyName)]
    [switch] $NoLog,

    # Specifies to not display the message to the console.
    [Parameter(ValueFromPipelineByPropertyName)]
    [switch] $NoConsole,

    # The number of spaces to indent the message in the log file.
    [Parameter(ValueFromPipelineByPropertyName)]
    [ValidateRange(1,30)]
    [ValidateNotNullOrEmpty()]
    [int] $Indent = 0,

    # Specifies what color the text should be be displayed on the console. Ignored when switch 'NoConsoleOut' is specified.
    [Parameter(ValueFromPipelineByPropertyName)]
    [ValidateSet('Black', 'DarkMagenta', 'DarkRed', 'DarkBlue', 'DarkGreen', 'DarkCyan', 'DarkYellow', 'Red', 'Blue', 'Green', 'Cyan', 'Magenta', 'Yellow', 'DarkGray', 'Gray', 'White')]
    [ValidateNotNullOrEmpty()]
    [String] $ConsoleForeground = 'White',

    # Existing log file is deleted when this is specified. Alias is 'Overwrite'.
    [Parameter(ValueFromPipelineByPropertyName)]
    [Switch] $Clobber,

    # The name of the system event log, e.g. 'Application'. The Skype for Business log is still called 'Lync Server'. Note that writing to the system event log requires elevated permissions.
    [Parameter(ValueFromPipelineByPropertyName)]
    [ValidateSet('Application', 'System', 'Security', 'Lync Server', 'Microsoft Office Web Apps')]
    [ValidateNotNullOrEmpty()]
    [String] $EventLogName,

    # The name to appear as the source attribute for the system event log entry. This is ignored unless 'EventLogName' is specified.
    [Parameter(ValueFromPipelineByPropertyName)]
    [ValidateNotNullOrEmpty()]
    [String] $EventSource = $([IO.FileInfo] $MyInvocation.ScriptName).Name,

    # The ID to appear as the event ID attribute for the system event log entry. This is ignored unless 'EventLogName' is specified.
    [Parameter(ValueFromPipelineByPropertyName)]
    [ValidateRange(1,65535)]
    [ValidateNotNullOrEmpty()]
    [int] $EventID = 1,

    # The text encoding for the log file. Default is ASCII.
    [Parameter(ValueFromPipelineByPropertyName)]
    [ValidateSet('Unicode','Byte','BigEndianUnicode','UTF8','UTF7','UTF32','ASCII','Default','OEM')]
    [ValidateNotNullOrEmpty()]
    [String] $LogEncoding = 'ASCII'
  ) # end of param block
  BEGIN{} # end BEGIN
  Process{
    try {
      [string]$LogFolder = Split-Path -Path $LogPath -Parent
      if (-not(Test-Path -Path $LogFolder)){
        $null = New-Item -Path $LogFolder -ItemType Directory
      }
      $msg = "{0} : {1} : {2}{3}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level.ToUpper(), ('  ' * $Indent), $Message
      if (-not($NoConsole)){
        switch ($level) {
          'Error' {$Host.UI.WriteErrorLine("$Message")}
          'Warn' {Write-Warning -Message $Message}
          'Info' {Write-Host $Message -ForegroundColor $ConsoleForeground}
          'Verbose' {Write-Verbose -Message $Message}
        }
      }
      if (-not($NoLog)){
        if ($Clobber) {
          $msg | Out-File -FilePath $LogPath -Encoding $LogEncoding -Force
        } else {
          $msg | Out-File -FilePath $LogPath -Encoding $LogEncoding -Append
        }
      }

      if ($EventLogName) {
        if (-not $EventSource) {
          [string] $EventSource = $([IO.FileInfo] $MyInvocation.ScriptName).Name
        }

        if(-not [Diagnostics.EventLog]::SourceExists($EventSource)) {
          [Diagnostics.EventLog]::CreateEventSource($EventSource, $EventLogName)
        }

        switch ($Level) {
          'Error' {$EntryType = 'Error'}
          'Warn'  {$EntryType = 'Warning'}
          'Info'  {$EntryType = 'Information'}
          'Verbose' {$EntryType = 'Information'}
          Default  {$EntryType = 'Information'}
        }
        Write-EventLog -LogName $EventLogName -Source $EventSource -EventId 1 -EntryType $EntryType -Message $Message
      }
      $msg = ''
    } # end try
    catch {
      Throw "Failed to create log entry in: '$LogPath'. The error was: '$_'."
    } # end catch
  } # end PROCESS
  END{} # end END

	<#
		.SYNOPSIS
			Writes logging information to screen and log file simultaneously.

		.DESCRIPTION
			Writes logging information to screen and log file simultaneously. Supports multiple log levels.

		.PARAMETER Message
			The message to be logged.

		.PARAMETER Level
			The type of message to be logged.
			
		.PARAMETER NoConsoleOut
			Specifies to not display the message to the console.
			
		.PARAMETER ConsoleForeground
			Specifies what color the text should be be displayed on the console. Ignored when switch 'NoConsoleOut' is specified.
		
		.PARAMETER Indent
			The number of spaces to indent the line in the log file.

		.PARAMETER Path
			The log file path.
		
		.PARAMETER Clobber
			Existing log file is deleted when this is specified.
		
		.PARAMETER EventLogName
			The name of the system event log, e.g. 'Application'.
		
		.PARAMETER EventSource
			The name to appear as the source attribute for the system event log entry. This is ignored unless 'EventLogName' is specified.
		
		.PARAMETER EventID
			The ID to appear as the event ID attribute for the system event log entry. This is ignored unless 'EventLogName' is specified.

		.PARAMETER LogEncoding
			The text encoding for the log file. Default is ASCII.
		
		.EXAMPLE
			PS C:\> Write-Log -Message "It's all good!" -Path C:\MyLog.log -Clobber -EventLogName 'Application'

		.EXAMPLE
			PS C:\> Write-Log -Message "Oops, not so good!" -Level Error -EventID 3 -Indent 2 -EventLogName 'Application' -EventSource "My Script"

		.INPUTS
			System.String

		.OUTPUTS
			No output.
			
		.NOTES
			Revision History:
				2011-03-10 : Andy Arismendi - Created.
				2011-07-23 : Will Steele - Updated.
				2011-07-23 : Andy Arismendi 
					- Added missing comma in param block. 
					- Added support for creating missing directories in log file path.
				2012-03-10 : Pat Richard
					- Added validation sets to $ConsoleForeground and $EventLogName
					- Changed formatting of $msg so that only $message is indented instead of entire line (looks cleaner)
					- suppressed output when creating path/file
				2017-5-14 : Pat Richard
					- Added -NoLog option to write info just to the console
					- Added -Verbose option to write console output to the verbose handler
					- Added ValidateSet for $encoding
					- Added default value for $EventSource
					- Tweaked the console output when writing an error
	#>
}
