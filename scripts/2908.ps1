#######################################################################################################################
# File:             ESXiMgmt_machines_generation_sample.ps1                                                           #
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
	  [string]$Drive,
	  [int]$MachinesNumber,
	  [string]$MachinePrefix,
	  [int]$OperationTimeout
	  )
# USAGE: .\ESXiMgmt_machines_generation_sample.ps1 192.168.1.1 root 123 datastore3 host1ds3 100 XPSP2_ 300

cls
Set-StrictMode -Version Latest
Import-Module ESXiMgmt -Force;

Connect-ESXi -Server $Server -Port 443 `
	-Protocol HTTPS -User $User -Password $Password `
	-DatastoreName $DatastoreName -Drive $Drive;
	
# This is to test can or can't plink.exe connect to your server
# The answer you need to select in case it questions is obviously Yes.
Invoke-ESXiCommand -Server $Server `
	 -User $User -Password $Password `
	 -Command 'ls ~; sleep 10s; exit;' -PathToPlink 'C:\VMTests\plink.exe' `
	 -ShowWindow $true -OperationTimeout 10;

New-ESXiVMs -TemplateVMName 'template XP SP2 Sv 2' -Count $MachinesNumber `
		-Logname "C:\VMTests\xpsp2\100.txt" -NewVMName $MachinePrefix `
		-BasePath 'C:\VMTests\xpsp2' -OperationTimeout $OperationTimeout;
