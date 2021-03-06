#Printer Statistic checking script by Henrik Pedersen Åmark

#This script is used to check how many times all printerques on the selected server has been used the latest X months
#First it gets all the events from the remote server's eventlog that are of ID 10 (successful print) and of the type "Print".
#Then it checks for the timestamps and filter away those that are older then X months.
#After the sorting it tries to match the printerque name against the message from the fort log line, if match it adds 1 to a counter and then take next line.
#If it doesnt match, it head to the next line.
#It will also write the statistics to a file.
#You will need admin rights to use this script
#
#Get todays date for creating filenames later
$date = Get-Date -UFormat %Y%m%d

#Finding out what host to check logs from
Write-Host "What server do you want to get the eventlog from?"
$hostname = Read-Host

Write-Host "Getting the eventlog from server"$hostname"."
Write-Host "Please wait... (this might take a few minutes)"

#Get Eventlog from a remote host
$events = gwmi -ComputerName $hostname -query "select * from win32_ntlogevent where logfile='system' and eventcode='10' and sourcename='print'" | Select-Object EventCode, Timegenerated, Message | sort Timegenerated

#Making a variable for the printerports
$printerports = gwmi -computername $hostname Win32_Printer | Select-Object Portname, name

#Converting newest logtimes to DateTime
$newest = [System.Management.ManagementDateTimeConverter]::ToDateTime($events[0].TimeGenerated)
Write-Host "Oldest logentry is from:" $newest

Write-Host "How many months back do you want to check?"
$months = Read-Host

#Checks is the path where the files gonna be added exists, it it dont, it creates it
if ((Test-Path -path $hostname) -ne $True)
{
	New-Item -type directory -path $hostname
}

$counter = 0
$eventcounter = 0

#Taking one printerques at the time
while ($counter -ne ($printerports.count-1))
{
		#Resetting quecounter so we don't get any old results
		$quecounter = 0
		
		#Looping through each line and checking for how old the events are and if they match the current printerquename
		foreach ($line in $events)
			{
				#Converting current the Timegenerated to DateTime
				$current = ([System.Management.ManagementDateTimeConverter]::ToDateTime($line.TimeGenerated))
				
				if ($current -gt $(Get-Date).AddMonths(-$months) -and $line.message -match $printerports[$counter].name)
				{
					#Adding 1 to the counter if it is a match
					$quecounter = $quecounter + 1
					
				}
				else
				{
					#Getting the next line
					$eventcounter = $eventcounter + 1
				}
				
			}
		
		Write-Host -ForegroundColor Green $printerports[$counter].name "has been used $($quecounter) times!"
		
		#Writing to file
		add-content -path $hostname\Statistics_$date.txt -Value "Printerque name: $($printerports[$counter].name)"
		add-content -path $hostname\Statistics_$date.txt -Value "Number of times used: $quecounter"
		Add-content -path $hostname\Statistics_$date.txt -Value " "
	
	#Adds 1 to the counter so the loop ends after all quenames are checked
	$counter = $counter + 1
}
