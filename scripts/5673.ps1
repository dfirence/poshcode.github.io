#Returns the priority mail server (SMTP) for a particular email address.
function Get-MX {
param([string] $domain = $( Throw "Query required in the format domain.com or email@domain.com.") )
	
	#rip domain out of full email address if necessary:
	if ($domain.IndexOf("@")) { $domain = $domain.SubString($domain.IndexOf("@")+1) } 
	  	
  #get all the MX records for this domain, sorted by descending preference 
  $mxrecords = @(get-dns $domain -type MX | sort-object -Property PREFERENCE -des)
  
  #verify that there are some records
  if ($mxrecords.Length -eq 0) { Throw "No records found." }
  	
  #The correct record is the one with the lowest preference:
  $mxrecords[0].EXCHANGE
}
