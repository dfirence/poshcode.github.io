function Get-CpuCache {
  begin {
    if (($ta = [PSObject].Assembly.GetType(
      'System.Management.Automation.TypeAccelerators'
    ))::Get.Keys -notcontains 'Marshal') {
      $ta::Add('Marshal', [Runtime.InteropServices.Marshal])
    }
    
    Set-Variable ($$ = [Regex].Assembly.GetType(
      'Microsoft.Win32.NativeMethods'
    ).GetMethod('NtQuerySystemInformation')).Name $$
    
    $ret = 0
  }
  process {
    try {
      $ptr = [Marshal]::AllocHGlobal(24)
      
      if ($NtQuerySystemInformation.Invoke(
        $null, ($par = [Object[]]@(73, $ptr, 24, $ret)
      )) -eq 0xC0000004) {
        $ptr = [Marshal]::ReAllocHGlobal($ptr, [IntPtr]$par[3])
        
        if ($NtQuerySystemInformation.Invoke(
          $null, @(73, $ptr, $par[3], 0)
        ) -ne 0) {
          throw New-Object InvalidOperationException(
            'Could not retrieve required data.'
          )
        }
      }
      
      $len = $par[3]
      $tmp = $ptr
      $(for ($i = 0; $i -lt $len; $i += $len / 24) {
        if ([Marshal]::ReadInt32($tmp, 4) -eq 2) {
          [Byte[]]$bytes = 0..11 | ForEach-Object {
            $ofb = 8
            $CACHE_TYPE = @{
              0 = 'CacheUnified'
              1 = 'CacheInstruction'
              2 = 'CacheData'
              3 = 'CacheTrace'
            }
          }{
            [Marshal]::ReadByte($tmp, $ofb)
            $ofb++
          }
          New-Object PSObject -Property @{
            Level = $bytes[0]
            Associativity = $bytes[1]
            LineSize = [BitConverter]::ToInt16($bytes[2..3], 0)
            Size = [BitConverter]::ToInt32($bytes[4..7], 0)
            Type = [BitConverter]::ToInt32($bytes[8..15], 0)
          } | Select-Object @{
            N='Type';E={$CACHE_TYPE.Item($_.Type)}
          }, Level, @{
            N='Size(KB)';E={$_.Size / 1Kb}
          }, Associativity, LineSize
        }
        $tmp = [IntPtr]($tmp.ToInt32() + 24)
      }) | Format-Table -AutoSize
    }
    catch { $_.Exception }
    finally {
      if ($ptr) { [Marshal]::FreeHGlobal($ptr) }
    }
  }
  end {
    [void]$ta::Remove('Marshal')
  }
}
