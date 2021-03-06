#requires -version 2.0
Set-Alias od Get-HexDump

function Get-HexDump {
  <#
    .SYNOPSIS
        Get hex dump of a file.
    .DESCRIPTION
        If only file name has been specified then Get-HexDump creates full
        dump of a file.
    .PARAMETER FileName
        A file name to process.
    .PARAMETER BytesToProcess
        Counter of firsts bytes to dump.
    .PARAMETER WhatIf
        Test of function without its execution.
    .EXAMPLE
        PS C:\> Get-HexDump foo 512
        Reads first 512 bytes of "foo" file.
    .EXAMPLE
        PS C:\> (gi \bar\foo).FullName | od
        Send file name to Get-HexDump with pipeline.
    .INPUTS
        System.String - FileName
        System.UInt16 - BytesToProcess
    .OUTPUTS
        System.Array
    .LINK
        Get-Content
    .NOTES
        You can report me about bugs and issues at gregzakh@gmail.com
  #>
  [CmdletBinding(SupportsShouldProcess=$true,
                 DefaultParameterSetName="FileName")]
  param(
    [Parameter(Mandatory=$true,
               Position=0,
               ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$FileName,
    
    [Parameter(Mandatory=$false,
               Position=1)]
    [ValidateRange(0, 65535)]
    [UInt16]$BytesToProcess = 0
  )
  
  begin {
    [String]$ofs = ''
    [Int32]$line = 0
  }
  process {
    if (Test-Path $FileName) {
      if ($PSCmdlet.ShouldProcess("Dumps specified bytes of " + $FileName)) {
        gc -ea 0 -enc Byte $FileName -re 16 -to $BytesToProcess | % {
          '{0:X8} {1, -49} {2}' -f $line++, [String](
            $_ | % {' ' + ('{0:x}' -f $_).PadLeft(2, "0")}
          ), [String](
            $_ | % {
              if ([Char]::IsLetterOrDigit($_) -or [Char]::IsSymbol($_) `
                -or [Char]::IsPunctuation($_)) {[Char]$_}
              else {'.'}
            }
          )
        }
      }
    }
    else {Write-Warning "file not found or does not exist."}
  }
  end {}
}
