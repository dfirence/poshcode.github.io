set-psdebug -strict

Function Where-Host
{
<# 
.SYNOPSIS 
	Filter hosts according to hostname resolution, ping reachability or WMI capability 
.DESCRIPTION 
	Filter hostnames by hostname resolution, ping reachbility or WMI capabilities.
	Filter can be positive or negative. Positive filter includes hosts that can be reached at least at level X (X can be "DNS", "Ping" or "WMI"). Negative filter includes hosts that cannot be reached at level X (X can be the same as above).
.EXAMPLE
	Get a list of hosts from Hosts.txt and keep only those who reply to WMI requests:
	Get-Content Hosts.txt | Filter-Host -Can WMI
.INPUTTYPE
	String
.PARAMETER Hostname
	Name of the host we want to know about its level of reachability
.PARAMETER PingTimeout
	When pinging hosts, timeout after what we consider the host is unreachable
.PARAMETER PingCount
	When pinging hosts, number of packets sent
.PARAMETER Can
	Positive Filter. We keep hosts who DO reply to a certain level of request.
	"Can" parameter takes an argument that is the MINIMUM capacity we are looking to know about:
	- "DNS": the hostname can at least be resolved by DNS
	- "Ping": the host at least replies to ping requests
	- "WMI": the host at least replies to a WMI "List" request
	Only one argument can be given to "Can" parameter. Give the most elevated you want.
.PARAMETER Cannot
	Negative Filter. We keep hosts who DO NOT reply to a certain level of request.
	"Cannot" parameter takes an argument that is the MAXIMUM capacity we are looking to know about:
	- "DNS": the hostname cannot be resolved by DNS
	- "Ping": the host doesn't reply to ping requests
	- "WMI": the host doesn't reply to a WMI "List" request
	Only one argument can be given to "Can" parameter. Give the less elevated you want.
.PARAMETER Credential
	A PSCredential object used if you want to do WMI requests and you're not logged with a power user.
	See Get-Credential
.RETURNVALUE
	For each object in the pipeline, the cmdlet returns the input object if filter matches, nothing if it doesn't.
.EXAMPLE
	Get a list of hosts from Hosts.txt and keep only those who doesn't reply to ping requests:
	Get-Content Hosts.txt | Filter-Host -Cannot Ping
.NOTES
    Author     : Rafael Corvalan - rafael <a-t> corvalan [dot] net
.LINK 
    http://psh-xrt.blogspot.com
#> 

	[CmdletBinding(DefaultParameterSetName="PositiveFilter")]
    Param(
		[String]
		[Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True, Mandatory=$True)]
		[Alias("Host","Name")]
		$Hostname,
		
		[Alias("Timeout")]
		[Int]$PingTimeout	= 200,
		
		[Alias("Count")]
		[Int]$PingCount		= 2,
        
		[ValidateSet("DNS", "Ping", "WMI")]
		[Parameter(ParameterSetName="PositiveFilter")]
		[String]
		$Can = "Ping",
        
		[ValidateSet("DNS", "Ping", "WMI")]
		[Parameter(ParameterSetName="NegativeFilter")]
		[String]
		$Cannot,
		
		[System.Management.Automation.PSCredential]
		[Alias("PSCredential")]
		$Credential
	)
	BEGIN
	{
		if (-not (Test-Path Variable:\Can)) {$Can = ''}
		if (-not (Test-Path Variable:\Cannot)) {$Cannot = ''}
	}
	Process
	{
		Write-Verbose "+ Processing host $Hostname"
		
		Write-Verbose "   - Resolving host $Hostname"
        $rh = Resolve-Host $Hostname -ErrorAction SilentlyContinue -ErrorVariable err
        
        if ($err -ne $Null)
        {
            Write-Verbose('Cannot resolve host {0}. Message [{1}]' -f $Hostname, ($err -join '; '))
            if ($Cannot -match '^DNS|Ping|WMI$')
            {
                return $_
            }
            return
		}
        
        if ($Can -ieq 'DNS') {return $_}
        if ($Cannot -ieq 'DNS') {return}

		Write-Verbose "   - Pinging host $Hostname"
		$ping = Ping-Host $Hostname -Quiet -Count $PingCount -Timeout $PingTimeout -ErrorAction SilentlyContinue -ErrorVariable err
		if ($err -ne $Null)
        {
            Write-Verbose('Error pinging host {0}. Message [{1}]' -f $Hostname, ($err -join '; '))
        }
        elseif ($ping.Loss -eq 100)
        {
			Write-Verbose('Host {0} is unreachable by ping' -f $Hostname)
        }
		if ($err -ne $null -or $ping.Loss -eq 100)
        {
            if ($Cannot -match '^Ping|WMI$') {return $_ }
			else {return}
		}

        
        if ($Can -ieq 'Ping') {return $_}
        if ($Cannot -ieq 'Ping') {return}

		Write-Verbose "   - WMI test on host $Hostname"
		if ($Credential -ne $Null) {
			Get-WMIObject -List -ComputerName $Hostname -Credential $Credential -ErrorAction SilentlyContinue -ErrorVariable err > $Null
		} else {
			Get-WMIObject -List -ComputerName $Hostname -ErrorAction SilentlyContinue -ErrorVariable err > $Null
		}
        
        if ($err -ne $Null)
        {
            Write-Verbose('Error querying WMI on host {0}. Message [{1}]' -f $Hostname, ($err -join '; '))
            if ($Cannot -ieq 'WMI') {return $_}
			else {return}

        }
        
        if ($Can -ieq 'WMI') {return $_}
        else {return}
    }
}
