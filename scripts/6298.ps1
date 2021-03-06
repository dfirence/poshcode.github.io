function Install-Software{
#.Synopsis
#  Install software from a UNC path to a remote computer
#.Description
#  This script allows an administrator to install software from either a local folder on their administration PC or
#  from a network share. Target computers to receive the installation are defined ahead of time in a text file.
#
#  The specified installer is copied locally to the C:\TEMP folder of each of the target computers and an installer
#  process is initiated locally on each target. Arguments for the installer file can be provided and are optional.
#.Parameter Targets
#  Input file of target computers. The file should be a plain text file with one target system on each line.
#.Parameter Install
#  The UNC path to the executable file. Arguments are listed separately and should not be specified here.
#.Parameter Arguments
#  Arguments for the executable.
#.Example
#  Install-Software -Targets .\computers.txt -Install "\\MyServer\MyShare\Folder\setup.exe" -Arguments "/V/qn NoRestart"
#
#  Description
#  -----------
#  Copies setup.exe from \\MyServer\MyShare\Folder to each of the target computers listed in computers.txt and initiates
#  setup.exe with the arguments "/V/qn NoRestart".
#.Example
#  Install-Software -Targets "\\MyServer\MyShare\Targets\computers.txt" -Install "E:\Folder\install.exe"
#
#  Description
#  -----------
#  Copies install.exe from E:\Folder on the local computer to each of the target computers listed in computers.txt and
#  initiates install.exe with no arguments.

[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')] 
param( 
	[parameter(Mandatory = $true, Position = 0)] 
	[string]$Targets,
	[parameter(Mandatory = $true, Position = 1)] 
	[string]$Install,
	[parameter(Mandatory = $false, Position = 2)] 
	[string]$Arguments
) 

# Get target computer list
$Computers = Get-Content $Targets
$InstallString = "$Install $Arguments"

foreach ($Computer in $Computers) {
	Copy-Item "$Install" \\$Computer\c$\TEMP
	
	Invoke-Command -ComputerName $Computer -ScriptBlock {
		Start-Process "$InstallString"}
}

