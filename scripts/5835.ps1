#requires -version 4
function Get-APIKey {
  <#
    .SYNOPSIS
        Gets VirusTotal public key of SysInternals.
    .DESCRIPTION
        DO NOT USE IT FOR YOUR DIRTY PURPOSES! THIS SCRIPT IS JUST A CONCEPT.
    .NOTES
        Author: greg zakharov
  #>
  param(
    [Parameter(ValueFromPipeline=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$UserAgent
  )

  $par = @{
    Uri = 'https://live.sysinternals.com/sigcheck.exe'
    DisableKeepAlive = $true
    UseBasicParsing = $true
  }

  if ($UserAgent) { $par['UserAgent'] = $UserAgent }

  ([Regex]'[\x20-\x7E]{64,}').Matches(
    [Text.Encoding]::UTF7.GetString((wget @par).Content)
  ).ForEach({if ($_ -match '\A(\d|[a-z]){64}\Z') {$_.Value}})
}

function Test-APIKey {
  <#
    .SYNOPSIS
        Tests uncovered public key.
    .NOTES
        Author: greg zakharov
  #>
  $par = @{
    Uri = 'https://www.virustotal.com/vtapi/v2/file/report'
    DisableKeepAlive = $true
    Method = 'POST'
    Body = @{
      resource = '0EBD8EA9B29BBA099699ED5A81D6BC4CD7FA46DC220D18FA5289BC3EA5EC1AF8'
      apikey = Get-APIKey
    }
  }

  Invoke-RestMethod @par
}
