
# The $test variable can be pretty much whatever you want it to be, or with a little adjustment it isn't even necessary.
# I just wanted to set it up like this for the $match variable later on
$test=(get-folder testing|get-vm)

#$data and the csv is where all the information lies that this script/s pulls
$data=import-csv book1.csv


$hostcredential=Get-Credential "Host Credentials"
$guestcredential=Get-Credential "Guest Credentials"

#Line row, row line, same thing in a spreadsheet. I just wish I knew more of those basic understood variables such as $line.
# If anyone knows a good listing please let me know
foreach ($line in $data)
{
#For each of the VMs in $test it checks to see if there is a listing for that vm name in the excel spreadsheet.
$match=$test|?{$line.guestname -eq $_.name}

	IF($match)
	{
	#Oh invoke-vmscript how I both love and hate you. This calls for the execution of the script works2.ps1 script locally on the remote computer
	invoke-vmscript -vm $match.name -scripttext '&"C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" "C:\Power\works2.ps1"' -scripttype "powershell" -hostcredential $hostcredential -guestcredential $guestcredential -confirm
	}

}
