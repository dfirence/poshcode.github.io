function Get-Computer {
<#
  .Synopsis
    Retrieves basic information about a computer. 
   .Description
    The Get-Computer cmdlet retrieves basic information such as
    computer name, domain or workgroup name, and whether or not the computer
    is on a workgroup or a domain for the local computer.
   .Example
    Get-Computer
    Returns comptuer name, domain or workgroup name, and isDomainName
    .Example
    Get-Computer
    Returns comptuer name, domain or workgroup name, and isDomainName
      .OutPuts
    [PSObject]
   .Notes
    NAME:  Get-Computer
    AUTHOR: Tome Tanasovski
    LASTEDIT: 2/13/2010
    KEYWORDS:
   .Link
     Http://powertoe.wordpress.com
 #Requires -Version 2.0
 #>
$sig = @"
[DllImport("Netapi32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
public static extern int NetGetJoinInformation(string server,out IntPtr domain,out int status);
"@
    $type = Add-Type -MemberDefinition $sig -Name Win32Utils -Namespace NetGetJoinInformation -PassThru 
    $ptr = [IntPtr]::Zero
    $status = 0
    $type::NetGetJoinInformation($null, [ref] $ptr, [ref]$status) |Out-Null
    $returnobj = New-Object PSObject
    
    $workdomainname = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
    
    $returnobj |Add-Member NoteProperty ComputerName ([System.Windows.Forms.SystemInformation]::Computername)

        switch ($status) {
        0 {
            Write-Warning "NetJoin status is type is Unknown.  Cannot determine whether or not this computer is on a domain or workgroup"
            $returnobj |Add-Member Noteproperty isDomain $null
        }
        1 {
            Write-Warning "NetJoin status is type is Unjoined.  Cannot determine whether or not this computer is on a domain or workgroup"
            $returnobj |Add-Member Noteproperty isDomain $null
        }
        2 {
            $returnobj |Add-Member Noteproperty isDomain $false
            $returnobj |Add-Member Noteproperty WorkgroupName $workdomainname
        }
        3 {
            $returnobj |Add-Member Noteproperty isDomain $true
            $returnobj |Add-Member Noteproperty DomainName $workdomainname
        }
    }

    return $returnobj
}
