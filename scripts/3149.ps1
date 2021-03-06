#config
@@#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
@@#NOTE: Does not support IPv6.  If used on a network with static IPv6 addresses,
@@#they may be lost.
@@#!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
@@$network = "10.200.*"
@@$newSubnet = "255.255.240.0"

#get WMI for network adapters
$nics = Get-WMIObject Win32_NetworkAdapterConfiguration | where { $_.IPEnabled -eq "TRUE" }

#loop over each adapter
foreach ($nc in $nics) 
{ 
    $addresses = [System.Collections.ArrayList]$nc.IPAddress
    $smasks = [System.Collections.ArrayList]$nc.IPSubnet
    $needsChange = $FALSE
    
    write-host ("{0} addresses found" -f $addresses.count)
    
    #loop over each address
    for ($i = 0; $i -lt $addresses.count;)
    {
        $addy = $addresses[$i]
        $sm = $smasks[$i]

        #remove from array all 
        if ($addy -notLike '*.*.*.*')
        {
            $addresses.RemoveRange($i, 1)
            $smasks.RemoveRange($i, 1)
        }    
        #if the address needs to be updated, change it and flag for update
        elseif ($addy -like $network -and $sm -ne $newSubnet)
        {
            write-host ("Updating address {0}/{1}" -f $addy, $sm)
            $smasks[$i] = $newSubnet
            $needsChange = $TRUE
            
            $i++;
        }
        #otherwise, skip it
        else
        {
            write-host ("Skipping address {0}/{1}" -f $addy, $sm)
            
            $i++;
        }
    }
    
    #if we had any ips that needed to be updated, do so now.
    if ($needsChange)
    {
        write-host ("Updating Addresses...")
        $res = [int]($nics.EnableStatic($addresses, $smasks).ReturnValue)
        
        #a nonzero value indicates failure
        if ($res -eq 0) {
            write-host "Updated Successfully!"
        } else {
            write-host ("Updating the IP Address failed with error {0}" -f $res)
        }
    }
    #no addresses changed
    else 
    {
        write-host "No changes needed"
    }
}
write-host 'done '
