@@#Filename commands.ps1
import-module "G:\Documents\Speech Macros\custom.psm1"
import-module "G:\Documents\Speech Macros\alice.psm1"
Add-SpeechCommands @{
   "test command" 					= { Say $(Respond "3:2,4:0-2") }
   " * the percentages * " 			= { Say $(Percentages) }
   " * star date  * "		 		= { Say "Current, Star date, $("$((Get-Date).year).$([math]::round($((Get-Date).dayofyear)/365, 2)*100)" -replace "([A-Za-z0-9.]){1}","`$1 " -replace "\.","point")" }
   " * mail * " 					= { Start-Process "https://mail.google.com" }
   "Google * please" 				= { $term = $_ -replace "$Computer(.+?)Google (.+?) please", '$2'; Start-Process "http://www.google.com/search?q=$term" }
   "What * time * " 				= { Say "It is $(Get-Date -f "h:mm tt")" }
   "What is * time  * " 		 	= { Say "It is $(Get-Date -f "h:mm tt")" }
   "What time  * " 					= { Say "It is $(Get-Date -f "h:mm tt")" }
   " * some music * " 				= { Start-Process "grooveshark.exe" }
   "What * date today" 				= { Say $(Get-Date -f "dddd, MMMM dd") }
   #list processes
   "What's running?"  				= {
      $proc = ps | sort ws -desc
      Say $("$($proc.Count) processes, including $($proc[0].name), which is using " +
            "$([int]($proc[0].ws/1mb)) megabytes of memory")
   }
   #Word Definition
   " * the definition for * please" = {$define = $_ -replace "$Computer(.+?)the definition for (.+?) please", '$2' ;$outtext = Get-Definition("$define");Say "Definitions for $define, , , $outtext"}

   } -Computer "alice" -Verbose
#eof



@@#Filename custom.psm1

function Get-Definition($word) {
#.Synopsis
#	Polls wiktionary for top text definitons for a given $word input
#.Description
#  This Function parses the top $lines definitions for a given
#  $term into one string formatted for speech synthesis
# 
#
	Say "Sure"
	if($word -match " "){Say "Fail, one word at a time please"; break}
	$page = "http://simple.wiktionary.org/wiki/$word"
	$ie = new-object -com "InternetExplorer.Application"
	$ie.visible = $false
	$ie.navigate($page)
    while($ie.busy){Start-Sleep 1}
	$output = " "
	$lines = 0
	
    
    for($d=0;$d -le $lines;$d++) {  ## grab the definition strings from each table
       $ol 		= @($ie.Document.getElementsByTagName("ol"))[0]
       $li		= @($ol.getElementsByTagName("li"))[$d]
       $def 	= @($li.innerHTML)
       $output += "$def"
	   if($d -lt $lines){ $output += ", or, " }
    } 
	
    $ie.Quit()			
    $closeIE = [System.Runtime.Interopservices.Marshal]::FinalReleaseComObject($ie)	
    Remove-Variable ie  		
	return Clean-String($output)
}

function Clean-String([string]$str){
#.Synopsis
#  Cleans string from web (most concerned about x/html tags)
#.Description
#  Cleans input string of xml tags
#  returns $str
# 
#
	$str = $str -replace "\<[^<]*\>", " "
	$str = $str.replace("&nbsp", "")
	return $str
}

function Respond($in, [string]$del = ","){
#.Synopsis
#  Recursive.
#  Returns a random response from $responses via the three dimensional array of choices: $choices[<groups>][<dimensions>][<values>]
#  This function takes in a string indicating which responses from the $responses array
#  to to choose from. It supports ranges (-) and direct selections (/) in each seed separated by (,). 
#.Description
#  the idea here is to respond based on this format: $in = "3:2,4:1-2,0/2-4/6:1"
#  where 3:2 is a direct seed, 4:1-2 is a range seed (from 4:1 to 4:2), 
#  and 0/2-4/6:1 combines the two (effectively adds 0:1, 2:1, 3:1, 4:1, 5:1, 6:1 to the choices)
#  In heap, the above example would effectively add 3:2, 4:1, 4:2, 0:1, 2:1, 3:1, 4:1, 5:1, 6:1 to the
#  available choices, and will appear as $choices(@($xs(3),$ys(2)),@($xs(4),$ys(1,2)),@($xs(0,2,3,4,6),$ys(1)))
#
	switch -wildcard ($del){
        "`,"{
        
            if($in -match "`,"){   #if more than one coordset, handle each
                $coordsets = $in -split "`," #split coordsets apart
                foreach($coordset in $coordsets){
                    $choices += ,(Respond $coordset "`:")
                }
            }
            else{ #else pass the string to the next step,    
                $choices = ,(Respond $in "`:")       
            } 
            
            $choice = $choices[(get-random -min 0 -max $choices.count)] #choose one of the groups randomly
            
            $responses[$choice[0]][$choice[1]];#pass response out of the function
        }
        "`:"{
            $coords = $in -split "`:" #split coordset apart   
                foreach ($coord in $coords){                     
                    if(($coord -match "`/")-or($coord -match "`-")){            #if there's an or operator or a range
                        $dimensions += ,(Respond $coord "`/")      # handle them, and add all values (in array) to this dimension (split fails elegantly)
                    }
                    else{
                        $dimensions += ,$coord            #else just add the coord value (in an array) via comma operator
                    }
                }  
                
            $dimensions #pass dimensions out dimensions is two dimensional array
        }
        "`/"{
            $ranges = $in -split "`/" #split ORs apart (if theres not OR, the string is still added to $ranges[0])
            foreach($range in $ranges){
                if($range -match "`-"){#if theres a range to handle, do so
                    foreach ($val in (Respond $range "`-")){
                        $orVals += ,$val  #append all values in returned range array to new array
                    }
                }
                else{# else just append the value to teh new array
                    $orVals += ,$range
                }                  
			}
            
            ,($orVals | get-random) #pass out single element array of random value from vals array
		}
        "`-"{
            $vals = $in -split "`-" #split ranges apart
            
			$vals[0]..$vals[1] # pass out array containing all values in range        	            
		}
    }
}

$responses = (#Response Array
	(##0-correct 
		"Right",
		"Correct"
	),
	(##1-incorrect
		"Wrong",
		"Incorrect"
	
	),
	(##2-positive
		"Yes",
		"Aye",
		"I'll give it a shot"
	
	),
	(##3-negative
		"No",
		"Negative",
		"Not going to happen"
	
	),
	(##4-affirmation
		"Sure",
		"OK",
		"Lets See"
		
	),
	(##5-retort
		"your mom",
		"your face"
	
	),
	(##6-insult
		"You\'re dumb",
		"you fail"
	
	),
	(##7-eager
		"I'm ready",
		"Lets check it out"
	
	),
	(##8-apprehensive
		"I don't know",
		"Just a seck"
	
	),
	(##9-neutral
		"oh",
		"Hum"
	
	)
)
 
function Percentages {
#.Synopsis
#  Specific speech command that reads back
#  remaining percentages of year, month, week, and day
#.Description
#  Pretty self explanitory, basic maths, elucidatory var names
# 
#    

	$date                 = get-date                                                #capture date object
    $daysInYear           = [int]$(if([datetime]::IsLeapYear($date.year)){366}else{365}) #if leap year, 366, else 365
    $daysInMonth          = [int]$([datetime]::DaysInMonth($date.year, $date.month))     #capture days in month
    
    $dayOfYear            = [int]$date.dayofyear #days past (including today)
    $dayOfMonth           = [int]$date.day       #days past (including today)
    $hoursOfDay           = [int]$date.hour      #hours past (including current)
    $minutesOfHour        = [int]$date.minute    #minutes past (including current)
    
    switch ($date.dayofweek.toString()){ #assumes start of week is sunday
        Sunday    { [int]$dayOfWeek="1"; break }
        Monday    { [int]$dayOfWeek="2"; break }
        Tuesday   { [int]$dayOfWeek="3"; break }
        Wednesday { [int]$dayOfWeek="4"; break }
        Thursday  { [int]$dayOfWeek="5"; break }
        Friday    { [int]$dayOfWeek="6"; break }
        Saturday  { [int]$dayOfWeek="7"; break }
    }
    
    $percentYearGone      = $dayOfYear/$daysInYear                                #days of this year (including today) divided by total days in this year
    $percentMonthGone     = ((($dayOfMonth*24)-24)+$hoursOfDay)/($daysInMonth*24) #hours of this month divided by total hours in this month
    $percentWeekGone      = ((($dayOfWeek*24)-24)+$hoursOfDay)/(7*24)             #hours of this week divided by total hours in a week
    $percentDayGone       = ((($hoursOfDay*60)-60)+$minutesOfDay)/(24*60)         #minutes of today divided by total minutes in a day
    
    $percentYearLeft      = [math]::round((1-$percentYearGone)*100,1)           #opposite percentages rounded to one decimal place
    $percentMonthLeft     = [math]::round((1-$percentMonthGone)*100,1)          #^
    $percentWeekLeft      = [math]::round((1-$percentWeekGone)*100,1)           #^
    $percentDayLeft       = [math]::round((1-$percentDayGone)*100,1)            #^
    
    $str = ""
    $str += "There's "
    $str += $percentYearLeft
    $str += "% of this year, "
    $str += $percentMonthLeft
    $str += "% of this month, "
    $str += $percentWeekLeft
    $str += "% of this week, and "
    $str += $percentDayLeft
    $str += "% of today remaining, what will you do with it?"
    return $str
}
#eof
