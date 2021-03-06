### Finding tabs:
$file =  "C:\data\test1.xlsx"

$objExcel = new-object -comobject excel.application 
$objExcel.Visible = $True 
 
#Opening Excel file listed above
$objWorkbook = $objExcel.Workbooks.Open($file) 

#this is the tab name you are looking for
$test = "newtesttab" 

$requireNewTab = 0
#Cycle through and test if tab already exists
do {
	$c = $objWorkbook.worksheets.Item($i).name
	$c
	if ($c -eq $test) {
		#Action taken when tab is found
		write-host "$test Alrady exists"
		
		#Changes value of $requireNewTab to 1 showing that there is already a tab with that name
		$requireNewTab = 1
	}
	$i++
}
while ($i -le $objWorkbook.worksheets.count)

#If $requireNewTab is set to 0 it adds a tab with the tab name
if (0 -eq $requireNewTab){
	write-host "inside if statment"
	$a = $objWorkbook.worksheets.add()
	$a.name = $test

}


#####  Finding last row:
$xlup = -4162
$file =  "C:\data\test1.xlsx"

 
$objExcel = new-object -comobject excel.application 
$objExcel.Visible = $True 

$objWorkbook = $objExcel.Workbooks.Open($file) 

$ExcelWorksheet = $objWorkbook.worksheets.Item(1)
$lastRow = $ExcelWorksheet.cells.Range("A1048576").End($xlup).row

#Value of the last row that has data in it.
$lastRow

#value of next available row to add data.
$nextRow = $lastRow + 1
