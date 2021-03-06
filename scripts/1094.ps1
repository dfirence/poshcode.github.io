# First, start asynchronous tools update. We need to do it in a separate process
# because the update is a beta version which contains unsigned drivers and will
# be blocked by Windows' driver confirmation prompt
$updateScript = "
Add-PSSnapin VMware.VimAutomation*
Connect-VIServer $DefaultVIServer
Get-VM 'OldVMTools' | Update-Tools
"

# Start the parallel process
[System.Diagnostics.Process]::Start('powershell.exe', $updateScript)

# This script will be executed inside the VM's guest OS.
# Note that WASP is preinstalled on the VM to keep the script simpler.
$confirmationScript = "
Add-PSSnapin WASP

# VMware tools includes multiple drivers so we need to click many times
for (`$i = 0; `$i -lt 5; ) {
	# In WASP, you usually find windows with Select-Window. The driver
	# confirmation is a bit strange though so we need to use Select-Control.
	# '-Window 0' means the desktop
	`$driverConfirmationWindow = `
         Select-Control -Window 0 -Recurse -Title 'Hardware Installation'
	
	if (`$driverConfirmationWindow -ne `$null) {
		`$driverConfirmationWindow |
		    Select-Control -title '&Continue Anyway' | Send-Click
		`$i++;
	}
	
	Start-Sleep 5;
}
"

#Send confirmation script to the guest
Invoke-VMScript `
    -vm 'OldVMTools' -guestUser 'user1' -guestPassword 'pass1' `
    -hostUser 'root' -hostPassword 'pass2' -script $confirmationScript

