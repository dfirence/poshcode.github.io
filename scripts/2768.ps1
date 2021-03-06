## NAME: Get-Dirty.ps1 
## AUTHOR: Barry Morrison 
## LASTEDIT: 07/05/2011 16:18:33 
<#
   .Synopsis 
       Get's files from today's date.  Will also return narrowed results based on keyword
   .Description
        Get's files from today's date.  Will also return narrowed results based on keyword
   .Parameter Path 
        Will run in current directory.  Path argument will allow you to define a path not in current working directory
   .Parameter Keyword
        Keyword argument will allow you to define a keyword to search on to narrow results.
   .Example 
        PS C:\scripts> .\dirtoday.ps1


    			Directory: C:\scripts


						Mode                LastWriteTime     Length Name
						----                -------------     ------ ----
						-a---          7/5/2011   3:25 PM        114 cat
						-a---          7/5/2011   4:11 PM       2252 dirtoday.ps1
						-a---          7/5/2011   3:46 PM        848 dirtoday2.ps1
						-a---          7/5/2011   2:55 PM        110 info.txt
						-a---          7/5/2011   1:52 PM         37 test.foo


   .Example 
        PS C:\scripts> .\dirtoday.ps1 -path "c:\Users\John Doe\Pictures"


    		Directory: C:\Users\John Doe\Pictures


					Mode                LastWriteTime     Length Name
					----                -------------     ------ ----
					-a---          7/5/2011  11:05 AM      49888 weinerdog.jpg
					
					
   .Example 
        PS C:\scripts> .\dirtoday.ps1 -keyword foo

			cat:2:test.foo:1:blah, blah, foo, ice cream,
			test.foo:1:blah, blah, foo, ice cream,
     
#>


param(
	[string]$Path = "",
	[string]$keyword = ""
	)

## Checking to see if the Keyword argument is passed -- If it is, search for $keyword
if ($keyword) {
	$files = dir -Path $path | Where-Object { $_.lastwritetime -ge (get-date).date } | Select-String $keyword
			## If there are not results returned, tell me!  
			if (!$files) {
				Write-Output "Nothing Here"
			}else{
				## If Results exist, give them to me!  
				$files
				}
	} else {
	## If not keyword argument is passed, do a simple search	
	$files = dir -Path $path | Where-Object { $_.lastwritetime -ge (get-date).date }
			## Like above, checking to see if no results are found for the query
			if (!$files) {
				## Tell me if nothing exists
				Write-Output "Nothing Here"
			}else{
				## Write results if something exists
				$files
				}
			
		}
