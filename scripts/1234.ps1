# TITLE: 	Get-SameTimeChatHistory.ps1
# PURPOSE:	Reads Sametime R8 chat transcript HTML files and outputs custom objects
# AUTHOR:	Hal Rottenberg <hal@halr9000.com

# OUTPUT: 
# - [datetime] Timestamp - can be easily filtered
# - [string] LastName
# -	[string] FirstName
# -	[string] Message
#
# REQUIREMENTS:
# - Must install PoshHttp snapin to use the ConvertFrom-Html cmdlet
#   http://huddledmasses.org/get-web-another-round-of-wget-for-powershell/
#   (Cmdlet needed because the HTML files won't cast to XML nicely.)
# - Sametime R8 chat client transcripts
# 
# TODO:
# - each session needs an index to aid with sorting & grouping
# - parameters to limit transcripts by name or date
# - there's a minor null index bug somewhere
# - automatically determine location of transcripts

param (
	$TranscriptPath = "$env:userprofile\SametimeTranscripts"
)

# get all chat transcript files
$html = Get-ChildItem -Recurse -Path $TranscriptPath -Filter *.html
$html | Foreach-Object { 
	# convert contents of each HTML file to XML using PoshHttp cmdlet
	$xml = $_ | Get-Content | ConvertFrom-Html
	# each XML object represents a single chat session with a single contact
	$xml | Foreach-Object {
		# each chat session has multiple message blocks
		$mb = $_.html.body.div[1].div 
		$day = $mb[0].InnerText # first record in block is the day the chat occurred
		$mb[1..$mb.Length] | Foreach-Object {
			$_ | Foreach-Object {
				$out = "" | Select-Object Timestamp, LastName, FirstName, Message
				# username field is an ugly LDAP CN field that needs fixing
				$uname = $_.username -split '/' -replace '\\' -replace ' '
				$out.LastName 		= $uname[0]
				$out.FirstName		= $uname[1]
				$out.Timestamp 		= [datetime]( $day + " " + $_.div[0].nobr )
				$out.Message 		= $_.div[2].span[0]."#text"
				Write-Output $out
			} 
		} 
	}
} 
