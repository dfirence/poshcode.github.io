#requires -version 2.0
function Suspend-Process {
  <#
    .EXAMPLE
        PS C:\> Suspend-Process 2008
    .EXAMPLE
        PS C:\> Suspend-Process 2008 -Resume
    .NOTES
        Author: greg zakharov
  #>
  param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [Int32]$ProcessId,
    
    [Parameter(Position=1)]
    [Switch]$Resume
  )
  
  begin {
    if (!(($cd = [AppDomain]::CurrentDomain).GetAssemblies() | ? {
      $_.FullName.Contains('Nt')
    })) {
      $attr = 'AnsiClass, Class, Public, Sealed, BeforeFieldInit'
      $type = (($cd.DefineDynamicAssembly(
        (New-Object Reflection.AssemblyName('Nt')), 'Run'
      )).DefineDynamicModule('Nt', $false)).DefineType('Suspend', $attr)
      [void]$type.DefinePInvokeMethod('NtSuspendProcess', 'ntdll.dll',
        'Public, Static, PinvokeImpl', 'Standard', [Int32],
        @([IntPtr]), 'WinApi', 'Auto'
      )
      [void]$type.DefinePInvokeMethod('NtResumeProcess', 'ntdll.dll',
        'Public, Static, PinvokeImpl', 'Standard', [Int32],
        @([IntPtr]), 'WinApi', 'Auto'
      )
      Set-Variable Nt -Value $type.CreateType() -Option ReadOnly -Scope global
    }
    
    $OpenProcess = [RegEx].Assembly.GetType(
      'Microsoft.Win32.NativeMethods'
    ).GetMethod('OpenProcess') #returns SafeProcessHandle type
    
    $PROCESS_SUSPEND_RESUME = 0x00000800
  }
  process {
    try {
      $sph = $OpenProcess.Invoke($null, @($PROCESS_SUSPEND_RESUME, $false, $ProcessId))
      if ($sph.IsInvalid) {
        Write-Warning "process with specified ID does not exist."
        return
      }
      $ptr = $sph.DangerousGetHandle()
      
      switch ($Resume) {
        $true  { [void]$Nt::NtResumeProcess($ptr) }
        $false { [void]$Nt::NtSuspendProcess($ptr) }
      }
    }
    catch { $_.Exception }
    finally {
      if ($sph -ne $null) { $sph.Close() }
    }
  }
  end {}
}
