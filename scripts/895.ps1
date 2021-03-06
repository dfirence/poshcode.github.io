function Split-String {
#.Synopsis
#  Split a string and execute a scriptblock to give access to the pieces
#.Description
#  Splits a string (by default, on whitespace), and assigns it to $0, and the first 9 words to $1 through $9 ... and then calls the specified scriptblock
#.Example
#  echo "this is one test ff-ff-00 a crazy" | split {$2, $1.ToUpper(), $6, $4, "?"}
#
#  outputs 5 strings: is, THIS, a, test, ?  
#
#.Example
#  echo "this is one test ff-ff-00 a crazy" | split {$0[-1]}
#
#  outputs the last word in the string: "crazy"
#
#.Parameter pattern
#  The regular expression to split on. By default "\s+" (any number of whitespace characters)
#.Parameter action
#  The scriptblock to execute.  By default {$0} which returns the whole split array
#.Parameter InputObject
#  The string to split
[CmdletBinding(DefaultParameterSetName="DefaultSplit")]
Param(
   [Parameter(Position=0, ParameterSetName="SpecifiedSplit")]
   [string]$pattern="\s+"
,
   [Parameter(Position=0,ParameterSetName="DefaultSplit")]
   [Parameter(Position=1,ParameterSetName="SpecifiedSplit")]
   [ScriptBlock]$action={$0}
,
   [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
   [string]$InputObject
)
BEGIN {
   if(!$pattern){[regex]$re="\s+"}else{[regex]$re=$pattern}
}
PROCESS {
   $0 = $re.Split($InputObject)
   $1,$2,$3,$4,$5,$6,$7,$8,$9,$n = $0
   &$action
}
}
   
 
# #This one is v1-compatible
# function Split-String {
# Param([scriptblock]$action={$0},[regex]$split=" ")
# PROCESS {
#    if($_){
#       $0 = $split.Split($_)
#       $1,$2,$3,$4,$5,$6,$7,$8,$9,$n = $0
#       &$action
#    }
# }
# }


 
 
 
 
 
 
 



