param ( 
   [Parameter(Mandatory=$true,HelpMessage= "Enter souce folder path")] 
   [ValidateScript({Test-Path $_ -PathType Container})] 
   [string]$Src, 
   [Parameter(Mandatory=$true,HelpMessage= "Enter destination folder path")] 
   [ValidateScript({Test-Path $_ -PathType Container})] 
   [string]$Dst 
    
)

# Function to copy files according to last Modified date
function Copy-LatestFile { 
   Param( 
      [string]$File1, 
      [string]$File2, 
      [switch]$WhatIf 
   ) 
   $File1Date = Get-Item $File1 | Foreach-Object {$_.LastWriteTimeUTC} 
   $File2Date = Get-Item $File2 | Foreach-Object {$_.LastWriteTimeUTC} 
   if ($File1Date -gt $File2Date) { 
      Write-Host "$File1 is newer than $File2, performing copy." 
      if($WhatIf) { 
         Copy-Item $File1 $File2 -Force -WhatIf 
      } else { 
         Copy-Item $File1 $File2 -Force 
      } 
   } else { 
      Write-Host "$File2 is newer than $File1, performing copy." 
      if ($whatif) { 
         Copy-Item $File2 $File1 -Force -WhatIf 
      } else { 
         Copy-Item $File2 $File1 -Force 
      } 
   } 
   Write-Host 
} 
if(-Not(Test-Path $Destination)) { 
   New-Item $Destination -Type Directory -Force | Out-Null 
} 

# Getting Files/Folders from Source and Destination 
$SrcEntries = Get-ChildItem $Source -Recurse 
$DstEntries = Get-ChildItem $Destination -Recurse 

# Parsing the folders and Files from Collections 
$SrcFolders = $SrcEntries | Where-Object{$_.PSIsContainer} 
$SrcFiles = $SrcEntries | Where-Object{!$_.PSIsContainer} 
$DstFolders = $DstEntries | Where-Object{$_.PSIsContainer} 
$DstFiles = $DstEntries | Where-Object{!$_.PSIsContainer} 

# Checking for Folders that exist in Source, but are missing from Destination 
foreach ($Folder in $Srcfolders) { 
   $SrcFolderPath = $Source -replace "\\","\\" -replace "\:","\:" 
   $DstFolder = $Folder.Fullname -replace $SrcFolderPath,$Destination 
   if($DstFolder -ne "") { 
      if(-Not(Test-Path $DstFolder)) { 
         Write-Warning "Folder $DstFolder does not exist. Creating $DstFolder." 
         New-Item $DstFolder -Type Directory | Out-Null 
      } 
   } 
} 

# Checking for Folders that exist in Destinatinon, but are missing from Source 
foreach ($Folder in $DestFolders) { 
   $DstFilePath = $Destination -replace "\\","\\" -replace "\:","\:" 
   $SrcFolder = $Folder.Fullname -replace $DstFilePath,$Source 
   if ($srcFolder -ne "") { 
      if(-Not(Test-Path $SrcFolder)) { 
         Write-Warning "Folder $SrcFolder does not exist. Creating $SrcFolder." 
         New-Item $SrcFolder -Type Directory | Out-Null 
      } 
   } 
} 

# Checking for Files that exist in Source, but are missing from Destination 
foreach ($Entry in $SrcFiles) { 
   $SrcFullname = $Entry.FullName 
   $SrcName = $Entry.Name 
   $SrcFilePath = $Source -replace "\\","\\" -replace "\:","\:" 
   $DstFile = $SrcFullname -replace $SrcFilePath,$Destination 
   if(Test-Path $DstFile) { 
      $SrcMD5 = (Get-FileHash $SrcFullname).Hash 
      $DstMD5 = (Get-FileHash $DstFile).Hash 
      if ($SrcMD5 -ne $DstMD5) { 
         Write-Warning "File MD5 checksums do not match, deciding by last modified date." 
         Write-Host "MD5: $SrcMD5 File: $SrcFullname" 
         Write-Host "MD5: $DstMD5 File: $DstFile" 
         Copy-LatestFile $SrcFullname $DstFile 
      } 
   } else { 
      Write-Host "$DstFile does not exist, copying from $SrcFullname" 
      Copy-Item $SrcFullName $DstFile -Force 
   } 
} 

# Checking for Files that exist in Destinatinon, but are missing from Source 
foreach ($Entry in $DesFiles) { 
   $DstFullname = $entry.FullName 
   $DstName = $Entry.Name 
   $DstFilePath = $Destination -replace "\\","\\" -replace "\:","\:" 
   $SrcFile = $DstFullname -replace $DstFilePath,$Source 
   if ($SrcFile -ne "") { 
      if (-Not(Test-Path $SrcFile)) { 
         Write-Host "File $SrcFile does not exist, copying from $DstFullname." 
         Copy-Item $DstFullname $SrcFile -Force 
      } 
   } 
} 
