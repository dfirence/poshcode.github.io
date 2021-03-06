
function Copy-Robocopy
{
	param
	(
		[Parameter(Position=0, Mandatory=$true)]
		[String] $Source,
		
		[Parameter(Position=1, Mandatory=$true)]
		[String] $Target,
		
		[Parameter(Position=2, Mandatory=$false)]
		[String[]] $Files = @("*.*"),
		
		[Parameter(Position=3, Mandatory=$false)]
		[String] $Options = ""
	)
	
	# Result
	$Result = @{
		"Params" = @{}
		"Timing" = @{}
		"Result" = @{}
	}
	
	# Define Log File
	$LogFile = $ENV:TEMP + "\Robocopy." + (Get-Date -UFormat "%Y%m%d.%H%M%S") + "." + (Get-Random -Minimum 1000 -Maximum 9999) + ".log"
	
	# Remove Wrong Options
	$Options = $Options.Replace('/NJH', "")
	$Options = $Options.Replace('/NJS', "")
	
	# Start Process
	$Duration = Measure-Command { Start-Process -FilePath 'ROBOCOPY' -ArgumentList ('"' + $Source + '" "' + $Target + '" "' + [String]::Join('" "', $Files) + '" ' + $Options) -RedirectStandardOutput $LogFile -NoNewWindow -Wait }
	
	# Import Robocopy Log
	$Robocopy = Get-Content -Path $LogFile
	
	# Line Numbers
	$LineHeaderFirst = (0..($Robocopy.Count - 1) | Where-Object { $Robocopy[$_] -eq "-------------------------------------------------------------------------------" })[0]
	$LineHeaderLast  = (0..($Robocopy.Count - 1) | Where-Object { $Robocopy[$_] -eq "------------------------------------------------------------------------------" })[0]
	$LineFooterFirst = (($Robocopy.Count - 1)..0 | Where-Object { $Robocopy[$_] -eq "------------------------------------------------------------------------------" })[0]
	$LineFooterLast  = ($Robocopy.Count - 1)
	
	# Result Params
	$Result["Params"]["Source"]  = ([String]($Robocopy[$LineHeaderFirst + 5].Split(":", 2)[1].Trim()))
	$Result["Params"]["Target"]  = ([String]($Robocopy[$LineHeaderFirst + 6].Split(":", 2)[1].Trim()))
	$Result["Params"]["Files"]   = ([String]::Join(", ", (($LineHeaderFirst + 8)..($LineHeaderLast - 4) | ForEach-Object { $Robocopy[$_].Split(":", 2)[-1].Trim() })))
	$Result["Params"]["Options"] = ([String]($Robocopy[$LineHeaderLast - 2].Split(":", 2)[1].Trim()))
	
	# Result Timing
	$Result["Timing"]["Duration"] = ([String]($Duration))
	$Result["Timing"]["Started"]  = ([String](Get-Date -Date $Robocopy[$LineHeaderFirst + 4].Split(":", 2)[1].Trim()))
	$Result["Timing"]["Ended"]    = ([String](Get-Date -Date $Robocopy[$LineFooterLast - 1].Split(":", 2)[1].Trim()))
	
	# Result Result
	for ($Line = ($LineFooterFirst + 3); $Line -le ($LineFooterFirst + 6); $Line++)
	{
		$Key = $Robocopy[$Line].Substring(02,07).Trim()
		$Result["Result"][$Key] = @{}
		
		for ($Col = 10; $Col -le 60; $Col += 10)
		{
			$Title = $Robocopy[$LineFooterFirst + 2].Substring($Col, 10).Trim()
			$Title = $Title.Substring(0,1).ToUpper() + $Title.Substring(1).ToLower()
			
			$Result["Result"][$Key][$Title] = $Robocopy[$Line].Substring($Col, 10).Trim()
		}
	}
	
	# Return
	return $Result
}

