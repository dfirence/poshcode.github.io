# to make it readable, I've wrapped the lines, but you can remove all the line breaks:
&{ 
  PARAM($FileName,$HashFileName) 
  ((Get-Content $HashFileName) -match $FileName)[0].split(" ")[0] -eq 
  [string]::Join("", (
    [Security.Cryptography.HashAlgorithm]::Create(
      ([IO.Path]::GetExtension($HashFileName).Substring(1).ToUpper())
    ).ComputeHash( 
      [IO.File]::ReadAllBytes( (Convert-Path $FileName) 
    )
  ) | ForEach { "{0:x2}" -f $_ }))
@@# Note that the last line here includes the PARAMETERS: FileName and HashFileName
} npp.5.3.1.Installer.exe npp.5.3.1.release.md5
