Function New-Zip
{
<#
.SYNOPSIS
	Create a Zip File from any files piped in.
.DESCRIPTION
	Requires that you have the SharpZipLib installed, which is available from
	http://www.icsharpcode.net/OpenSource/SharpZipLib/
.NOTES
	File Name  : PowerZip.psm1 
	Author     : Christophe CREMON (uxone) - http://powershell.codeplex.com
	Requires   : PowerShell V2
.PARAMETER Source
	Set the name of the source to zip (file or directory)
.PARAMETER ZipFile
	Set the name of the zip file to create
.PARAMETER Recurse
	Browse the source recursively
.PARAMETER Include
	Include only items you specify
.PARAMETER Exclude
	Exclude items you specify
.PARAMETER AbsolutePaths
	Preserve the absolute path name of each item in the zip container
.PARAMETER DeleteAfterZip
	Delete source items after successful zip
.EXAMPLE
	New-Zip -Source C:\Temp -ZipFile C:\Archive\Scripts.zip -Include *.ps1 -DeleteAfterZip
	Copies all PS1 files from the C:\Temp directory to C:\Archive\Scripts.zip and delete them after successful ZIP
#>
	param (
	[ValidateNotNullOrEmpty()]
		[Parameter(
    		Mandatory = $true)
    	]
			[string] $Source,
		[Parameter(
    		Mandatory = $true)
    	]
			[string] $ZipFile,
		[switch] $Recurse,
		[array] $Include,
		[array] $Exclude,
		[switch] $AbsolutePaths,
		[switch] $DeleteAfterZip )
	
	[int] $ExitCode = 1
	
	$LoadAssembly = [System.Reflection.Assembly]::LoadWithPartialName("ICSharpCode.SharpZipLib")
	if ( -not $LoadAssembly ) { throw "! Assembly not found {ICSharpCode.SharpZipLib}" }
	
	$RootPath = ( Resolve-Path -Path $Source -ErrorAction SilentlyContinue ).Path	
	if ( -not $RootPath ) { throw "! Source not found {$Source}" }
	
	if ( $ZipFile -notmatch "\.zip$" ) { $ZipFile = $ZipFile -replace "$",".zip" }
	if ( $Recurse -eq $true ) { $RecurseArgument = "-Recurse" }
	if ( $AbsolutePaths -eq $true ) { $AbsolutePathsArgument = "-AbsolutePaths" }
	if ( $DeleteAfterZip -eq $true ) { $DeleteAfterZipArgument = "-DeleteAfterZip" }
	if ( $Include )
	{
		$Include = $Include -join ","
		$IncludeArgument = "-Include $Include"
		$Source = $Source+"\*"
	}
	if ( $Exclude )
	{
		$Exclude = $Exclude -join ","
		$ExcludeArgument = "-Exclude $Exclude"
	}
	
	$GetCommand = "Get-ChildItem -Path '$Source' $RecurseArgument $IncludeArgument $ExcludeArgument -Force"
	$ItemsToZip = Invoke-Expression -Command $GetCommand
	$SizeBeforeZip = ( $ItemsToZip | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue ).Sum
	$SizeBeforeZipInMB = $SizeBeforeZip | ForEach-Object { "{0:N2}" -f ($_ / 1MB) }
	if ( -not $SizeBeforeZip )
	{
		Write-Output "NOTHING TO ZIP"
		break
	}
	
	$StartTime = Get-Date
	Write-Output "`n===================================`n=> Start Time : $($StartTime.ToString(""dd/MM/yyyy-HH:mm:ss""))`n"	
	Write-Output "TOTAL SIZE BEFORE ZIP : {$SizeBeforeZipInMB MB}`n"
	Write-Output "Initializing ZIP File {$ZipFile} ...`n"
	
	$CreateZIPContainer = New-Item -ItemType File -Path $ZipFile -Force -ErrorAction SilentlyContinue
	if ( -not $CreateZIPContainer ) { throw "! Unable to create ZIP container {$ZipFile}" }
	
	$oZipOutputStream = New-Object -TypeName ICSharpCode.SharpZipLib.Zip.ZipOutputStream([System.IO.File]::Create($ZipFile))	
	
	[byte[]] $Buffer = New-Object Byte[] 4096
	
	foreach ( $Item in $ItemsToZip )
	{
		if ( $Item.FullName -ne $ZipFile )
		{
			if ( Test-Path ( $Item.FullName ) -ErrorAction SilentlyContinue )
			{
				$ZipEntry = $Item.FullName
				if ( -not $AbsolutePaths )
				{
					$ReplacePath = [Regex]::Escape( $RootPath+"\" )
					$ZipEntry = $Item.FullName -replace $ReplacePath,""
				}				
				if ( $Item.psIsContainer -eq $true )
				{
					if ( $Recurse -eq $true )
					{
						Write-Output "Processing ZIP of Directory {$($Item.FullName)} ..."
						$OldErrorActionPreference = $ErrorActionPreference
						$ErrorActionPreference = "SilentlyContinue"
						$oZipEntry = New-Object -TypeName ICSharpCode.SharpZipLib.Zip.ZipEntry("$ZipEntry/")
						$oZipOutputStream.PutNextEntry($oZipEntry)
						if ( $? -ne $true )
						{
							$ItemsNotZipped += @($Item.FullName)
							$ErrorsArray += @("! Unable to ZIP Directory {$($Item.FullName)}")
						}
						$ErrorActionPreference = $OldErrorActionPreference
					}
				}
				else
				{
					Write-Output "Processing ZIP of File {$($Item.FullName)} ..."
					$OldErrorActionPreference = $ErrorActionPreference
					$ErrorActionPreference = "SilentlyContinue"
					$FileStream = [IO.File]::OpenRead($Item.FullName)
					$oZipEntry = New-Object -TypeName ICSharpCode.SharpZipLib.Zip.ZipEntry("$ZipEntry")
					$oZipOutputStream.PutNextEntry($oZipEntry)
					[ICSharpCode.SharpZipLib.Core.StreamUtils]::Copy($FileStream,$oZipOutputStream,$Buffer)
					if ( $? -ne $true )
					{
						$ItemsNotZipped += @($Item.FullName)
						$ErrorsArray += @("! Unable to ZIP File {$($Item.FullName)}")
					}
					$FileStream.Close()
				}
			}
		}
	}
	
	$oZipOutputStream.Finish()
	$oZipOutputStream.Close()
	
	if ( $? -eq $true )
	{
		$ErrorActionPreference = $OldErrorActionPreference
		if ( $DeleteAfterZip )
		{
			$ItemsToZip | Where-Object { $ItemsNotZipped -notcontains $_.FullName } | ForEach-Object {
				if ( $_.psIsContainer -ne $true )
				{
					if ( Test-Path ( $_.FullName ) -ErrorAction SilentlyContinue )
					{
						Write-Output "Processing Delete of File {$($_.FullName)} ..."
						$RemoveItem = Remove-Item -Path $_.FullName -Force -ErrorAction SilentlyContinue
						if ( $? -ne $true )
						{
							$ErrorsArray += @("! Unable to Delete File {$($_.FullName)}")
						}
					}
				}
			}
			if ( $Recurse )
			{
				$ItemsToZip | Where-Object { $ItemsNotZipped -notcontains ( Split-Path -Parent $_.FullName ) } | ForEach-Object {
					if ( $_.psIsContainer -eq $true )
					{
						if ( Test-Path ( $_.FullName ) -ErrorAction SilentlyContinue )
						{
							Write-Output "Processing Delete of Directory {$($_.FullName)} ..."
							$RemoveItem = Remove-Item -Path $_.FullName -Force -Recurse -ErrorAction SilentlyContinue
							if ( $? -ne $true )
							{
								$ErrorsArray += @("! Unable to Delete Directory {$($_.FullName)}")
							}
						}
					}
				}
			}
		}
		Write-Output "`nZIP File Created {$ZipFile} ...`n"
		$ExitCode = 0
	}
	else
	{
		$ErrorActionPreference = $OldErrorActionPreference
		$ErrorsArray += @("! ZIP Archive {$ZipFile} Creation Failed`n")
	}
	
	if ( $ErrorsArray )
	{
		Write-Output "`n[ ERRORS OCCURED ]"
		$ErrorsArray
		$ExitCode = 1
	}
	else
	{
		$SizeAfterZip = ( Get-Item -Path $ZipFile -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue ).Sum
		$SizeAfterZipInMB = $SizeAfterZip | ForEach-Object { "{0:N2}" -f ($_ / 1MB) }
		Write-Output "`nTOTAL SIZE AFTER ZIP : {$SizeAfterZipInMB MB}`n"
		
		$Gain = ( $SizeBeforeZip - $SizeAfterZip )
		$GainInMB = $Gain | ForEach-Object { "{0:N2}" -f ($_ / 1MB) }
		if ( $Gain -gt 0 )
		{
			$GainInPercent = (($SizeBeforeZip - $SizeAfterZip) / $SizeBeforeZip) * 100 | ForEach-Object { "{0:N2}" -f $_ }
			Write-Output "GAIN : {$GainInMB MB} ($GainInPercent %)`n"
		}
	}
	$EndTime = Get-Date
	$ExecutionTime = ($EndTime-$StartTime)
	Write-Output "`nExecution Time : $ExecutionTime`n"	
	Write-Output "=> End Time : $($EndTime.ToString(""dd/MM/yyyy-HH:mm:ss""))`n=================================`n"
	exit $ExitCode
}
Export-ModuleMember -Function New-Zip
