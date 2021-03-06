#requires -version 4
function Get-ZipContent {
  <#
    .SYNOPSIS
        Reads ZIP file data.
    .DESCRIPTION
        Function gets data with BinaryReader instead COM Shell.Application.
    .EXAMPLE
        PS E:\downloads> Get-ZipContent SysinternalsSuite.zip | Format-Table -a

        Crc32      Attributes Modified            Method    Path                 Packed    Size
        -----      ---------- --------            ------    ----                 ------    ----
        0x0A1AC525          0 01.11.2006 14:06:36 {Deflate} AccessEnum.exe        48346  174968
        0x5A4797E5          0 12.07.2007 6:26:48  {Deflate} AdExplorer.chm        42823   50379
        0xAFDD017F          0 14.11.2012 11:22:40 {Deflate} ADExplorer.exe       203304  479832
        ...
  #>
  param(
    [Parameter(Mandatory=$true)]
    [ValidateScript({Test-Path $_})]
    [String]$PathName
  )
  
  begin {
    $PathName = Convert-Path $Pathname
    $Methods  = @{
      Store   = 0
      Deflate = 8
      BZIP2   = 12
      LZMA    = 14
    }
  }
  process {
    try {
      $fs = [IO.File]::OpenRead($PathName)
      $br = New-Object IO.BinaryReader($fs)
      $fs.Position = $fs.Length - 22
      # locate of start of central directory
      $fs.Position += 16
      $fs.Position = $br.ReadUInt32()
      # read certral directories data
      while ($true) {
        if ($br.ReadUInt32() -ne 33639248) {break}
        $fs.Position += 6 # skip next three fields
        # compressed method and last modification datetime
        $a, $b, $c = $br.ReadUInt16(), $br.ReadUInt16(), $br.ReadUInt16()
        # crc32 and [un]compressed size(s)
        $d, $e, $f = $br.ReadUInt32(), $br.ReadUInt32(), $br.ReadUInt32()
        $g = $br.ReadUInt16() # file name length
        $h = $br.ReadUInt16() # extra field length
        $i = $br.ReadUInt16() # file comment length
        $fs.Position += 4     # skip next two fields
        $j = $br.ReadUInt32() # external file attributes
        $fs.Position += 4     # skip next field
        New-Object PSObject -Property @{
          Path = -join $br.ReadChars($g)
          Attributes = [IO.FileAttributes]$j
          Crc32 = "0x$($d.ToString('X8'))"
          Modified = New-Object DateTime(
            (($c -shr 9) + 1980), (($c -shr 5) -band 0xf), ($c -band 0x1f),
            ($b -shr 11), (($b -shr 5) -band 0x3f), (($b -band 0x1f) * 2)
          )
          Size = $f
          Packed = $e
          Method = $Methods.Keys.Where({$Methods.Item($_) -eq $a})
        }
        $fs.Position += $h + $i
      }
    }
    catch {
      $_.Exception.InnerException
    }
    finally {
      if ($br -ne $bull) {$br.Close()}
      if ($fs -ne $null) {$fs.Close()}
    }
  }
  end {}
}
