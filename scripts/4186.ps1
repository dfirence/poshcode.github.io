function Get-NetView  {
	param($Computer)
	
	$Result = @()
	$ses = NET.EXE VIEW $Computer

	$ColLength = -1
	$start = -1
	for($i = 0; $i -lt $ses.Count;$i++)
	{
		$temp =$null
		$temp = $ses[$i]
		if($temp -like "-----------------*")
		{
			#Start Parse
			$start = $i+1
		}
		if($temp -eq "The command completed successfully.")
		{
			#End Parse
			$start = -1
		}
		if($temp -like "Share name*Type*")
		{
			#Determine Length

			$end = $temp.IndexOf("Type")
			$ColLength = $end
		}
		
		if($i -ge $start -and $start -ne -1)
		{
			#Find Share
			$parts =$temp.Substring(0,$ColLength)
			$share = ("\\" + $Computer + "\" + $parts.Trim())
			
			$obj = New-Object PSObject
			$obj | Add-Member -MemberType NoteProperty -Name "Share" -Value $share
			$Result += $obj
		}
	}
	
	
	return $Result
}
#Usage	
Get-NetView DFSROOT01 | ft -AutoSize
