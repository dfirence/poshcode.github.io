################################################
#
# Author:  Travis Kuntz <tkuntz2 at Google's mail service>
#
# Purpose: These functions convert a CSV file into an XLSX file.
#          There are several scripts to do this, but they did not fit my particular needs.
#          These functions are intended to provide an easy, reliable way to convert CSVs into the XML-based Excel format.
#          A feature of this function is GUI file selection and default values to enable wider distribution and use. 
#
# Usage:   Type convert-csv and press enter.
#          Convert-CSV [[-filename] <String>] [-outpath <String>] [<CommonParameters>]
#          Convert-CSV -filename c:\results\test.csv -outpath c:\scripts
#          Convert-CSV c:\results\test.csv c:\scripts  
#  
#################################################  

function Get-FileName($searchRoot){
<# 
  .SYNOPSIS
  This function provides GUI access to select a file path and name for a Powershell script.
  
  .DESCRIPTION
  This function is called through other functions.  It displays a popup and allows a user to choose a file.

  That file name and path can then be passed as a variable for insertion into another function, i.e. $var = get-filename.
  .EXAMPLE
  $somevariable = get-filename
  .EXAMPLE
  $var = get-filename | get-acl -path $var
  .PARAMETER initialDirectory
  This optional parameter can specify the directory in which the file browsing window starts.
#>
 
 #Load the .NET class that enables us to work with method System.Windows.Forms.OpenFileDialog.
 [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") |
 
 #Pipe informational messages into nothingness.
    Out-Null

 #Load file name and path through the GUI.
         $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
         $OpenFileDialog.initialDirectory = $searchRoot
         $OpenFileDialog.filter = "All files (*.*)| *.*"
         $OpenFileDialog.ShowDialog() | Out-Null
         $OpenFileDialog.filename
    }#End function Get-FileName


function Convert-CSV {
 <#
  .SYNOPSIS
    This function converts a *.csv file to a *.xlsx file.
  .DESCRIPTION
  Excel files, in order to adhere to an open-source standard, changed from a COM oriented file type to an XML file type.

  For that reason, this script initiates a COM object and silently launches Excel.

  Once Excel brings in the worksheet, we initiate a save through the API and silently close Excel.
  .EXAMPLE
  Type convert-csv and press enter.  A browse dialogue box is opened.  Choose your *.csv file.  The default save location is the original folder.
  .EXAMPLE
  convert-csv -filename c:\results\test.csv -outpath c:\scripts
  .EXAMPLE
  convert-csv c:\results\test.csv c:\scripts
  .PARAMETER filename
  The source CSV file you would like to convert to XLSX.
  .PARAMETER outpath
  The path in which you want the new XLSX file to be placed.
    #>
    [CmdletBinding()]
      param
      (
        [Parameter(Position=0)]
        [string]$filename,	
        [string]$outpath
      )
     
#Join the functions and initiate the first function if $filename is not null.
if ([string]::IsNullOrEmpty($filename)) {
       $filename = get-filename -searchroot "c:\"
    }
        
#Because Excel is COM-oriented, we must use this method.

#Initiate the object.
    $xl = new-object -comobject excel.application

#Do it without an Excel window.
    $xl.visible = $false

#Open a workboook with the CSV file.
        $Workbook = $xl.workbooks.open($filename)

#Grab worksheet one.
        $Worksheets = $Workbooks.worksheets

#Widen the column widths.
    $xl.columns.item(1).columnWidth = 27
    $xl.columns.item(2).columnWidth = 27
    $xl.columns.item(3).columnWidth = 27
    $xl.columns.item(4).columnWidth = 27

#Check for the $outpath parameter and assign it to $filename for name conversion.
    if ([string]::IsNullOrEmpty($outpath)) {
       $outpath = (split-path $filename -parent)
    }

#Split the file path name and reconcatenate with the .xlsx extension.
    $filepath = split-path $filename -parent
    $basename = (get-item -path $filename).BaseName
    $excelfile = ("$outpath" +"\" + "$basename" + ".xlsx")
    

#The 51 at the end of this line saves it in the XLSX format.
#Perform the Save.
        $Workbook.SaveAs("$excelfile",51)
        $Workbook.Saved = $True

#Close Excel.
    $xl.Quit()
    
}#End function Convert-CSV
