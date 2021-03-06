#requires -pssnapin VMware.VimAutomation.Core -version 1.0
# Author:  Glenn Sizemore
# URL:	   http`://get-admin.com/blog/?p=47
# Purpose: Move VMware templates
#
# Usage:   move-VMTemplate -targetpool "pool1" -targethost "ESX1.localdomain.local"
#          Will move Every Template in VIVC to ESX1.
#
#	   move-VMTemplate -template win2k3_x86_ENT -targetpool pool1 -targethost ESX1.localdomain.local -targetfolder win_templates
#	   Will move win2k3_x86_ENT template onto ESX1, and into win_templates
param(
      $template,
      [string]$targetpool = "pool1",
      [string]$targetHost = "ESX1.localdomain.local",
      [string]$targetFolder = "Templates"
     )

# This is not bulletproof because $DefaultVIServer is not nulled
# when the connection is either manually disconnected or times out.
#
# That being said, this will prompt for connection if your current
# Session has never connected to VIVC.

if (-not $DefaultVIServer) {Connect-VIServer}

# get the moref for the Target Resource pool
# NOTE: MoRef is VMware's equivalent of a GUID
$targetPoolMoRef = (get-cluster $targetpool  | Get-ResourcePool | get-view).MoRef

# gets the moref for the Target ESX Host
$targethostMoRef = (get-VMHost $targetHost  | get-view).MoRef

# gets the moref for the Target Folder
$TargetFolderMoRef = (Get-Folder Templates | Get-View).MoRef

# gets the moref for every template registered in Virtual center.
foreach ($template in (Get-Template $template | get-view))
{
	#when we convert the template into a VM we will move it into 
	#the target resource pool / host
	$template.MarkAsVirtualMachine($targetPoolMoRef,$targethostMoRef)
	
	# Convert the VM back into a template
	$template.MarkAsTemplate()

	# Move that template into the target folder	
	$TargetFolder.MoveIntofolder($TargetFolderMoRef)
}
