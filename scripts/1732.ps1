# Get data from factual.com. Currently you need an API key to even query data so you'll
# have to set one up before you can use this. Set your API key to the global variable
# APIKEY. Hopefully one day factual will allow reads without requiring API keys, which
# is why I chose not to make it an argument to the function.
#
# Note that table name must be the internal table name (e.g. Dbopve) and not any sort
# of name meaningful to humans.
Function Get-FactualData {
	param($tableName)

	$wc = New-Object Net.Webclient
	$url = "http://api.factual.com/v1/" + $APIKEY + "/tables/" + $tableName + "/read.xml"
	$xml = [xml]$wc.DownloadString($url)

	# Get the column titles.
	$nFields = $xml.result.response.fields.field.length - 1
	$fields = $xml.result.response.fields.field[1 .. ($nFields + 1)]

	# Create objects for each entry.
	$xml.result.response.data.row | Foreach {
		$t = "" | Select $fields
		foreach ($i in 1 .. $nFields) {
			$t.($fields[$i-1]) = $_.cell[$i]
		}
		Write-Output $t
	}
}

