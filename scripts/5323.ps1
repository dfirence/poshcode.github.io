#############################################################################################
#
# NAME: Add-BeginningContent.ps1
# AUTHOR: Rob Sewell http://sqldbawithabeard.com
# DATE:21/07/2014
#
# COMMENTS: This script recurses through the directory in the $path variable checks which files 
#           have the required patterns defined by the select-strings, adds the value in
#           $Header Variable and opens the file for checking before pausing
#
# USAGE: Define the Path variable for the directory of your files
#        Define the Select-string to help define the searches. If you wish to use all files
#        delete or comment out lines 25 to 31 and alter line 22 to $Diffs = $Names
#        Define the Header variable to include the string you wish to add at the top 
#        If you wish to remove the user interaction delete or comment Line 62
#

# Set variable for directory
$path = 'E:\SkyDrive\Documents\Scripts\Powershell Scripts\Functions\'
$Files = Get-ChildItem -Path $path -Recurse

$Names = $Files|select name, FullName

# Search for multiple entries in the files this can be commented out
$Matchs = $files |
  where { $_ | Select-String -Pattern "###"  } |
  where { $_ | Select-String -Pattern "# NAME:" } |
   where { $_ | Select-String -Pattern "# AUTHOR:" } |
    where { $_ | Select-String -Pattern "# DATE:" } |
     where { $_ | Select-String -Pattern "# COMMENTS:" } |
      where { $_ | Select-String -Pattern "# USAGE:" } |select name,FullName

      #Choose the files which do not have all of the search terms

      $Diffs = $Names  | Where-Object {$Matchs.Name -notcontains  $_.Name}


      foreach($Diff in $Diffs)
      {
      $ScriptName = $Diff.Name
      # read the file into a variable
      $Old = Get-Content $Diff.FullName
      # Set the Header
      $Header = "#############################################################################################
#
# NAME: " + $ScriptName + "
# AUTHOR: Rob Sewell http://sqldbawithabeard.com
# DATE:21/07/2014
#
# COMMENTS: 
#
# USAGE: 
#
      "
      #Add Header
      Set-Content -Path $FileName -Value $Header
      #Add Original File contents
      Add-Content -Path $FileName -Value $Old 
      # Open File for checking/completing
      Invoke-Item $FileName
      # wait for user input this can be commented out
      pause
      }
