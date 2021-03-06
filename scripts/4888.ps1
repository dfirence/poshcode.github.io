#requires -version 2.0
Set-Alias listdlls Get-ListDlls

function Get-ListDlls {
  <#
    .NOTES
        Author: greg zakharov
  #>
  param(
    [Parameter(Position=0)]
    [Alias("n")]
    [String]$ProcessName,
    
    [Parameter(Position=0)]
    [Alias("i")]
    [Int32]$ProcessId,
    
    [Parameter(Position=0)]
    [Alias("d")]
    [String]$DllName
  )
  
  begin {
    $del = '-' * 47
    
    function tbl([Diagnostics.ProcessModule[]]$Modules) {
      $Modules | select @{N='Base';E={'0x' + $_.BaseAddress.ToString('x8')}
      },@{N='Size';E={'0x' + $_.ModuleMemorySize.ToString('x')}
      },@{N='Path';E={$_.ModuleName}}
    }
  }
  process {
    if ($ProcessName) {
      [Diagnostics.Process]::GetProcessesByName($ProcessName) | % {
        "`n{0} pid: {1}`n{2}" -f $_.ProcessName, $_.Id, $del
        tbl $_.Modules | ft -a
      }
    }
    elseif ($ProcessId) {
      $i = [Diagnostics.Process]::GetProcessById($ProcessId)
      "`n{0} pid: {1}`n{2}" -f $i.ProcessName, $ProcessId, $del
      tbl $i.Modules | ft -a
    }
    elseif ($DllName) {
      "{0}`n{1}" -f $DllName, $del
      [Diagnostics.Process]::GetProcesses() | % {
        if ($_.Modules -match $DllName) {"{0, 23} pid: {1}" -f $_.ProcessName, $_.Id}
      }
    } #if
  }
  end {}
}
