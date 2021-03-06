[CmdletBinding()]
Param(
	[Parameter(Mandatory=$True,Position=1)]
	[string]$logDirectory,
	
	[Parameter(Mandatory=$False)]
	[int]$monthThreshold = 1
)

if ([string]::IsNullOrEmpty($logDirectory))
{
	Throw New-Object System.ArgumentNullException "Path must be supplied.";
}

if ($logDirectory.EndsWith("\"))
{
	Throw New-Object System.ArgumentException "Path must not have a trailing backslash.";
}

$threshold = (Get-Date -Hour 0 -Minute 0 -Second 0 -Day 1).AddMonths(-$monthThreshold);
Write-Host "The threshold is: $($threshold.ToString("yyyy-MM-dd")). Logs older than the treshold will be archived.";

$dataList=@();
Get-ChildItem -Path $logDirectory | 
	Where { $_.Extension -eq ".log" -and $_.LastWriteTime -lt $threshold } | 
	% `
	{
		$temp = '' | Select FileName, Period
		$temp.FileName = """" + $_.FullName + """";
		$temp.Period = '{0:MM-yyyy}' -f $_.LastWriteTime;
		$dataList += $temp
	}

$uniquePeriods = $dataList | Select Period -unique;
foreach ($period in $uniquePeriods)
{
	$fileList = $dataList | 
		Where-Object { $_.Period -eq $period.Period } | 
		Select -expand FileName;
		
	$argumentList = "a -y -t7z -sdel ""$($logDirectory)\$($period.Period).7z"" $fileList";
	Start-Process '7za.exe' -argumentlist $argumentlist -NoNewWindow -wait;
}

