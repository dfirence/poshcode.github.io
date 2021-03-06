function global:Move-FileSafely {
#.Synopsis
#  Moves files and folders from $source folder to $destination
#.Description 
#  Moves files from $source to $destination but if they already exist, it puts them in a parallel $BackupCopies folder instead
#.Parameter Source
#  The path to the source directory
#.Parameter Destination
#  The path to the destination. The CONTENTS of $source will be copied into this folder.
#.Parameter BackupCopies
#  The path to an alternate folder where files will be moved to if they already exist in the destination.
param($Source, $Destination, $BackupCopies=$(Join-Path $destination (Get-Date -f "backup yyyy-MM-dd")))
   function Test-CreateablePath {
      param($path)
      try {
         # if we can resolve the parent, then we'll be able to create this ...
         return Join-Path (Resolve-Path (Split-Path $path) -ErrorAction STOP) (Split-Path $path -Leaf)
      } catch {
         # otherwise, if it's a full absolute path, we'll be able to create it...
         return (split-path $path -isabsolute)
      }
   }
   
   $source = Resolve-Path $source -ErrorAction Stop # throw if source folder doesn't exist

   if(!(Test-CreateablePath $Destination)) {
      throw "Destination ($Destination) path must be a full path, or a subfolder of an existing folder"
   }
   if(!(Test-CreateablePath $BackupCopies)) {
      throw "BackupCopies ($BackupCopies) path must be a full path, or a subfolder of an existing folder"
   }

   mkdir $destination -Force -ErrorAction SilentlyContinue | Out-Null
   
   Get-ChildItem $source -recurse -ErrorAction SilentlyContinue | Move-Item -Destination { split-path $_.FullName.Replace($Source, $Destination) } -ErrorVariable Problems -ErrorAction SilentlyContinue
   foreach($file in $Problems | Select -Expand TargetObject | Where { Test-Path $_.FullName -Type Leaf }) { 
      $Target = $File.FullName.Replace($source, $backupCopies)
      mkdir (Split-Path $Target) -Force -ErrorAction SilentlyContinue | Out-Null
      move-item $File.FullName $Target
   }
   remove-item $source -Recurse -Force
}

