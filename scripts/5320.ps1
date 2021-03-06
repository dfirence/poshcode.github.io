########################################################################################################
#                                                                                                     
#                     Powershell Script for vSphere Syslog Collector
# 
# Uses IP address from directories created for each esxi host to do a DNS lookup and create shortcuts
# for for those folders based on the returned DNS of the esxi host 
# http://vspherepowershellscripts.blogspot.com.au/2014/07/test.html                                                                                                  
########################################################################################################


Function ReverseDNS
{
	$nslookup = "nslookup " + $args[0] + " " + $ns + " 2> null"
	$result = Invoke-Expression ($nslookup) 
	$global:reverse_solved_ip = $result.SyncRoot[3]

	# If nslookup returns no result set variable to 'No record found'
	if ($result.count -lt 4) 
	{
		$global:reverse_solved_ip = "No record found"
	}
	else
	{
		#Trim off the first 9 charactors from the start this removes the 'Name:' from the output
		$global:reverse_solved_ip = $global:reverse_solved_ip.Remove(0,9)
	}
}

# Name Server which will do name resolution
$ns = "dns.server.com"

#Root path of log folders (always include the trailing backslash)
$folderpath = "C:\ProgramData\VMware\VMware Syslog Collector\Data\"

# Create array of folder names to feed into ReverseDNS function
$foldername = Get-ChildItem $folderpath | Where-Object {$_.PSIsContainer} | Foreach-Object {$_.Name}

# Loop through each folder name
Foreach ($ip in $foldername){
	
	
	# Feed IP address into ReverseDNS function
	ReverseDNS $ip
	
	#Write some output so you can see what is going on
	Write-Host $ip
	Write-Host $reverse_solved_ip
	Write-Host ""
	
	
	
	# For all records in array that do not contain 'No record found' 
	if ($reverse_solved_ip -ne "No record found") {
		
		#Create Shortcut
		$target = $folderpath + $ip
		$shortcut = $folderpath + $reverse_solved_ip + ".lnk"
		$wshshell = New-Object -ComObject WScript.Shell
		$link = $wshshell.CreateShortcut($shortcut)
		$link.TargetPath = $target
		$link.Save()
	}
}
