#PrinterChecking Script By Henrik Pedersen Åmark and Daniel Lundgren

#This script is designed to check what printers that is still in use.
#It's assumed the printer is classed as inactive if it hasnt been used in X months
#The script is reading the Systemlog on a printserver of your choice, the one you type in the hostname for,
#sorting the log on eventID 10 (successful print) and searching for entries the latest 6 months.
#When its done it gets printer ports and ques from the same server and then compare them to the messageline from the eventlog.
#And then checking if the mportname of is in the message.
#If it is, it will write the name to a file and if not it will write the name to another file.

#You will need admin rights to use the script.

$date = Get-Date -UFormat %Y%m%d
#Finding out what host to check logs from
Write-Host "What server do you want to get the eventlog from?"
$hostname = Read-Host

Write-Host "Getting eventlog from remote server "$hostname". Please wait..."
Write-Host "Please wait... (this might take a few minutes)"

#Get Eventlog from a remote host
$events = gwmi -ComputerName $hostname -query "select * from win32_ntlogevent where logfile='system' and eventcode='10' and sourcename='print'" | Select-Object EventCode, Timegenerated, Message | sort Timegenerated

#Making a variable for the printerports
$printerports = Get-WmiObject -computername $hostname Win32_Printer | Select-Object Portname, DeviceID, __server, name

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

while ($counter -ne ($printerports.count-1))
{
	$foundprinted = 0

	#Looping through each line and checking for how old the events are and if they match the current printerquename
	foreach ($line in $events)
	{
		#Converting Timegenerated to DateTime
		$current = ([System.Management.ManagementDateTimeConverter]::ToDateTime($line.TimeGenerated)) 
		
		#Checking each line for beeing less then X months and has quename in the message
		if ($current -gt $(Get-Date).AddMonths(-$months) -and ($line.message -match $printerports[$counter].name ))
		{
			$foundprinted = 1
		}
	}
	
	if ($foundprinted) 
	{
		write-host -ForegroundColor Green $printerports[$counter].name"is in use!" 
		
		#Writing to a file
		add-content -path $hostname\Validprinters_$date.txt -Value $printerports[$counter].name
	}
	else 
	{
		#Writing to another file
		write-host -ForegroundColor red $printerports[$counter].name "is not in use!"
		add-content -path $hostname\Invalidprinters_$date.txt -Value $printerports[$counter].name
	}
	
	#Adds 1 to the counter so the loop ends after all quenames are checked
	$counter=$counter+1
}

