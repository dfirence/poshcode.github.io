<#
.SYNOPSIS
  Author:..Vidrine
  Date:....2013.01.14

.DESCRIPTION
  Thanks to http://jfrmilner.wordpress.com/  

  Specify target host and root directory.  The script will then recursively check for all folders and report on their NTFS permissions.
  Output is stored in a custom object, that is then exported to CSV.

  Script can easily be scaled to include processing multiple hosts, processing hosts imported from source file, process files instead of just folders, etc...
#>

$targetServer    = '\\ETH-470'    #Enter hostname
$targetDirectory = 'C:\Traces\Forms' #Enter directory name
$target          = Join-Path -ChildPath $targetDirectory -Path $targetServer
$arrResults      = @() #Initialize array used to store custom object output
$exportPath      = 'C:\temp\ntfsCheck2.csv' #Enter name of the CSV output file
 
#Query target directory for all 'folders' (excludes files via Where statement)
Get-ChildItem -Recurse -Path $target | Where { $_.PSIsContainer } |
forEach {
    $objPath = $_.FullName
    $coLACL  = Get-Acl -Path $objPath
    forEach ( $objACL in $colACL ) {
        forEach ( $accessRight in $objACL.Access ) {
            $objResults = New-Object –TypeName PSObject
            $objResults | Add-Member –MemberType NoteProperty –Name DirectoryPath      –Value $objPath
            $objResults | Add-Member –MemberType NoteProperty –Name Identity           –Value $accessRight.IdentityReference
            $objResults | Add-Member –MemberType NoteProperty –Name SystemRights       –Value $accessRight.FileSystemRights
            $objResults | Add-Member –MemberType NoteProperty –Name SystemRightsType   –Value $accessRight.AccessControlType
            $objResults | Add-Member -MemberType NoteProperty -Name IsInherited        -Value $accessRight.IsInherited
            $objResults | Add-Member -MemberType NoteProperty -Name InheritanceFlags   -Value $accessRight.InheritanceFlags
            $objResults | Add-Member –MemberType NoteProperty –Name RulesProtected     –Value $objACL.AreAccessRulesProtected
            $arrResults += $objResults
        }
    }
}
 
$arrResults | Export-CSV -NoTypeInformation -Path $exportPath
