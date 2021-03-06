Param(
	[string]$CCNetListenerFile = $null,
	[string]$MyComputerName = [System.Environment]::MachineName,
	[string]$Config='Debug',
	[int]$CCNetLogQueueLength = 10
	[switch]$NoBuild,
	[string]$SpecificVdir = $null
)
# usage from ccnet will be something like this:
#...
#<powershell>
#<scriptDirectory>iphi</scriptDirectory>
#<script>deploy.ps1</script>
#<executable>C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe</executable>
#<dynamicValues>
#  <replacementValue property="buildArgs">
#    <format>-CCNetListenerFile {0}</format>
#    <parameters>
#      <namedValue name="$CCNetListenerFile" value="Default" />
#    </parameters>
#  </replacementValue>
#</dynamicValues>                    
#</powershell>
#...

[Environment]::CurrentDirectory=(Get-Location -PSProvider FileSystem).ProviderPath

# The CCNetListenerFile is an xml file used by ccnet to list what is going on during the build in details
function CCNetListenerLog( $q ) {
	if($CCNetListenerFile -ne '' -and $CCNetListenerFile -ne $null) { 
		$stream = [System.IO.StreamWriter] $CCNetListenerFile
		$stream.AutoFlush = $true;
		$stream.WriteLine("<data>")
		foreach( $item in $q ) {
			$stream.WriteLine($item)
		}
		$stream.WriteLine("</data>")
		$stream.Close()
	}
}

$q = New-Object System.Collections.Queue
function LogBuildPoint( [string]$text ) {
	if( $q.Count -ge $CCNetLogQueueLength ) {
		# store in temp var so there is no output, can probably do this better ...
		$old = $q.Dequeue();
	}
	$stamp = [System.DateTime]::Now.ToString("yyyy-MM-dd hh:mm:ss");
	$item = "<Item Time='$stamp' Data='$text' />"

	$q.Enqueue( $item );
	#use write-host because otherwise this becomes included in the function output, not necessarily written to the screen
	#also this write-host causes the message to be put in the build log when run from ccnet
	Write-Host $text 
	if($CCNetListenerFile -ne '' -and $CCNetListenerFile -ne $null) { 
		CCNetListenerLog $q 
	}
}

#push directory (and update the environment variable so that relative paths work as expected without ".\")
function pd( [string]$location ) {
	Push-Location $location;
	[Environment]::CurrentDirectory=(Get-Location -PSProvider FileSystem).ProviderPath;
}
#pop directory
function ppd() {
	Pop-Location
	[Environment]::CurrentDirectory=(Get-Location -PSProvider FileSystem).ProviderPath;
}

function Build() {
	#you can log a repetative task and estimate when it will finish like this:
	$total = ($repetition_object | Measure-Object).Count
	$num = 0
	$startTime = [System.DateTime]::Now
	$repetition_object | % {
		$_ | RepetitiveTask
		
		$num++
		$curTime = [System.DateTime]::Now
		$percent = ($num / $total)
		$expected = ($startTime + (New-Object TimeSpan (($curTime - $startTime).Ticks / $percent))).ToShortTimeString()
		LogBuildPoint "Finished $num out of $total, expect to complete at: $expected"		
	}
}

#useful if you want to call this from the CLI to declare the functions
if(!$NoBuild) {
	Build
}

