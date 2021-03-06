function ConvertFrom-QuotedPrintable {
	[OutputType([string])]
	[CmdletBinding()]
	param(
		[Parameter(ValueFromPipeline)]
		[string]$InputObject
,
		[Parameter(Mandatory)]
		[System.Text.Encoding]$Encoding = [System.Text.Encoding]::UTF8
	)
	begin {
		$buf = ''
	}
	process {
		$buf += [regex]::Replace(
			[regex]::Replace($InputObject, "=[ `t]*(?:`r`n|`n|\z)", ''),
			'=[0-9a-fA-F]{2}',
			[System.Text.RegularExpressions.MatchEvaluator]{[string][char][int]::Parse($args[0].Value.Substring(1), [System.Globalization.NumberStyles]::AllowHexSpecifier)}
		)
	}
	end {
		$Encoding.GetString([byte[]][char[]]$buf)
	}
}
