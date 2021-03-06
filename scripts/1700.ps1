 # ============================================================================================== 
 # 
 #
 # NAME: Export-WLANSettings.ps1
 # 
 # AUTHOR: Jan Egil Ring
 #
 # DATE  : 14.03.2010 
 # 
 # COMMENT: Using netsh.exe to loop through each WLAN on the system and export the settings to the user-provided output-file.
 #          Must be run with Administrator-privileges for the Key Content (security key) to be exported.
 # 
 # 
 # ============================================================================================== 

Write-Warning "Must be run with Administrator-privileges for Key Content to be exported"
$filepath = Read-Host "Provide path to output-file. E.g. C:\temp\wlan.txt"

$wlans = netsh wlan show profiles | Select-String -Pattern "All User Profile" | Foreach-Object {$_.ToString()}
$exportdata = $wlans | Foreach-Object {$_.Replace("    All User Profile     : ",$null)}
$exportdata | ForEach-Object {netsh wlan show profiles name="$_" key=clear} | Out-File $filepath
