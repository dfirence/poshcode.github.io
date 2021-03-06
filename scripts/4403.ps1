[CmdletBinding()]param(
    [string]$query, 
    [string]$server,
    [switch]$nOforward
    )
$TLDs = DATA {
  @{
    ".br.com"="whois.centralnic.net"
    ".cn.com"="whois.centralnic.net"
    ".eu.org"="whois.eu.org"
    ".com"="whois.crsnic.net"
    ".net"="whois.crsnic.net"
    ".org"="whois.publicinterestregistry.net"
    ".edu"="whois.educause.net"
    ".gov"="whois.nic.gov"
  }
}

$EAP, $ErrorActionPreference = $ErrorActionPreference, "Stop"

$query = $query.Trim()

if($query -match "(?:\d{1,3}\.){3}\d{1,3}") {
    Write-Verbose "IP Lookup!"
    $query = "n $query"
    if(!$server) { $server = "whois.arin.net" }
} elseif(!$server) {
    $server = $TLDs.GetEnumerator() |
        Where { $query -like  ("*"+$_.name) } |
        Select -Expand Value -First 1
}
if(!$server) {
    $server = "whois.arin.net"
}

$maxRequery = 3 

do {
    Write-Verbose "Connecting to $server"
    $client = New-Object System.Net.Sockets.TcpClient $server, 43

    try {
        $stream = $client.GetStream()

        Write-Verbose "Sending Query: $query"
        $data = [System.Text.Encoding]::Ascii.GetBytes( $query + "`r`n" )
        $stream.Write($data, 0, $data.Length)

        Write-Verbose "Reading Response:"
        $reader = New-Object System.IO.StreamReader $stream, [System.Text.Encoding]::ASCII

        $result = $reader.ReadToEnd()

        if($result -match "(?s)Whois Server:\s*(\S+)\s*") {
            Write-Warning "Recommended WHOIS server: ${server}"
            if(!$NoForward) {
                Write-verbose "Non-Authoritative Results:`n${result}"
                # cache, in case we can't get an answer at the forwarder
                if(!$cachedResult) {
                    $cachedResult = $result
                    $cachedServer = $server
                }
                $server = $matches[1]
                $query = ($query -split " ")[-1]
                $maxRequery--
            } else { $maxRequery = 0 }
        } else { $maxRequery = 0 }
    } finally {
        if($stream) {
            $stream.Close()
            $stream.Dispose()
        }
    }
} while ($maxRequery -gt 0)

$result

if($cachedResult -and ($result -split "`n").count -lt 5) {
    Write-Warning "Original Result from ${cachedServer}:"
    $cachedResult
}

$ErrorActionPreference = $EAP
