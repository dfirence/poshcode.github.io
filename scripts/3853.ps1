#Initialize Global Variables
$NumYears = 0
$NumMonths = 0
$NumDays = 0
$LeapYearTest = 0
$FirstDate = ''
$LastDate = ''
$LastDateFeb = ''
$destination = Join-Path $env:USERPROFILE '\Desktop\Export Data' #Tells program where to write directory structure

#Get the first date from user
$FirstDate = Read-host "Please enter the beginning date in the format 'YYYY/MM/DD' "
#Error checking date input
$FirstDate = $FirstDate -as [DateTime];
if (!$FirstDate)	#If not valid date, give error and exit
{  
    Write-host 'You have entered an invalid date, please check the date format and try again'
    exit 1
}
#Get the last date from user
$LastDate = Read-host "Please enter the beginning date in the format 'YYYY/MM/DD' "
#Error checking date input
$LastDate = $LastDate -as [DateTime];
if (!$LastDate)		#If not valid date, give error and exit
{  
    Write-host 'You have entered an invalid date, please check the date format and try again'
    exit 1
}

#Loop Structure for Creation of Directores
While ( ( Get-Date $FirstDate ).AddDays( $NumDays ) -le ( Get-Date $LastDate ) ) {
#Next line creates path in the form of YYYY\MM-MMMM\YYYY-MM-DD
	$path = Join-Path -Path (Join-Path -Path ( Join-Path -Path $destination -ChildPath ( Get-Date $FirstDate ).AddYears( $NumYears ).ToString( 'yyyy' ) ) -ChildPath ( Get-Date $FirstDate ).AddMonths( $NumMonths ).ToString( 'MM-MMMM' ))-ChildPath ( Get-Date $FirstDate ).AddDays( $NumDays ).ToString( 'yyyy-MM-dd' ) 
#Next line creates the directory using the path
    New-Item -Path $path -ItemType 'Directory'
#Leap Year Testing to get correct end date for the month of February calling on dotNet Framework function IsLeapYear
	$LeapYearTest = ( Get-Date $FirstDate ).AddYears( $NumYears )
	if ([datetime]::IsLeapYear($LeapYearTest.Year) -eq 'True') { $LastDateFeb = '29-Feb' }	#If leap year test is true then end of Feb is 29th
	else { $LastDateFeb = '28-Feb' }														#If leap year test is false then end of Feb is 28th
#Condition testing to determine the end of the month, switching to next month and next year
	switch ((Get-Date $FirstDate).AddDays($NumDays).ToString('dd-MMM'))
	{
	'31-Jan' {$NumMonths++ } 
	"$LastDateFeb" {$NumMonths++ }
    '31-Mar' {$NumMonths++ }
	'30-Apr' {$NumMonths++ }
	'31-May' {$NumMonths++ }
	'30-Jun' {$NumMonths++ }
	'31-Jul' {$NumMonths++ }
	'31-Aug' {$NumMonths++ }
	'30-Sep' {$NumMonths++ }
    '31-Oct' {$NumMonths++ }
	'30-Nov' {$NumMonths++ }
	'31-Dec' {
			$NumMonths++
			$NumYears++ 
			}
	}
	$NumDays++
	}
