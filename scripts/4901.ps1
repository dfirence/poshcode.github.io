# DuserLremove.ps1
# Removes a domain user from local admin group on a list of servers
# Qodosh
# 2.15.2014 v1.1
#
# The path to your server lists between the quotes. Use FQDN in your server list. Will add conversion.
$Servers = Get-Content 'C:\servers.txt'
# The domain and user you want to remove. Don't really need this but it makes it easier.
$userToRemove = "DOMAIN/USER"
# Loops through the servers in the list
foreach ($Server in $Servers){
# This selects the computer and each time it loops it is a different computer
    $computer = [ADSI]("WinNT://$Server,computer")
# This just tells you what is going on 
    $Server
# Finds the group
    $group = $computer.psbase.children.find("Administrators")
# This just tells you what is going on 
    $group
# Removes the user
    $group.Remove("WinNT://$userToRemove")
}



