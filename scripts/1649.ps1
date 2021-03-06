#
# NAME
#   Select-CSVString
#
# SYNOPSIS
#   Convert CSV files to custom objects with properties
#
# SYNTAX
#   Select-CSVString -pattern <string[]> -files (ls *) [-StartDate <DateTime>] [-EndDate <DateTime>]

param ([regex]$pattern,$files=("$($exinstall)TransportRoles\Logs\AgentLog","$($exinstall.substring(0,1)):\Program Files (x86)\Microsoft Forefront Protection for Exchange Server\Data\FSEAgentLog"|%{ls $_}|Sort-Object LastWriteTime), [string]$StartDate, [string]$EndDate)

# Check start and end dates
$local:erroractionpreference = "Stop"
If(!$StartDate -and !$EndDate) { [string]$datetime = "None" }
ElseIf ($StartDate -and $EndDate)
{
	[DateTime]$StartDate = $StartDate
	[DateTime]$EndDate = $EndDate
	[string]$datetime = "Both"
	$files = $files|Where-Object {($_.CreationTime -ge $StartDate -or $_.LastWriteTime -ge $StartDate) -and $_.CreationTime -le $EndDate}
}
ElseIf ($StartDate -and !$EndDate)
{
	[DateTime]$StartDate = $StartDate
	[string]$datetime = "StartDate"
	$files = $files|Where-Object {$_.CreationTime -ge $StartDate -or $_.LastWriteTime -ge $StartDate}
}
ElseIf (!$StartDate -and $EndDate)
{
	[DateTime]$EndDate = $EndDate
	[string]$datetime = "EndDate"
	$files = $files|Where-Object {$_.CreationTime -le $EndDate -or $_.LastWriteTime -le $EndDate}
}
$local:erroractionpreference = "Continue"

# Get columns
$columns = @($files)[0]|Get-Content -TotalCount 5

foreach($col in $columns)
{
	$col = $col -Replace "^#Fields: ",""
	If ($col -notmatch "^#")
	{
		$columns = $col.Split(',')
		break
	}
}

# Get Results
foreach($file in $files)
{
	Write-Debug "File: $($file.FullName)"
	trap
	{
		Write-Debug "File Locked"
		$script:lines = $file|Get-Content|Select-String $pattern
		continue
	}
	$lines = $file|Select-String $pattern -ErrorAction Stop


	foreach($l in $lines) {
		Write-Debug "Line: $($l.Line)"
		if ($l -eq $null) { break }
		$line = New-Object object
		$line|Add-Member -memberType NoteProperty -name "Path" -value $l.Path

		# ---------- Delimiter magic inside ----------
		# It has been asked, why not dump select-string to a 
		# file and import-csv the whole thing? To get realtime
		# results and avoid temporary files, thats why.

		$z = [char](222)
		$from = ","

		$tmp = $l.Line -replace "(?:`"((?:(?:[^`"]|`"`"))+)(?:`"$from|`"`$))|(?:$from)|(?:((?:.(?!$from))*.)(?:$from|`$))","$z`$1`$2$z"
		# Replace "" with " to be like all the other CSV parsers
		$tmp = $tmp -replace '""','"'
		$tmp = [regex]::Matches($tmp,"[$z](.*?)[$z]")
		$row = @()
		$tmp | foreach { $row += $_.Groups[1].Value }
		# ---------- Delimiter magic inside ----------

		0..($columns.Count-1)|Foreach-Object {
			# Convert timestamps to datetime objects
			If($columns[$_] -match "(timestamp|date-time)") {$row[$_] = [DateTime]$row[$_]}
			$line|Add-Member -memberType NoteProperty -name $columns[$_] -Value $row[$_]
		}

		# Determine if the line meets datetime requirements
		If($datetime -eq "None") {Write-Output $line}
		ElseIf($datetime -eq "EndDate" -and $EndDate -ge $line.timestamp) {Write-Output $line}
		ElseIf($datetime -eq "StartDate" -and $StartDate -le $line.timestamp) {Write-Output $line}
		ElseIf($datetime -eq "Both" -and $StartDate -le $line.timestamp -and $EndDate -ge $line.timestamp) {Write-Output $line}
	}
}

