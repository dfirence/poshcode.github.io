<# 
.NOTES  
    File Name  : send-HL7Message.ps1  
    Author     : Rob Holme (rob@holme.com.au) 
    Version    : 1.0 (12/07/2016)
    Requires   : PowerShell V2

.SYNOPSIS  
    Send a HL7 message via TCP to a remote host (MLLP framing)
	
.DESCRIPTION  
    Send a HL7 message via TCP to a remote host (MLLP framing)
	
.PARAMETER HostName
    The remote hostname or IP address receiving the HL7 message

.PARAMETER Port
    The remote port of the listener receiving the message

.PARAMETER FileName
    The path and name of the file to send

.PARAMETER NoACK
    If the -NoAck switch is set the script will not wait to receive an ACK message from the remote host.

.EXAMPLE
    .\send-HL7Message -HostName 127.0.0.1 -Port 1234 -FileName c:\test\message.hl7
    # send the file c:\test\message.hl7 to 127.0.0.1:1234, wait for ACK

.EXAMPLE
    .\send-HL7Message 127.0.0.1 1234 c:\test\message.hl7 -NoACK 
    # send the file c:\test\message.hl7 to 127.0.0.1:1234, ignore ACK
#>

[CmdletBinding()]
Param(
        [parameter(Mandatory=$true, Position=0)]
        [string] $HostName,
        [parameter(Mandatory=$true, Position=1)]
        [string] $Port,
        [parameter(Mandatory=$true, Position=3)]
        [string] $FileName,
        [parameter(Mandatory=$false, Position=4)]
        [switch] $NoACK
)

# Warn if the file does not exist.
If (!(Test-Path $FileName))
{
    write-Output "`nError: The file $FileName does not exist."
    return
}

# frame the message using MLLP control characters
$message = [char]0x0B
foreach ($line in get-content $FileName)
{ 
    $message += $line
    $message += [char]0x0D
}
$message += [char]0x1C
$message += [char]0x0D

# create a TCP connection to the remote host, send the message
$tcpConnection = New-Object System.Net.Sockets.TcpClient
Try 
{
	Write-Output "`nConnecting to $($HostName):$($Port) (TCP) ..."
    $tcpConnection.Connect($HostName, $Port)
    $tcpStream = $tcpConnection.GetStream()
    $encoder = New-Object System.Text.UTF8Encoding
    $writeBuffer = New-Object Byte[] 4096
    $writeBuffer = $encoder.GetBytes($message)
    $tcpStream.Write($writeBuffer, 0, $writeBuffer.Length)
    $tcpStream.Flush()
    Write-Output "Message sent"
    # wait for the ACK message returned from the remote host unless -NoACK switch set
    if (!$NoACK)
    {
        write-Output "Waiting for ACK ..."
        $readBuffer = New-Object Byte[] 4096
        $bytesRead = $tcpStream.Read($readBuffer, 0, 4096)
        $ackMessage = $encoder.GetString($readBuffer, 0, $bytesRead)
        $start = $ackMessage.IndexOf([char]0x0B)
        if ($start -ge 0)
        {
            # Search for the end of the MLLP frame (FS control character)
            $end = $ackMessage.IndexOf([char]0x1C)
            if ($end -gt $start)
            {
                # split the ACK message on <CR> character (segment delineter), output each segment of the ACK on a new line
                $ackLines = $($ackMessage.SubString($start+1, $end-1)).Split([char]0x0D)
                foreach ($line in $ackLines)
                {
                    Write-Output $line
                }    
            }
        }
    }
}
# the connection failed
Catch 
{
	Write-Output "Connection to $($HostName):$($Port) failed"
}
Finally 
{
	# for Powershell v3+, call Dispose(), for earlier versions call Close()
    if ($PSVersionTable.PSVersion.Major -lt 3) {
		$tcpConnection.Close()
	}
	else {
		$tcpConnection.Dispose()	
	}
}


