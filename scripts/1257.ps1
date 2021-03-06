[reflection.assembly]::LoadWithPartialName("Microsoft.SharePoint") | out-null
[reflection.assembly]::LoadWithPartialName("Microsoft.Office.Server") | out-null
[reflection.assembly]::LoadWithPartialName("Microsoft.Office.Server.Search") | out-null

@@#NOTE: I've set strict crawl freshness/crawl duration/success ratio threshholds. Reset as desired
@@#      to something that more suits your reality.
$crawlFreshnessDayThreshhold = 2
$crawlDurationHourThreshhold = 4
$successRatioThreshhold = 0.9


function Calculate-CrawlDuration(
	[Microsoft.Office.Server.Search.Administration.SharePointContentSource]$contentSource)
{
	if ($contentSource.CrawlStatus -eq [Microsoft.Office.Server.Search.Administration.CrawlStatus]::Idle) {
		return "Green - no current crawl"
	}
	
	$timespan = [datetime]::Now - $contentSource.CrawlStarted
	$timespanFormatted = "Running for $($timespan.TotalDays.ToString('0.00')) Days" + 
		"($($timespan.TotalHours.ToString('0.0')) hours)"
	
	if ($timespan.TotalHours -le ($crawlDurationHourThreshhold / 2)) {
		return "Green - $timespanFormatted"
	} elseif ($timespan.TotalHours -le ($crawlDurationHourThreshhold)) {
		return "Yellow - $timespanFormatted"
	} else {
		return "Red - $timespanFormatted"
	}
}


function Calculate-CrawlFreshness(
	[Microsoft.Office.Server.Search.Administration.SharePointContentSource]$contentSource)
{
	$timespan = [datetime]::Now - $contentSource.CrawlCompleted
	$timespanFormatted = "$($timespan.TotalDays.ToString('0.00')) days ago"
	if ($timespan.Days -le 0) {
		return "Green - $timespanFormatted"
	} elseif ($timespan.Days -lt $crawlFreshnessDayThreshhold) {
		return "Yellow - $timespanFormatted"
	} else {
		return "Red - $timespanFormatted"
	}
}


function Calculate-IndexHealth(
	[Microsoft.Office.Server.Search.Administration.SharePointContentSource]$contentSource, 
	$successCount, $warningCount, $errorCount)
{
	$formatted = "($($successCount)/$($warningCount)/$($errorCount))"
	if ($errorCount -eq 1) {
		return "Red - exactly 1 error, usually indicates permissions/config error - $formatted"
	}
	
	$successRatio = ([double]$successCount)/([double]($warningCount + $errorCount))
	$successRatioMidpointToPerfection = (1.0 - ((1.0 - $successRatioThreshhold)/2.0))
	if ($successRatio -ge $successRatioMidpointToPerfection) {
		return "Green - $formatted"
	} elseif ($successRatio -ge $successRatioThreshhold) {
		return "Yellow - $formatted"
	} else {
		return "Red - $formatted"
	}
}

function Get-CrawlHealth
{
	$serverContext = [Microsoft.Office.Server.ServerContext]::Default
	$searchContext = [Microsoft.Office.Server.Search.Administration.SearchContext]::GetContext($serverContext)

	$content = [Microsoft.Office.Server.Search.Administration.Content]$searchContext
	$history = [Microsoft.Office.Server.Search.Administration.CrawlHistory]$searchContext
	
	$contentSources = $content.ContentSources | foreach { $_ }
	
	$contentSources | foreach { 
		#unroll DataTable object into more useful DataRow object
		$crawlHistory = $history.GetLastCompletedCrawlHistory($_.Id) | % { $_ }
		add-member -inputobject $_ -membertype NoteProperty -name "CurrentCrawlDuration" -value (
			Calculate-CrawlDuration $_)
		add-member -inputobject $_ -membertype NoteProperty -name "CompletedCrawlFreshness" -value (
			Calculate-CrawlFreshness $_)
		add-member -inputobject $_ -membertype NoteProperty -name "IndexHealth" -value (
			Calculate-IndexHealth -contentSource $_ -successCount $crawlHistory.SuccessCount -warningCount (
				$crawlHistory.WarningCount) -errorCount $crawlHistory.ErrorCount)
	}
	
	$contentSources | select Name, CurrentCrawlDuration, CompletedCrawlFreshness, IndexHealth | fl
}



@@#USAGE: -Open a PowerShell session on the SharePoint server with elevated credentials 
@@#       (specifically, with access to the SSP - usually the SharePoint farm account)
@@#       -Tweak the threshholds (they may be too ambitious for your environment)
@@#        -Paste this text into an open PowerShell window and type (without the # mark)
#        Get-CrawlHealth
