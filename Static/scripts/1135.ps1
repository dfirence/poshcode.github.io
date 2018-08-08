#Requires -Version 2.0

DATA loc {
	# en-US
	convertfrom-stringdata @'
		RootName = (Root)
		FolderCaption = Folder: {0}
		FeedCaption = Feed: {0}
		MarkReadStatus = Marking all items read
		DownloadStatus = Downloading all items
		AsyncDownloadStatus = Beginning download of all items
'@
}

# Import localized data (default is en-US above).
import-localizeddata -bindingVariable loc -errorAction SilentlyContinue

filter Recurse-Feeds { $_.Subfolders | Recurse-Feeds; $_.Feeds }
filter Recurse-Folders { $_.Subfolders | Recurse-Folders; $_ }

# Filter to write progress based on the number of feed items
filter Write-FeedProgress
{
	param(
        [scriptblock] $Script = $(throw "`$Script required."),
        [string] $Activity = $(throw "`$Activity required."),
        [MarshalByRefObject] $Folder = $(throw "`$Folder required."),
        [switch] $WithProgress
    )
	begin
	{
		$total = $Folder.TotalItemCount
		$count = 0
	}
	process
	{
        try
        {
		  & $Script
        }
        finally
        {
            # Always report progress
    		if ($WithProgress)
    		{
    			$count += $_.ItemCount;
    			$percent = $count / $total * 100

    			$path = $_.Parent.Path
    			if ($path -eq "") { $path = $loc.RootName }

    			write-progress -activity $activity -status ($loc.FolderCaption -f $path) `
    				-current ($loc.FeedCaption -f $_.Name) -percent $percent
    		}
        }
	}
}

# Mark all feed items as read
function MarkRead-Feeds
{
<#
.Synopsis
    Marks all feeds in the root or given folder as read.
.Description
    Marks all the feeds in Internet Explorer 7.0 or newer as read. If no folder
    is provided then this marks all feeds under the root folder.
.Parameter Folder
	The name of the folder under which all items are marked read.
.Parameter WithProgress
	Show a progress bar and activity details.
.Example
    markread-feeds "Microsoft Feeds" -withprogress
	Marks all items as read under "Microsoft Feeds" with progress.
#>
    [CmdletBinding()]
	param(
        [Parameter(Position = 0)]
        [string] $Folder = $null,
        
        [Parameter()]
		[switch] $WithProgress
    )

	$rss = new-object -com Microsoft.FeedsManager
	$root = $rss.GetFolder($Folder)
	$root | recurse-feeds | write-feedprogress -script { $_.MarkAllItemsRead() } `
		-activity $loc.MarkReadStatus -folder $root -withprogress:$WithProgress
}

# Download all new feed items
function Download-Feeds
{
<#
.Synopsis
    Downloads (synchronizes) all feeds in the root or given folder.
.Description
    Forces the synchronization of all feeds in Internet Explorer 7.0 or newer.
    If no folder is provided then this downloads all feeds under the root
    folder.
.Parameter Folder
	The name of the folder under which all items are marked read.
.Parameter Asynchronous
	Return immediately and download all items in a separate thread.
.Parameter WithProgress
	Show a progress bar and activity details.
.Example
    download-feeds "Microsoft Feeds" -withprogress
	Downloads all items under the "Microsoft Feeds" folder with progress.
#>
    [CmdletBinding()]
	param(
        [Parameter(Position = 0)]
        [string] $Folder = $null,
        
        [Parameter()]
		[switch] $Asynchronous,
        
        [Parameter()]
		[switch] $WithProgress
    )

	if ($Asynchronous)
	{
		$activity = $loc.AsyncDownloadStatus
		$script = { $_.AsyncDownload() }
	}
	else
	{
		$activity = $loc.DownloadStatus
		$script = { $_.Download() }
	}

	$rss = new-object -com Microsoft.FeedsManager
	$root = $rss.GetFolder($Folder)
	$root | recurse-feeds | write-feedprogress -script $script `
		-activity $activity -folder $root -withprogress:$WithProgress
}

# Export everything for use into the current session.
export-modulemember -function "markread-feeds", "download-feeds"
