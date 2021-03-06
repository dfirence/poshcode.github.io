#requires -version 2.0
Set-Alias clockres Get-ClockRes

function Get-ClockRes {
  <#
    .NOTES
        Author: greg zakharov
  #>
  begin {
    $cd = [AppDomain]::CurrentDomain
    $Attributes = 'AutoLayout, AnsiClass, Class, Public, Sealed, BeforeFieldInit'
    
    if (!($cd.GetAssemblies() | ? {
      $_.FullName.Contains('NativeMethods')
    })) {
      $type = (($cd.DefineDynamicAssembly(
        (New-Object Reflection.AssemblyName('NativeUtils')), [Reflection.Emit.AssemblyBuilderAccess]::Run
      )).DefineDynamicModule('NativeUtils', $false)).DefineType('ClockRes', $Attributes)
      [void]$type.DefinePInvokeMethod('NtQueryTimerResolution', 'ntdll.dll',
        [Reflection.MethodAttributes]'Public, Static, PinvokeImpl',
        [Reflection.CallingConventions]::Standard, [Int32],
        @([Int32].MakeByRefType(), [Int32].MakeByRefType(), [Int32].MakeByRefType()),
        [Runtime.InteropServices.CallingConvention]::Winapi, [Runtime.InteropServices.CharSet]::Auto
      )
      $global:clockres = $type.CreateType()
    }
  }
  process {
    try {
      [Int32]$minres = $maxres = $actres = 0
      $res = $clockres::NtQueryTimerResolution([ref]$minres, [ref]$maxres, [ref]$actres)
      if ($res -eq 0) {
        'Current timer interval: {0} ms' -f ($actres / 10000)
        'Minimum timer interval: {0} ms' -f ($minres / 10000)
        'Maximum timer interval: {0} ms' -f ($maxres / 10000)
      }
    }
    catch [Management.Automation.RuntimeException] {
      Write-Host $_.Exception.Message -fo Red
    }
  }
  end {}
}
