#requires -version 2.0
PARAM ( 
   [Parameter(Position=1, Mandatory=$true)]
   [ValidateSet("wmv","wmvhigh","ppt")] # the "mp4" files aren't there yet
   [String]$MediaType,
   [string]$Destination = $PWD
)
Import-Module BitsTransfer
Push-Location $Destination
$Extension = $(switch -wildcard($MediaType){"wmv*"{"wmv"} "mp4"{"mp4"} "ppt"{"pptx"}})
$BaseUrl = "http://ecn.channel9.msdn.com/o9/pdc09/{0}/{2}.{1}"

Start-BitsTransfer -TransferType Download -Source @(
   "CL09","CL18","FT02","FT06","FT11","PR05","SVC01","SVC10","SVC20","SVR03","CL30","CL33","FT30",
   "FT31","PR31","SVC30","SVC37","SVR33","VTL30","VTL32","CL04","CL14","CL25","FT18","FT19","FT25",
   "PR02","SVC13","SVR01","SVR14","CL13","CL29","FT10","FT28","FT57","PR11","SVC52","SVR15","SVR17",
   "CL11","CL17","CL23","FT03","FT08","PR10","SVR16","VTL01","CL01","FT50","FT52","FT55","FT59","PR13",
   "SVC02","SVC03","SVC15","CL31","CL34","FT32","FT34","FT36","SVC31","SVC32","SVR31","VTL31","CL15",
   "FT12","FT17","FT58","SVC16","SVC28","SVC53","SVR11","VTL05","CL06","FT04","FT07","FT29","PR06",
   "SVC09","SVC17","SVR13","VTL04","CL12","CL22","FT22","FT23","FT26","SVC04","SVC14","SVC19","SVC54",
   "SVR12","CL02","CL05","CL16","FT21","FT56","PR03","SVC08","SVC18","SVR10","VTL03","CL10","FT13",
   "FT53","FT60","PR07","SVC06","SVC25","SVR07","SVR18","VTL02","CL03","CL21","CL27","FT14","FT20",
   "FT24","PR09","SVC12","SVR09","SVR19","CL32","CL35","CL36","FT33","FT35","PR30","PR33","SVC33",
   "SVC36","SVR32","CL07","CL24","CL28","FT09","FT16","FT27","PR12","SVC27","SVR02","SVR06","CL26",
   "FT05","FT54","PR01","PR14","SVC23","SVC26","SVR08","KYN01-PGM","KYN02-PGM" | 
   ForEach { $BaseUrl -f  $MediaType, $Extension, $_ }
)
Pop-Location

