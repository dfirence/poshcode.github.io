#requires -pssnapin VMware.VimAutomation.Core
# http://get-admin.com/blog/?p=342
#Get any cluster that has DPM Enabled
$Clusters = @()
$Clusters += Get-Cluster -verbose:$false | Where-Object { (Get-View -VIObject $_  -verbose:$false).ConfigurationEx.DpmConfigInfo.Enabled }
Write-Verbose "$(get-date -uformat %T) Found $($Clusters.Count) DPM Enabled DRS Clusters  ..."
 
Foreach ($cluster in $Clusters) {
    Write-Verbose "$(get-date -uformat %T) Processing $($Cluster.Name) Cluster"
    #Get any hosts that have a state of disconnected
    $VMHosts = @()
    $VMHosts = $cluster | Get-VMHost -verbose:$false | Where-Object { $_.State -eq "NotResponding" }
    Write-Verbose "$(get-date -uformat %T) Found $($VMHosts.Count) Suspended Hosts"
    #Wake 'em up!
    Foreach ($VMHost in $VMHosts){
        #Get the mac address of any WOL enabled Pnic
        $VMHostNetworkSystem = (Get-view -VIObject $VMHost -verbose:$false).ConfigManager.NetworkSystem
        $Pnics = (Get-view -ID $VMHostNetworkSystem -verbose:$false).NetworkInfo.Pnic | Where-Object {$_.WakeOnLanSupported}
        #Send the WOL Majic Packet...
        Foreach ($Pnic in $Pnics) {
            $MAC = $Pnic.Mac.split(':') | %{ [byte]('0x' + $_) }
            $UDPclient = new-Object System.Net.Sockets.UdpClient
            $UDPclient.Connect(([System.Net.IPAddress]::Broadcast),4000)
            $packet = [byte[]](,0xFF * 6)
            $packet += $mac * 16
            [void] $UDPclient.Send($packet, $packet.Length)
            Write-Verbose "$(get-date -uformat %T) Magic Packet sent to $($VMHost.Name) $($Pnic.Device)"
        }
    }
}

