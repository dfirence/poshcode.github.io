if (!(Test-Path alias:pipelist)) { Set-Alias pipelist Get-PipeList }

function Get-PipeList {
  <#
    .SYNOPSIS
        Gets list of all open named pipes.
    .DESCRIPTION
        The quickest way to do it:
        PS C:\> [IO.Directory]::GetFiles(
        >> "\\.\pipe\"
        >> ) | % {-join$_[($_.IndexOf('\', 5) + 1)..$_.Length]}
        Actually, GetFiles method is based on calls of two
        system functions (FindFirstFile and FindNextFile) and
        this script shows how does it work in reality.
    .NOTES
        Author: greg zakharov
  #>
  
  begin {
    $asm = [AppDomain]::CurrentDomain.GetAssemblies() | ? {
      $_.ManifestModule.ScopeName.Equals('CommonLanguageRuntimeLibrary')
    }
    
    $SafeFindHandle = $asm.GetType('Microsoft.Win32.SafeHandles.SafeFindHandle')
    $Win32Native = $asm.GetType('Microsoft.Win32.Win32Native')
    
    $WIN32_FIND_DATA = $Win32Native.GetNestedType(
        'WIN32_FIND_DATA', [Reflection.BindingFlags]32
    )
    $FindFirstFile = $Win32Native.GetMethod(
        'FindFirstFile', [Reflection.BindingFlags]40,
        $null, @([String], $WIN32_FIND_DATA), $null
    )
    $FindNextFile = $Win32Native.GetMethod(
        'FindNextFile', [Reflection.BindingFlags]40,
        $null, @($SafeFindHandle, $WIN32_FIND_DATA), $null
    )
    
    $obj = $WIN32_FIND_DATA.GetConstructors()[0].Invoke($null)
    
    function Read-Field([String]$Field) {
      return [String]$WIN32_FIND_DATA.GetField($Field, [Reflection.BindingFlags]36).GetValue($obj)
    }
  }
  process {
    '{0, -40} {1, 14}' -f 'Pipe Name', 'Instances'
    '{0, -40} {1, 14}' -f '---------', '---------'
    
    $hndl = $FindFirstFile.Invoke($null, @('\\.\pipe\*', $obj))
    '{0, -40} {1, 14}' -f (Read-Field cFileName), (Read-Field nFileSizeLow)
    
    while ($FindNextFile.Invoke($null, @($hndl, $obj))) {
      '{0, -40} {1, 14}' -f (Read-Field cFileName), (Read-Field nFileSizeLow)
    }
    
    $hndl.Close()
  }
  end { '' }
}
