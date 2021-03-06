function Set-Extension { 
#.Synopsis
#  Change the extension on file paths
#.Example
#  ls *.ps1 | Set-Extension bak | ls
#
#  Lists all .bak files that correspond to .ps1 scripts
#.Example
#  ls *.txt | move -dest { Set-Extension log -path $_.PSPath }
#
#  Renames all .txt files by changing their extension to .log
#.Example
#  ls *.txt -Rename
#
#  Renames all .txt files by changing their extension to .log
#.Parameter Path
#  The file path to change the extension on
#.Parameter Extension
#  The new extension to use
#.Parameter Rename
#  Actually rename the file instead of just outputting the altered path
param(
   [Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
   [Alias("FullName")]
   [string]$Path
,
   [Parameter(Mandatory=$true,Position=0)]
   [string]$Extension
,
   [Parameter()]
   [switch]$Rename
,
   [Parameter()]
   [switch]$Passthru
) 
process { 
   if($Rename) {
      Move-Item -Literal $Path -Destination ([IO.Path]::ChangeExtension($path, $extension)) -Passthru:$Passthru
   } else {
      [IO.Path]::ChangeExtension($path, $extension) 
   }
}
}
