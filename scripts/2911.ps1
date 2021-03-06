#######################################################################################################################
# File:             ESXiMgmt_search_for_guest_hostname_sample.ps1                                                     #
# Author:           Alexander Petrovskiy                                                                              #
# Publisher:        Alexander Petrovskiy, SoftwareTestingUsingPowerShell.WordPress.Com                                #
# Copyright:        © 2011 Alexander Petrovskiy, SoftwareTestingUsingPowerShell.WordPress.Com. All rights reserved.   #
# Prerequisites:    The module was tested with Vmware ESXi 4.1 U1 on the server side and                              #
#                       Vmware PowerCLI 4.1 U1                                                                        #
#                       plink.exe 0.60.0.0                                                                            #
# Usage:            To load this module run the following instruction:                                                #
#                       Import-Module -Name ESXiMgmt -Force                                                           #
#                   Please provide feedback in the SoftwareTestingUsingPowerShell.WordPress.Com blog.                 #
#######################################################################################################################
param([string]$Server,
	  [string]$User,
	  [string]$Password,
	  [string]$DatastoreName,
	  [string]$Drive
	  )
# USAGE: .\ESXiMgmt_search_for_guest_hostname_sample.ps1 192.168.1.1 root 123 datastore3 host1ds3

cls
Set-StrictMode -Version Latest
Import-Module ESXiMgmt -Force;

Connect-ESXi -Server $Server -Port 443 `
	-Protocol HTTPS -User $User -Password $Password `
	-DatastoreName $DatastoreName -Drive $Drive;

$vmname = Get-ESXiVMName -VMHostname 'B45E19A64B5E418'
Write-Host "Guest host $($vmname) corresponds to $($vmname)";

$hostnames = @(
			'1-0028687D9BSP3',
			'1-07B328CA254D4',
			'1-081D88F5DF2D4',
			'1-10BF79C694094',
			'1-15DB4C70F57B4',
			'1-1B154BAE5CD84',
			'1-1D33859002954',
			'1-3502988189C24',
			'1-3A324DA9EBE54',
			'1-9160383452304',
			'1-96B95B980BDE4',
			'1-B3F725FTYE56',
			'1-E49B84B0A4AA4',
			'1-FECEC772CBB74'
			);
			
$vmnamesFromHostnames = Get-ESXiVMName -VMHostname $hostnames;
		
for ($private:i = 0; $private:i -lt $vmnamesFromHostnames.Length; $private:i++)
{
	Write-Host "Guest host $($hostnames[$private:i]) corresponds to $($vmnamesFromHostnames[$private:i])";
}
			
