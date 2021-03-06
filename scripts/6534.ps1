<# https://mobile.twitter.com/gregzakharov/status/781216796443602945 #>

function Get-DisplayDevices {
  <#
    .SYNOPSIS
        Gets information about the display devices in the current
        session.
    .NOTES
        typedef struct _DISPLAY_DEVICE { // A |      W
          DWORD cb;                 // +0x000 | +0x000
          TCHAR DeviceName[32];     // +0x004 | +0x004
          THCAR DeviceString[128];  // +0x024 | +0x044
          DWORD StateFlags;         // +0x0a4 | +0x144
          TCHAR DeviceID[128;       // +0x0a8 | +0x148
          TCHAR DeviceKey[128];     // +0x128 | +0x248
        } DISPLAY_DEVICE, *PDISPLAY_DEVICE;
        
        sizeof(DISPLAY_DEVICEA) = 424;
        sizeof(DISPLAY_DEVICEW) = 840;
  #>
  begin {
    function private:New-Delegate {
      param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Module,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Function,
        
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]$Delegate
      )
.....
