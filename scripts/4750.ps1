function Get-HostPaste {
  <#
    .NOTES
        Author: greg zakharov
        If you have a question send me a letter to
        mailto:gregzakharov@bk.ru or mailto:grishanz@yandex.ru
  #>
  begin {
    if (@(ps powershell).Count -gt 1) {
      throw "More than one host running."
    }
    
    function get([String]$Assembly, [String]$Class, [String]$Method, [Switch]$Flags) {
      $type = ([AppDomain]::CurrentDomain.GetAssemblies() | ? {
        $_.Location.Split('\')[-1].Equals($Assembly)
      }).GetType($Class)
      
      switch ($Flags) {
        $true {$res = $type.GetMethod($Method, [Reflection.BindingFlags]'NonPublic, Static')}
        default {$res = $type.GetMethod($Method)}
      }
      
      return $res
    }
  }
  process {
    $GetConsoleWindow = get `
      Microsoft.PowerShell.ConsoleHost.dll Microsoft.PowerShell.ConsoleControl GetConsoleWindow -f
    $SendMessage = get System.dll Microsoft.Win32.UnsafeNativeMethods SendMessage
    
    [Runtime.InteropServices.HandleRef]$href = New-Object Runtime.InteropServices.HandleRef(
      (New-Object IntPtr), $GetConsoleWindow.Invoke($null, @())
    )
  }
  end {
    [void]$SendMessage.Invoke($null, @($href, 0x0111, [IntPtr]0xfff1, [IntPtr]::Zero))
  }
}
