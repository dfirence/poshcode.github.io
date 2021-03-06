#requires -version 2.0
Set-Alias regjump Get-RegistryPath

$asm = Add-Type -MemberDefinition @'
    [DllImport("kernel32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern Boolean CloseHandle(IntPtr hObject);
    
    [DllImport("kernel32.dll")]
    internal static extern IntPtr OpenProcess(
        UInt32 dwDesiredAcess,
        [MarshalAs(UnmanagedType.Bool)]Boolean bInheritHandle,
        UInt32 dwProcessId
    );
    
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    internal static extern IntPtr FindWindow(
        String lpClassName,
        String lpWindowName
    );
    
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    internal static extern IntPtr FindWindowEx(
        IntPtr hwndParent,
        IntPtr hwndChildAfter,
        String lpszClass,
        String lpszWindow
    );
    
    [DllImport("user32.dll")]
    internal static extern UInt32 GetWindowThreadProcessId(
        IntPtr hWnd,
        out UInt32 lpdwProcessId
    );
    
    [DllImport("user32.dll")]
    internal static extern IntPtr SendMessage(
        IntPtr hWnd,
        UInt32 Msg,
        IntPtr wParam,
        IntPtr lParam
    );
    
    [DllImport("user32.dll")]
    internal static extern IntPtr SetFocus(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern Boolean SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern Boolean ShowWindow(
        IntPtr hWnd,
        UInt32 nCmdShow
    );
    
    const UInt32 SW_SHOW     = 0x00000005;
    const UInt32 SYNCHRONIZE = 0x00100000;
    
    public static void JumpTo(String path) {
      IntPtr RegEditMain;
      IntPtr RegEditHwnd;
      UInt32 rslt;
      UInt32 ProcessId = 0;
      IntPtr hndl;
      
      RegEditMain = FindWindow("RegEdit_RegEdit", null);
      if (RegEditMain == IntPtr.Zero) {
        ProcessStartInfo psi = new ProcessStartInfo("regedit.exe");
        psi.UseShellExecute = false;
        Process.Start(psi);
        Thread.Sleep(100); //pause for the correct execution of the next step
        RegEditMain = FindWindow("RegEdit_RegEdit", null);
      }
      
      ShowWindow(RegEditMain, SW_SHOW);
      RegEditHwnd = FindWindowEx(RegEditMain, IntPtr.Zero, "SysTreeView32", null);
      SetFocus(RegEditHwnd);

      rslt = GetWindowThreadProcessId(RegEditHwnd, out ProcessId);
      if (rslt != 0) {
        hndl = OpenProcess(SYNCHRONIZE, false, ProcessId);
        for (Int32 i = 0; i < 30; i++)
          SendMessage(RegEditHwnd, (UInt32)0x100, (IntPtr)0x25, IntPtr.Zero);
        
        //jumping
        Char[] c = path.ToCharArray();
        for (Int32 i = 0; i < c.Length; i++) {
          if (c[i].Equals('\\')) {
            SendMessage(RegEditHwnd, (UInt32)0x100, (IntPtr)0x27, IntPtr.Zero);
          }
          else {
            SendMessage(RegEditHwnd, (UInt32)0x102, (IntPtr)c[i], IntPtr.Zero);
          }
        }
        SetForegroundWindow(RegEditMain);
        SetFocus(RegEditMain);
        CloseHandle(hndl);
      }
    }
'@ -Name NativeUtils -NameSpace RegJump -Using System.Diagnostics, System.Threading -PassThru

function Get-RegistryPath {
  <#
    .NOTES
        Author: greg zakharov
  #>
  param(
    [Parameter(Mandatory=$true)]
    [String]$RegistryPath
  )
  
  begin {
    $RegistryPath = $RegistryPath.ToUpper()
    
    function get([String]$short, [String]$full) {
      if (Test-Path ('Registry::' + $RegistryPath)) {
        $RegistryPath = '\' + $RegistryPath.Replace($short, $full)
        $asm::JumpTo($RegistryPath)
      }
      else {
        Write-Host Specified registry path does not exist. -fo Yellow
      }
    }
  }
  process {
    try {
      switch ($RegistryPath.Substring(0, 4)) {
        'HKCR' {get 'HKCR' 'HKEY_CLASSES_ROOT'}
        'HKCU' {get 'HKCU' 'HKEY_CURRENT_USER'}
        'HKLM' {get 'HKLM' 'HKEY_LOCAL_MACHINE'}
        'HKU\' {get 'HKU'  'HKEY_USERS'}
        'HKCC' {get 'HKCC' 'HKEY_CURRENT_CONFIG'}
        default {
          Write-Host Invalid registry path. -fo Red
        }
      }
    }
    catch [Management.Automation.MethodInvocationException] {
      Write-Host Invalid registry path. -fo Red
    }
  }
  end {}
}
