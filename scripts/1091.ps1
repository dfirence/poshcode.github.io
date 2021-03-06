#The PowerShell Talk
#Virtualization Congress 2009
#
#The Chicken Counter Script

#Get our cretendials 
#More on credential stores: http://professionalvmware.com/2009/04/09/posh-article-of-the-week-secure-credential-storage/
$credentials = Get-VICredentialStoreItem -File "c:\scripts\really_secure_file.xml"

#Setup Our Counters
$datacenters = @{
    Name = "Datacenters"
    Expression = { Get-Datacenter | Measure-Object}
}
$hosts = @{
    Name = "Hosts"
    Expression = { Get-VMHost | Measure-Object }
}
$vms = @{
    Name = "VMs"
    Expression = { Get-VM | Measure-Object }
}
$clusters = @{
    Name = "Clusters"
    Expression = { Get-Cluster | Measure-Object }
}

#Connect to each vCenter in the credentials file
ForEach ($creds in $credentials) {
	
	#Connect, Count, Disconnect
	connect-viserver -Server $creds.Host -User $creds.User -Password $creds.Password
	$output = $datacenter | Select-Object $datacenters, $hosts, $vms, $clusters
	disconnect-viserver -confirm:$false
    
	#Add this to the mail
	$Body += "`nvCenter: " + $creds.Host
	$Body += "`nDatacenters: " + $output.Datacenterss.count
    $Body += "`nHosts: " + $output.Hosts.Count
    $Body += "`nVMs: " + $output.VM.Count
    $Body += "`nClusters: " + $output.Clusters.Count
    
	#Totals
	$totalHosts += $output.Hosts.count
	$totalVM += $output.VM.count
	$totalDatacenters += $output.Datacenters.count
	$totalClusters += $output.Clusters.count
}

#Setup & Send our Mail
$SmtpClient = new-object Net.Mail.SmtpClient("localhost")
$From = "The Farm Hand <chicken_counter@professionalvmware.com>"	#Change these for your environment
$To = "Your Pointy Haired Boss <The_Boss@professionalvmware.com>"	#Change these for your environment
$Title = "Direct from your local VC: Weekly Statistics"

$Body += "`n`nTotals:`n"
$Body += "`nDatacenters: " + $totalDatacenters
$Body += "`nHosts: " + $totalHosts
$Body += "`nVMs: " + $totalVM
$Body += "`nClusters: " + $totalClusters

$SmtpClient.Send($From, $To, $Title, $Body)
