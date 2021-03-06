# get-large-pics.ps1 - takes two arguments, source directory and target directory.
# all files in source directory are uploaded to google image search one by one,
# and in turn it downloads the resulting pictures and saves the largest picture,
# in the target directory, using the same file name as the source file.
# so you can just, after verifying the pictures are correct, copy the target directory to the source directory,
# to have larger versions of all your pictures.
# If no target directory is specified, it will use "\[source directory]\results"

function global:Get-GoogleImageSearchUrl
{
    param(
        [Parameter(Mandatory = $true)]
        [ValidateScript({ Test-Path $_ })]
        [string] $ImagePath
    )

    # extract the image file name, without path
    $imagepath = (get-item -ea 0 $imagepath).fullname
    $fileName = Split-Path $imagePath -Leaf

    # the request body has some boilerplate before the raw image bytes (part1) and some after (part2)
    #   note that $filename is included in part1
    $part1 = @"
-----------------------------7dd2db3297c2202
Content-Disposition: form-data; name="encoded_image"; filename="$fileName"
Content-Type: image/jpeg


"@
    $part2 = @"
-----------------------------7dd2db3297c2202
Content-Disposition: form-data; name="image_content"


-----------------------------7dd2db3297c2202--

"@

    # grab the raw bytes composing the image file
    $imageBytes = [Io.File]::ReadAllBytes($imagePath)

    # the request body should sandwich the image bytes between the 2 boilerplate blocks
    $encoding = New-Object Text.ASCIIEncoding
    $data = $encoding.GetBytes($part1) + $imageBytes + $encoding.GetBytes($part2)

    # create the HTTP request, populate headers
    $request = [Net.HttpWebRequest] ([Net.HttpWebRequest]::Create('http://images.google.com/searchbyimage/upload'))
    $request.Method = "POST"
    $request.ContentType = 'multipart/form-data; boundary=---------------------------7dd2db3297c2202'  # must match the delimiter in the body, above
    $request.ContentLength = $data.Length

    # don't automatically redirect to the results page, just take the response which points to it
    $request.AllowAutoredirect = $false

    # populate the request body
    $stream = $request.GetRequestStream()
    $stream.Write($data, 0, $data.Length)
    $stream.Close()        

    # get response stream, which should contain a 302 redirect to the results page
    $respStream = $request.GetResponse().GetResponseStream()

    # pluck out the results page link that you would otherwise be redirected to
    (New-Object Io.StreamReader $respStream).ReadToEnd() -match 'HREF\="([^"]+)"' | Out-Null
    $matches[1]
}

$foundfiles = 0
if ($args.count -lt 1)
{
	$sourceFolder = "c:\users\jrg26\pics"
}
else
{
	$sourceFolder = $args[0]
}
$SearchItem = 'PowerShell'
if ($args.count -lt 2)
{
	$TargetFolder = join-path $sourceFolder "results"
}
else
{
	$TargetFolder = $args[1]
}
$browserAgent = 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36'
if ( (Test-Path -Path $TargetFolder) -eq $false) { md $TargetFolder }


$files = @(dir $sourceFolder|?{$_.psiscontainer -eq $false})
for ($t=0;$t -lt $files.Count;$t++)
{
	"Processing file #$($t) of $($files.Count)"
	$f = $files[$t]
	$url = get-GoogleImageSearchUrl $f.fullname
    
    $page = Invoke-WebRequest -Uri $url -UserAgent $browserAgent -TimeoutSec 30
    $link = @($page.Links|?{$_.outertext -eq "Large"})
    if ($link.Count -eq 0 -or $link.href -notlike "/search*") 
    {
        "No Large pictures found on google for $($F.basename)"
        continue
    }
    $url = "www.google.com"+$link[0].href.tostring().replace("&amp;","&")
 
$page = Invoke-WebRequest -Uri $url -UserAgent $browserAgent -TimeoutSec 30
$found = $null
$page.Links | 
  Where-Object { $_.href -like '*imgres*' } | 
  ForEach-Object { ($_.href -split 'imgurl=')[-1].Split('&')[0]} |
  ForEach-Object {
    $file = Split-Path -Path $_ -Leaf
    $path = Join-Path -Path $TargetFolder -ChildPath $file   
    $path = $path.Replace("*","x").Replace("?","x") 
    do 	
    {
	$p1 = join-Path -path $TargetFolder -ChildPath $(get-random(99999)).tostring()
	if ($path.lastindexof(".") -eq -1)
	{
		$path = $p1 + $f.extension
	}
	else 
	{
		$ext = $path.substring($path.lastindexof("."))
		if (($ext.length -gt 4) -and ($ext -ne ".jpeg"))
		{
			$ext = $ext.substring(0,4)		
		}
		$path = $p1 + $ext
	}
    } while ((test-path -ea 0 $path))
    try 
    {
    Invoke-WebRequest -ea 0 -Uri $_ -OutFile $path -UserAgent $browserAgent -TimeoutSec 30
    }
    catch { }
    if (test-path -ea 0 $path)
    {
        $f2 = get-item -ea 0 $path

	if ($f2.length -le $f.Length)
	{
		del -ea 0 $f2
	}
	elseif ($found -eq $null)
	{
		$found = $f2
	}
	elseif ($found.length -ge $f2.length)
	{
		del -ea 0 $f2				
	}
	elseif ($found.length -lt $f2.length)
	{
		del -ea 0 $found
		$found = $f2
	}	
    }
  } 
if ($found -eq $null) {"No bigger files downloaded."; continue}

    $f3 = $f.basename + $found.extension
    $f3 = join-path $found.DirectoryName $f3

    del -ea 0 $f3
    ren $found.fullname $f3
    "Found $($found.Length) byte file to replace $($f.Length) byte file: $($f.BaseName)$($f.extension)"
    $foundfiles++
[gc]::collect()
}

"$($foundfiles) larger pictures found."
