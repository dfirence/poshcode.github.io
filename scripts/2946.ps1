function Get-MacAddressOui {
<#
	.SYNOPSIS
		Gets a MAC address OUI (Organizationally Unique Identifier).

	.DESCRIPTION
		The Get-MacAddressOui function retrieves the MAC address OUI reference list maintained by the IEEE standards website and
		returns the name of the company to which the MAC address OUI is assigned.

	.PARAMETER MacAddress
		Specifies the MAC address for which the OUI should be retrieved.

	.EXAMPLE
		Get-MacAddressOui 00:02:B3:FF:FF:FF
		Returns the MAC address OUI and the company assigned that idenifier.

	.INPUTS
		System.String

	.OUTPUTS
		PSObject

	.NOTES
		Name: Get-MacAddressOui
		Author: Rich Kusak (rkusak@hotmail.com)
		Created: 2011-09-01
		LastEdit: 2011-09-06 19:09
		Version: 1.0.3.0

	.LINK
		http://standards.ieee.org/develop/regauth/oui/oui.txt

	.LINK
		about_regular_expressions

#>

	[CmdletBinding()]
	param (
		[Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
		[ValidateScript({
			# Builds regex patterns for the 4 MAC address hex formats
			$patterns = @(':', '-', $null) | ForEach {"^([0-9a-f]{2}$_){5}([0-9a-f]{2})$"}
			$patterns += '^([0-9a-f]{4}\.){2}([0-9a-f]{4})$'

			if ($_ -match ($patterns -join '|')) {$true} else {
				throw "The argument '$_' does not match a valid MAC address format."
			}
		})]
		[string]$MacAddress
	)
	
	begin {
	
		$uri = 'http://standards.ieee.org/develop/regauth/oui/oui.txt'
		$webClient = New-Object System.Net.WebClient
		
		try {
			Write-Debug "Performing operation 'DownloadString' on target '$uri'."
			$ouiReference = $webClient.DownloadString($uri)
		} catch {
			throw $_
		}
		
		$properties = 'MacAddress', 'OUI', 'Company'

	} # begin
	
	process {
	
		$oui = ($MacAddress -replace '\W').Remove(6)
		$regex = "($oui)\s*\(base 16\)\s*(.+)"
		
		New-Object PSObject -Property @{
			'MacAddress' = $MacAddress
			'OUI' = $oui
			'Company' = [regex]::Match($ouiReference, $regex, 'IgnoreCase').Groups[2].Value
		} | Select $properties
	
	} # process
} # function Get-MacAddressOui

