####################################################################################
#  Script: parse-nmap.ps1
# Purpose: Parse the XML output file of the nmap port scanner and emit custom 
#          objects with properties containing data from XML file.
# Example: dir *.xml | .\parse-nmap.ps1 
#  Author: Jason Fossen (www.EnclaveConsulting.com)
# Version: 2.0
# Updated: 15.Jun.2009
#   Notes: Pipe one or more file objects into script.  Don't pipe file contents.
#          Script is slow, e.g., a 20MB XML log with 65k entries requires 103 seconds
#          to process on a 2.16GHz T2600 Intel CPU (about 630 entries per second).
#   LEGAL: PUBLIC DOMAIN.  SCRIPT PROVIDED "AS IS" WITH NO WARRANTIES OR GUARANTEES OF 
#          ANY KIND, INCLUDING BUT NOT LIMITED TO MERCHANTABILITY AND/OR FITNESS FOR
#          A PARTICULAR PURPOSE.  ALL RISKS OF DAMAGE REMAINS WITH THE USER, EVEN IF
#          THE AUTHOR, SUPPLIER OR DISTRIBUTOR HAS BEEN ADVISED OF THE POSSIBILITY OF
#          ANY SUCH DAMAGE.  IF YOUR STATE DOES NOT PERMIT THE COMPLETE LIMITATION OF
#          LIABILITY, THEN DELETE THIS FILE SINCE YOU ARE NOW PROHIBITED TO HAVE IT.
####################################################################################


if ($args -ne $null) { 
    "`nThis script takes no arguments, please pipe one or more files into it."
    "Example: dir *.xml | .\parse-nmap.ps1 | export-csv -path c:\file.csv`n"
    exit 
}

# Set $ShowProgress to $false if you do not want progress info sent to StdErr.
$ShowProgress = $true



ForEach ($file in $input) {
    If ($ShowProgress) { [Console]::Error.WriteLine("[" + (get-date).ToLongTimeString() + "] Starting $file" ) }

    $xmldoc = new-object System.XML.XMLdocument
    $xmldoc.Load($file)
    $i = 1  #Counter for <host> nodes processed.

    # Process each of the <host> nodes from the nmap report.
    $xmldoc.nmaprun.host | foreach-object { 
        $hostnode = $_   # $hostnode is a <host> node in the XML.

        # Init variables, with $entry being the custom object for each <host>. 
        $service = " " #service needs to be a single space.
        $entry = ($entry = " " | select-object FQDN, HostName, Status, IPv4, IPv6, MAC, Ports, OS) 

        # Extract state element of status:
        $entry.Status = $hostnode.status.state.Trim() 
        if ($entry.Status.length -eq 0) { $entry.Status = "<no-status>" }

        # Extract fully-qualified domain name(s).
        $hostnode.hostnames | foreach-object { $entry.FQDN += $_.hostname.name + " " } 
        $entry.FQDN = $entry.FQDN.Trim()
        if ($entry.FQDN.Length -eq 0) { $entry.FQDN = "<no-fullname>" }

        # Note that this code cheats, it only gets the hostname of the first FQDN if there are multiple FQDNs.
        if ($entry.FQDN.Contains(".")) { $entry.HostName = $entry.FQDN.Substring(0,$entry.FQDN.IndexOf(".")) }
        elseif ($entry.FQDN -eq "<no-fullname>") { $entry.HostName = "<no-hostname>" }
        else { $entry.HostName = $entry.FQDN }

        # Process each of the <address> nodes, extracting by type.
        $hostnode.address | foreach-object {
            if ($_.addrtype -eq "ipv4") { $entry.IPv4 += $_.addr + " "}
            if ($_.addrtype -eq "ipv6") { $entry.IPv6 += $_.addr + " "}
            if ($_.addrtype -eq "mac")  { $entry.MAC  += $_.addr + " "}
        }        
        if ($entry.IPv4 -eq $null) { $entry.IPv4 = "<no-ipv4>" } else { $entry.IPv4 = $entry.IPv4.Trim()}
        if ($entry.IPv6 -eq $null) { $entry.IPv6 = "<no-ipv6>" } else { $entry.IPv6 = $entry.IPv6.Trim()}
        if ($entry.MAC  -eq $null) { $entry.MAC  = "<no-mac>" }  else { $entry.MAC  = $entry.MAC.Trim() }


        # Process all ports from <ports><port>, and note that <port> does not contain an array if it only has one item in it.
        if ($hostnode.ports.port -eq $null) { $entry.Ports = "<no-ports>" } 
        else 
        {
            $hostnode.ports.port | foreach-object {
                If ($_.service.name -eq $null) { $service = "unknown" } else { $service = $_.service.name } 
                $entry.Ports += $_.state.state + ":" + $_.protocol + ":" + $_.portid + ":" + $service + " " 
            }
            $entry.Ports = $entry.Ports.Trim()
        }


        # Extract fingerprinted OS type and percent of accuracy.
        $hostnode.os.osmatch | foreach-object {$entry.OS += $_.name + " <" + ([String] $_.accuracy) + "%-accuracy> "} 
        $entry.OS = $entry.OS.Trim()
        if ($entry.OS -eq "<%-accuracy>") { $entry.OS = "<no-os>" }


        # Emit custom object from script.
        $entry
        $i++  #Progress counter...
    }

If ($ShowProgress) { [Console]::Error.WriteLine("[" + (get-date).ToLongTimeString() + "] Finished $file, processed $i entries." ) }
}







