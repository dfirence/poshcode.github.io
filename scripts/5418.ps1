#requires -version 2.0
Set-Alias lspci Get-PCIDevices

function Get-PCIDevices {
  <#
    .NOTES
        Author: greg zakharov
  #>
  
  gci HKLM:\SYSTEM\CurrentControlSet\Enum\PCI | % {
    gp (gci $_.PSPath).PSPath | select @{
      N='DeviceID'; E={
        $i = ([Regex]"\d+").Matches($_.LocationInformation)
        '{0:x2}:{1:x2}.{2}' -f [Int32]$i[0].Value, [Int32]$i[1].Value, $i[2].Value
      }
    }, Class, @{
      N='Device'; E={$_.DeviceDesc}
    }, @{
      N='DriverDate'; E={
        ($script:r = gp (Join-Path HKLM:\SYSTEM\CurrentControlSet\Control\Class $_.Driver)).DriverDate
      }
    }, @{
      N='DriverVersion'; E={$r.DriverVersion}
    }
  } | sort DeviceID | ft -a
}
