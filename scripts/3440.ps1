@@---------------------logoff_clientside_interactive.ps1-----------------
#powershell -ExecutionPolicy Unrestricted logoff_clientside_interactive.ps1
$ErrorActionPreference = "silentlycontinue"
$mycreds = (Get-Credential)
Invoke-Command  -ComputerName terminalserver -Credential $mycreds  {
&"C:\Program Files\internal\logoff_serverside.ps1"
}
@@---------------------logoff_clientside_interactive.ps1-----------------
or even simpler
@@---------------------logoff_clientside_same_user.ps1-------------------
$ErrorActionPreference = "silentlycontinue"
Invoke-Command  -ComputerName terminalserver {
&"C:\Program Files\internal\logoff_serverside.ps1"
}
@@---------------------logoff_clientside_same_user.ps1-------------------


@@---------------------logoff_serverside.ps1-----------------------------
# http://psterminalservices.codeplex.com/ - Powershell Module for Terminalserver
# http://blogs.technet.com/b/heyscriptingguy/archive/2011/01/05/simplify-desktop-configuration-by-using-a-shared-powershell-module.aspx
# Module installation to %windir%\System32\WindowsPowerShell\v1.0\Modules
# activate Powershell remoteing for non-Administrators
# Set-PSSessionConfiguration -Name Microsoft.PowerShell -showSecurityDescriptorUI -force
# add remote desktop users

Import-module PSTerminalServices
$myId=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$data=$myID.name.split('\')
$data=$data[1]
Get-TSSession -ComputerName localhost -Filter {$_.Username -eq $data}  | Stop-TSSession –Force
@@---------------------logoff_serverside.ps1-----------------------------
