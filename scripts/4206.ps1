$code = @'
using System;
using System.Runtime.InteropServices;

public class WinAPI {
  [DllImport("user32.dll")]
  internal static extern IntPtr FindWindow(string lpClassName,
                                         string lpWindowName);
  [DllImport("user32.dll")]
  internal static extern IntPtr GetParent(IntPtr hWnd);

  [DllImport("user32.dll")]
  internal static extern IntPtr SetParent(IntPtr hWnd,
                                                 IntPtr hWndNewParent);

  [DllImport("user32.dll")]
  [return: MarshalAs(UnmanagedType.Bool)]
  internal static extern bool SetWindowPos(IntPtr hWnd,
    IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

  public static void BringToForm(string wClass, string wName, IntPtr wParent) {
    IntPtr hwnd = FindWindow(wClass, wName);

    if (hwnd != IntPtr.Zero) {
      GetParent(hwnd);
      SetParent(hwnd, wParent);
      SetWindowPos(hwnd, (IntPtr)1, 0, 0, 600, 300, 0);
    }
  }
}
'@

function SetHostHere {
  Add-Type $code

  $cmd = New-Object Diagnostics.Process
  $cmd.StartInfo.FileName = "cmd.exe"
  $cmd.StartInfo.Arguments = " /k title Terminal"
  $cmd.StartInfo.UseShellExecute = $true
  [void]$cmd.Start()

  Start-Sleep -milliseconds 100
  [WinAPI]::BringToForm("ConsoleWindowClass", "Terminal", $frmMain.Handle)
}

function frmMain_Show {
  Add-Type -AssemblyName System.Windows.Forms
  [Windows.Forms.Application]::EnableVisualStyles()

  $frmMain = New-Object Windows.Forms.Form
  #
  #frmMain
  #
  $frmMain.ClientSize = New-Object Drawing.Size(605, 295)
  $frmMain.FormBorderStyle = "FixedSingle"
  $frmMain.StartPosition = "CenterScreen"
  $frmMain.Text = "Terminal"
  $frmMain.Add_Click({SetHostHere})
  $frmMain.Add_Load({SetHostHere})

  [void]$frmMain.ShowDialog()
}

frmMain_Show
