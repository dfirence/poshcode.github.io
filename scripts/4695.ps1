Set-Alias hl New-HardLink

$code = @'
using System;
using System.Reflection;
using System.Runtime.InteropServices;

[assembly: AssemblyVersion("2.0.0.0")]
[assembly: CLSCompliant(true)]
[assembly: ComVisible(false)]

namespace HardLink {
  internal static class NativeMethods {
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
    [return: MarshalAs(UnmanagedType.Bool)]
    internal static extern Boolean CreateHardLink(String lpFileName,
                                                  String lpExistingFileName,
                                                  IntPtr lpSecurityAttributes);
  }
  
  public sealed class Creator {
    private Creator() {}
    
    public static void SetLink(String copy, String orig) {
      Boolean lnk = NativeMethods.CreateHardLink(copy, orig, IntPtr.Zero);
      
      if (!lnk) Console.Out.WriteLine("HardLink creation error.");
    }
  }
}
'@

function New-HardLink {
  <#
    .EXAMPLE
        PS C:\> New-HardLink "E:\foo.txt" "E:\lnk\foo.txt"
  #>
  param(
    [Parameter(Mandatory=$true,
               Position=0)]
    [String]$FileName,
    
    [Parameter(Mandatory=$true,
               Position=1)]
    [String]$LinkName
  )
  
  Add-Type $code
  [HardLink.Creator]::SetLink($LinkName, $FileName)
}
