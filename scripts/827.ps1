<#
.Synopsis
	Outputs .NET exception information along with their summary information if available.
.Description
	Spins all loaded types in all loaded assemblies and will return any Exception types that
	match the filter if specified. Because the script only spins loaded assemblies, if you want
	the script to search additional assemblies, you must load them yourself using
	[System.Reflection.Assembly]::Load or related method.
.Notes
NAME:    Get-Exception
AUTHOR:  David Mohundro
URL:     http://www.mohundro.com/blog/
#>

param (
	$filter = ''
)

if ($filter -ne '') {
	$filter = ".*$filter"
}

$exceptions = [System.AppDomain]::CurrentDomain.GetAssemblies() | foreach { 
	$_.GetTypes() | where { $_.FullName -match "System$filter.*Exception$" }
}

$exceptions | foreach {
	$type = $_
	$doc = $_.Assembly.Location.Replace("dll", "xml")
	$summary = 'No summary found.'

	if (Test-Path $doc) {
		$xpath = "/doc/members/member[@name='T:$_']"
		Write-Verbose "Found: $doc"
		Write-Verbose "XPath to use is: $xpath"

		$xml = [xml]$(Get-Content $doc)
		$nodes = $xml.SelectNodes($xpath)

		$nodes | foreach { 
			$summary = $_.summary
		} 
	}

	$result = New-Object PSObject

	$result | 
	Add-Member NoteProperty Name $type.FullName -pass |
	Add-Member NoteProperty Summary $summary

	$result
}

