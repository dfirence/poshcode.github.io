#===================================================================================
#
#	Filename:	AddExecuteInPowerShellToPS1Files.ps1
#
#	Author:		Nigel Boulton
#
#	Version:	1.00
#
#	Date:		9 Nov 2008
#
#	Mod dates:	
#
#	Purpose:	To add context menu items for .ps1 files in Windows Explorer, to
#				allow PowerShell scripts to be executed by right-clicking them
#
#	Action:		Gets the path to PowerShell.exe by reading the Path property of
#				the process. If PowerShell is not running (e.g. if using a GUI/IDE),
#				prompts the user to	enter the path. Quotes the path if it contains
#				any spaces
#				Gets the class key for .ps1 files from the registry and adds the
#				appropriate subkeys and values to it to add "Execute in PowerShell"
#				and "Execute in PowerShell (-NoExit)" context menu items
#
#	Notes:		USE AT YOUR OWN RISK! Backup your system first and all that...
#				Must be run as an administrator
#
#===================================================================================

# Get the full path to PowerShell.exe, or prompt if using a GUI
$PoSH = Get-Process | Where-Object {$_.Name -eq "PowerShell"} | Select-Object -First 1
If ($PoSH -eq $null) {
	$PoSHPath = Read-Host "Please enter the full path to PowerShell.exe, or cancel and run this script in a PowerShell console session"
	If ($PoSHPath -eq $Null) {exit 1}
	}
Else
	{
	$PoSHPath = $PoSH.Path
}

# Quote PowerShell path if it isn't already
If ($PoSHPath.Substring(0,1) -ne "`"") {$PoSHPath = "`"" + $PoSHPath}
If ($PoSHPath.Substring($PoSHPath.Length - 1,1) -ne "`"") {$PoSHPath += "`""}

# Get class for .ps1 files
$PS1Class = (Get-ItemProperty -Path HKLM:SOFTWARE\Classes\.ps1)."(Default)"

# Build hash table of registry data to add
# $_.Name is the registry key and $_.Value is the data for the "(Default)" value in that key
$RegData = @{"HKLM:Software\Classes\$PS1Class\shell\Execute in PowerShell\command" = $PoSHPath + " &'%1'";`
			 "HKLM:Software\Classes\$PS1Class\shell\Execute in PowerShell (-NoExit)\command" = $PoSHPath + " -NoExit &'%1'"}

# Check for an existing "Open" action. If there isn't one we need to add one in to ensure that "Open"
# remains the default. If we didn't do this, in future double-clicking .ps1 files would execute them!
If ((Test-Path "HKLM:Software\Classes\$PS1Class\shell\open\command") -eq $False) {$RegData.Add("HKLM:Software\Classes\$PS1Class\shell\open\command", "notepad.exe `"%1`"")}

# Iterate hash table to create registry keys and set values
$RegData.GetEnumerator() | ForEach-Object {
	# Create registry path
	If ((Test-Path $_.Name) -eq $False) {New-Item -Path $_.Name -Force | Out-Null}
	# Set "(Default)" value
	Set-ItemProperty -Path $_.Name -Name "(Default)" -Value $_.Value
}
Write-Output "Processing complete"
