#requires -version 2.0
function _from {
  <#
    .SYNOPSIS
        Add pack of type accelerators in Python style.
    .EXAMPLE
        _from Runtime.InteropServices -import {
          Marshal, HandleRef, GCHandle
        }
    .NOTES
        Author: greg zakharov
  #>
  param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateNotNullOrEmpty()]
    [String]$NameSpace,
    
    [Parameter(Mandatory=$true, Position=1)]
    [ScriptBlock]$Import
  )
  
  $ret = $null
  $arr = [Array]($ta = [Type]::GetType(
    'System.Management.Automation.TypeAccelerators'
  ))::Get.Keys
  
  [Management.Automation.PSParser]::Tokenize($Import, [ref]$ret) | % {
    if ($_.Type -match 'Command' -and $arr -notcontains $_.Content) {
      $ta::Add($_.Content, ("$($NameSpace).$($_.Content)"))
    }
  } #foreach
}
