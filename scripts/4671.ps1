#.Synopsis
#  Port of Chris Veness' AES CTR (AES Counter Mode) Aes.Ctr.decrypt
#.Description
#  This cmdlet will decrypt text encypted with Aes.Ctr.encrypt from:
#  http://www.movable-type.co.uk/scripts/aes.html
#
#  Useful for web scraping since that library is popular on websites.
#
#.Example
#  ConvertFrom-AesCtr 'dQMbtNJqolJkPwoC7sejtg==' 'asdf' 256
#.Parameter Cypher
#  Message you want to decrypt.
#.Parameter Password
#  Password to use to decrypt the $Cypher.
#.Parameter Size
#  Block size to use.
#.Parameter InRaw
#  If set, $Cypher is assumed to be a [byte[]] blob. Otherwise, it is
#  assumed to be a [byte[]] blob converted to a base64 encoded [string].
#.Parameter OutRaw
#  If set, the return value is outputted as a binary blob. Otherwise, it
#  is assumed to be a utf-8 encoded str converted to a [string].
function ConvertFrom-AesCtr {
	[OutputType([string], [System.ArraySegment[byte]])]
	param(
		[Parameter(Mandatory)]
		$Cypher
,
		[Parameter(Mandatory)]
		[string]$Password
,
		[ValidateSet(128, 192, 256)]
		[int]$Size = 256
,
		[switch]$InRaw
,
		[switch]$OutRaw
	)
	try {
		[int]$Size = $Size -shr 3

		if ($InRaw) {
			[byte[]]$Cypher = $Cypher
		} else {
			[byte[]]$Cypher = [System.Convert]::FromBase64String($Cypher)
		}

		[byte[]]$Password = [System.Text.Encoding]::UTF8.GetBytes($Password)
		[array]::Resize([ref]$password, $Size)

		$aes = [System.Security.Cryptography.Aes]::Create()
		$aes.Mode = [System.Security.Cryptography.CipherMode]::ECB
		$aes.Padding = [System.Security.Cryptography.PaddingMode]::Zeros
		$aes.Key = $Password
		$enc = $aes.CreateEncryptor()
		[byte[]]$Password = $enc.TransformFinalBlock($Password, 0, $Password.Length)

		[array]::Resize([ref]$Password, $Size)
		[array]::Copy($Password, 0, $Password, 16, $Size - 16)

		$aes.Key = $Password
		$enc = $aes.CreateEncryptor()

		$Password = New-Object byte[] 16
		[array]::Copy($Cypher, $Password, 8)

		foreach ($i in 0..[Math]::Floor(($Cypher.Length - 9) / 16)) {
			$Password[15] = $i -band 255
			$Password[14] = ($i -shr 8) -band 255
			$Password[13] = ($i -shr 16) -band 255
			$Password[12] = $i -shr 24

			$aes = $enc.TransformFinalBlock($Password, 0, 16)
			$i = $i * 16 + 8
			foreach ($b in 0..[Math]::Min(15, $Cypher.Length - $i - 1)) {
				$Cypher[$i+$b] = $Cypher[$i+$b] -bxor $aes[$b]
			}
		}

		if ($OutRaw) {
			,(New-Object System.ArraySegment[byte] @($Cypher, 8, ($Cypher.Length - 8)))
		} else {
			[System.Text.Encoding]::UTF8.GetString($Cypher, 8, $Cypher.Length - 8)
		}
	} catch {
		throw
	}
}
