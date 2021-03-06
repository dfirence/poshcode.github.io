<#
====================================================================
Author(s):	Josh Atwell <josh.c.atwell@gmail.com>
Link:		www.vtesseract.com
File: 		Get-UCSServiceProfileAssociations-FromList.ps1
Purpose: 	Gets Service Profile Associations for all UCS clusters
		provided in a list.
				
		If you want to view the Serivce Profile associations for
		a single UCSM you can use the following one-liner:
				
		Get-UcsServiceProfile | Select Ucs, Name, PnDn | Sort UCS,PnDn
 
Date:		2012-10-01
Revision: 	1
 
References:	Written using UCSPowerTool 0.9.90
		Requires Cisco UCSPowerTool

====================================================================
Disclaimer: This script is written as best effort and provides no 
warranty expressed or implied. Please contact the author(s) if you 
have questions about this script before running or modifying
====================================================================
#>


#	Load UCSPowerTool Module if needed
If ((Get-Module "CiscoUCSPS" -ErrorAction SilentlyContinue) -eq $null) {
Write-Output "UCSPowerTool Module not loaded.  Attempting to load UCSPowerTool"
Import-Module "C:\Program Files (x86)\Cisco\Cisco UCS PowerTool\Modules\CiscoUcsPS\CiscoUcsPS.psd1"
}

# Prepopulated Data
# Enter data and remote # comment character to use
#$sourcelist =  Get-Content "C:\Josh\Temp\2012-09-29.txt"
#$destinationfile = "C:\Josh\Temp\ServiceProfiles_2012-09-29_b.csv"

# User prompts if data is not prepopulated above
If ($sourcelist -eq $null){
$sourcelist = Get-Content (Read-Host "Please enter path to file with list of UCSMs (.txt)")
}
If ($destinationfile -eq $null){
$destinationfile = Read-Host "Please enter file path and name for the output (.csv).  If left blank no output file will be created."
}

# Prompts and stores user credentials
$cred = Get-Credential

Set-UcsPowerToolConfiguration -SupportMultipleDefaultUcs $true

$AllUCS = $sourcelist
Connect-UCS $AllUCS -Credential $cred
$report = Get-UcsServiceProfile | Select Ucs, Name, PnDn | Sort UCS,PnDn

Write-Output $report

# Will export to CSV
If ($destinationfile -ne $null){
$report | Export-CSV $destinationfile -NoTypeInformation
}
Disconnect-UCS

# Clears the $cred variable for security purposes
Clear-Variable cred

If ((Read-Host "Do you want to disconnect the CiscoUCSPS module? (Y/N)") -eq "Y"){
Remove-Module "CiscoUCSPS"
}Else{
Write-Output "Did not disconnect CiscoUCSPS module.  You can do so manually with Remove-Module 'CiscoUCSPS'"
}
