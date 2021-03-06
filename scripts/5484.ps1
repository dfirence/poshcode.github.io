<#
.NOTES 
Name: Number of VLFs
Author: Rob Sewell http://sqldbawithabeard.com
Requires: 
Version History: 
.Synopsis
Number of VLFs and AUtogrowth for every database log file
.DESCRIPTION
This script iterates through a list of servers and writes to Excel
some information about each database log file. It will alter the 
colour of the cell depending on the paramters you set at the top of the
script
.EXAMPLE
Define the location of the servers on Line 30

$Servers = Get-Content "PATHTOSERVERSFILE.txt"

or (alter locations to fit)
$Query = "SELECT Name FROM dbo.databases"
$Servers = Invoke-Sqlcmd -ServerInstance MANAGEMENTSERVER -Database DBADATABASE -Query $query

Define the parameters on line 30 & 31
.NOTES

This script WILL STOP ALL Excel processes
#>

#Set the variables
$Servers = Get-Content 'PATHTO\sqlservers.txt'
$TooMany = 25 #How many VLFs is too many
$wayTooMany = 50   #How many VLFs is WAY too many

# Create a .com object for Excel
$xl = new-object -comobject excel.application
$xl.Visible = $true # Set this to False when you run in production


$wb = $xl.Workbooks.Add() # Add a workbook
$ws = $wb.Worksheets.Item(1) # Add a worksheet 
$cells=$ws.Cells
$Row = 3
$Col = 2
$Date = Get-Date
$Title = 'Results of Script to show VLFs and File Growth run on ' + $Date
$cells.item(2,2)="Server"
$cells.item(2,2).font.size=16
$cells.item(2,3)="Database"
$cells.item(2,3).font.size=16
$cells.item(2,4)="No. of VLFs"
$cells.item(2,4).font.size=16
$cells.item(2,5)="Growth"
$cells.item(2,5).font.size=16
$cells.item(2,6)="Growth Type"
$cells.item(2,6).font.size=16
$cells.item(2,7)="Size"
$cells.item(2,7).font.size=16
$cells.item(2,8)="Used Space"
$cells.item(2,8).font.size=16
$cells.item(2,9)="Name"
$cells.item(2,9).font.size=16
$cells.item(2,10)="File Name"
$cells.item(2,10).font.size=16

foreach ($Server in $Servers)
{  
	$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $Server
	foreach ($db in $srv.Databases|Where-Object {$_.isAccessible -eq $True})
	{
		$Col = 2
		$Row++
		$VLF = $DB.ExecuteWithResults("DBCC LOGINFO").Tables[0].Rows.Count
		$logFile = $db.LogFiles | Select Growth,GrowthType,Size, UsedSpace,Name,FileName
		$Name = $DB.name
		$cells.item($row,$col)=$Server
		$col++
		$cells.item($row,$col)=$Name
		$col++
		if($VLF -gt $TooMany) 
		{
			$cells.item($row,$col).Interior.ColorIndex = 6 # Yellow
		}
		if($VLF -gt $WayTooMany)
		{
			$cells.item($row,$col).Interior.ColorIndex = 3 # Red
		}
		$cells.item($row,$col)=$VLF
		$cells.item($row,$col).HorizontalAlignment = 3 #center
		$col++
		$cells.item($row,$col)=$logFile.Growth
		$cells.item($row,$col).HorizontalAlignment = 4 #right
		$col++
		$Type = $logFile.GrowthType.ToString()
		if($Type -eq 'Percent')
		{
			$cells.item($row,$col).Interior.ColorIndex = 3 #Red
		}
		$cells.item($row,$col)=$Type
		$cells.item($row,$col).HorizontalAlignment = 4 #right
		$col++
		$cells.item($row,$col)=($logFile.Size)
		$cells.item($row,$col).HorizontalAlignment = 3 #center
		$col++
		$cells.item($row,$col)=($logFile.UsedSpace)
		$cells.item($row,$col).HorizontalAlignment = 3 #center
		$col++
		$cells.item($row,$col)=$logFile.Name
		$col++
		$cells.item($row,$col)=$logFile.FileName
	}
	$Row++
}
$ws.UsedRange.EntireColumn.AutoFit()
$cells.item(1,2)=$Title 
$cells.item(1,2).font.size=24
$cells.item(1,2).font.bold=$True
$cells.item(1,2).font.underline=$True
$Date = Get-Date -f ddMMyy
$filename = 'VLF' + $Date
$wb.Saveas("C:\temp\$filename.xlsx")
$xl.quit()
Stop-Process -Name EXCEL
