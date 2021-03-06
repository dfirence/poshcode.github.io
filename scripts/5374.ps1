# First, you have to install WinPcap
# http://www.winpcap.org/install/default.htm

# Then, you have to download SharpPcap
# http://sourceforge.net/projects/sharppcap/

# And you need to import the assembly from wherever you put it
Add-Type -Path $SkyProfileDir\Libraries\SharpPcap*\SharpPcap.dll

# To avoid crashing, you MUST avoid accessing the NonBlockingMode property
# But I also want to expose the Interface.FriendlyName because it's the meaningful name
Update-TypeData -TypeName SharpPcap.WinPcap.WinPcapDevice `
    -MemberName FriendlyName -MemberType ScriptProperty -Value { $this.Interface.FriendlyName }
Update-TypeData -TypeName SharpPcap.WinPcap.WinPcapDevice `
    -DefaultDisplayProperty FriendlyName -DefaultDisplayPropertySet FriendlyName, Addresses, Description, MacAddress
# The MacAddress property doesn't seem to work right now, but Interface.MacAddress does
Update-TypeData -TypeName SharpPcap.WinPcap.WinPcapDevice `
    -MemberName MacAddress -MemberType ScriptProperty -Value { $this.Interface.MacAddress } -Force
# By default, PcapAddress ToString() shows the address and netmask etc. which we don't need to see all the time.
Update-TypeData -TypeName SharpPcap.LibPcap.PcapAddress `
    -DefaultDisplayProperty Addr -MemberName ToString -MemberType ScriptMethod -Value { $this.Addr.ToString() } -Force

# Then you need to pick a device to capture with
[SharpPcap.CaptureDeviceList]::Instance | Format-Table FriendlyName, Addresses, Description, MacAddress -Auto -Wrap



# If the pipeline-enabled Read-Choice is available:
Import-Module Reflection -Min 4.7 -ErrorAction SilentlyContinue
if($choose = get-command Read-Choice* | ? { $_.Parameters.Values.GetEnumerator() | % Attributes | % ValueFromPipeline }) {
    $device = [SharpPcap.CaptureDeviceList]::Instance |
       &$choose -Prompt "Please choose a device for capture:" -Label FriendlyName -Passthru
} else {
    $device = [SharpPcap.CaptureDeviceList]::Instance | 
              Where { $_.Addresses.Addr -like "192.*" } | 
              Select -First 1
}

Get-EventSubscriber -Source $device.MacAddress -EA 0 | Where EventName -eq OnPacketArrival | Unregister-Event
$null = Register-ObjectEvent $device -EventName OnPacketArrival -Source $device.MacAddress {
    try {
        # Do something useful with the CaptureEventArgs in $EventArgs:
        $Packet = [PacketDotNet.Packet]::ParsePacket($EventArgs.Packet.LinkLayerType, $EventArgs.Packet.Data) 
        # If you just want the TcpPacket:
        # $Packet = $Packet.Extract([PacketDotNet.TcpPacket])

        # If you want to see what you could be doing ... 
        # $Packet | Get-Member | Out-String -Stream | % Trim | Write-Host

        # This isn't useful, but it's a nice demo
        Write-Host ([DateTime]$EventArgs.Packet.Timeval.Date) "Len=" $EventArgs.Packet.Data.Length -Foreground Cyan
        Write-Host $Packet.ToString()
    } catch {
        Write-Host "ERROR:" $_ -Foreground Red
    }
}


Write-Host "Capturing on" $device.FriendlyName

$device.Open([SharpPcap.DeviceMode]::Promiscuous, 1000);
# Receive only TCP packets
$device.Filter = "tcp"
$device.StartCapture()

# Listen for a while ...
# In order to make sure the "host" output of the event handler shows up ...
# We should Write-Host on the current thread (ugh, that's screwy)
for($msec=0; $msec -lt 3000; $msec += 100) {
    Start-Sleep -milli 100
    Write-Host -NoNewLine
}

# Clean up
$device.StopCapture()
$device.Close()
