################################################################################
# This script will maintain the PS Transcript file at a fixed length and can be 
# used to prevent such files, etc, from becoming too large. It is best placed in
# the $profile. Defaults to 10000 lines. Parameters allow use for other files.
# The author can be contacted via www.SeaStarDevelopmet.Bravehost.com
################################################################################
Param ([int]   $lines = 10000,
       [String]$file = "$env:scripts\Transcript.txt")
	   
If ($file -notlike "*.txt") {
	[System.Media.SystemSounds]::Hand.Play()
	Write-Error "This script can only process .txt files"
	Exit 1
}
If (!(Test-Path $file)) {
	[System.Media.SystemSounds]::Hand.Play()
	Write-Error "File $file does not exist"
	Exit 1
}
[int]$count = 0
$errorActionPreference = 'SilentlyContinue'
$content = (Get-Content $file)
$extra = ($content | Measure-Object -line)
[int]$extra = $extra.Lines - $lines              #The number of lines to remove.
If ($extra -gt 0) {
    $tempfile = [IO.Path]::GetTempFileName()
	Write-Output "Starting maintenance on file $file"
	$content | ForEach-Object {
    	$count += 1
  		If($count -gt $extra) {                  #Ignore the first $extra lines.
			$_ | Out-File $tempfile -Append -Force  #Create new Transcript file.
		}
	}
	If (file -like "*transcript.txt") { 
		Stop-Transcript | Out-Null
	}
	Remove-Item $file
	Move-Item $tempfile -Destination $file
	$tag = "[$extra lines removed]."
	If ($file -like "*transcript.txt") {
		Start-Transcript -append -path $file -force | Out-Null
	}
	Write-Output "Maintenance of file completed $tag"
}
$ErrorActionPreference = 'Continue'

