## ============================================================
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class RecycleBin
{
	[DllImport("shell32.dll",CharSet=CharSet.Unicode)]
	public static extern void SHUpdateRecycleBinIcon();
}
"@
## ============================================================
Function ConvertTo-LitheralSize
{
	Param
	(
		[Parameter(ValueFromPipeline)]
		[System.UInt64[]]$Size
	)
	Process
	{
		$Size | ForEach-Object -Process {
			switch ($_)
			{
				{ $_ -lt 1KB }  { $litheral = "$_ bytes"; break }
				{ $_ -lt 1MB }  { $litheral = ($_ / 1KB).ToString('.0 KiB'); break }
				{ $_ -lt 1GB }  { $litheral = ($_ / 1MB).ToString('.00 MiB'); break }
				{ $_ -lt 1TB }  { $litheral = ($_ / 1GB).ToString('.00 GiB'); break }
				{ $_ -lt 1PB }  { $litheral = ($_ / 1TB).ToString('.00 TiB'); break }
					 Default	{ $litheral = ($_ / 1TB).ToString('.000 PiB') }
			}
				$litheral | write
		}
	}
}
## ============================================================
[void] [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.VisualBasic')
Function Recycle-Item
{
	[CmdletBinding()]
	Param(
		[Parameter(Position=0,Mandatory,ValueFromPipeline)]
			[System.Object[]]$Path,
			[System.Management.Automation.SwitchParameter]$WipeOut
	)
	Begin
	{
		[Microsoft.VisualBasic.FileIO.UIOption]$dialog_mode = 0x02
		[Microsoft.VisualBasic.FileIO.RecycleOption]$recycle_mode = 0x02 -bor -not $WipeOut
	}
	Process
	{
		$Path | gi -Force -ErrorAction 'SilentlyContinue' | ForEach-Object -Process {
			if (($_.Attributes -band 0x10) -eq 0x10)
			{
				"Removing directory: `"$($_.FullName)`"" | Write-Verbose
				[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($_.FullName,$dialog_mode,$recycle_mode)
			}
			else
			{
				"Removing file: `"$($_.FullName)`"" | Write-Verbose
				[Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($_.FullName,$dialog_mode,$recycle_mode)
			}
		}
	}
}

# -- Recycle Bin Object --
$method = @{}

$method['Help'] = {
	$help = @"

	`"Recycle Bin Object`"

	Author   : Michael Skourlatov
	Created  : 2014-Jun-27
	Modified : 2014-Aug-12

This script creates object which correctly works with ntfs streams and reparse points

Usage samples:

	`$RecycleBin.List()[`$id].Object -> return the item as file or folder by it's ID

	`$RecycleBin.ShowItems([<mask>]) -> show items list
	`$RecycleBin.Restore([<mask>]) -> restore items (may need confirmation)
	`$RecycleBin.Measure([<mask>]) -> measure true size of all items in Recycle Bin
	`$RecycleBin.Clear([<mask>]) -> this is obvious
	`$RecycleBin.List([<mask>]) -> this is the core method
	`$RecycleBin.Help() -> show this help

More examples:

	`$RecycleBin.List([<mask>]).Measure()
	`$RecycleBin.List([<mask>]).Restore()
	`$RecycleBin.List([<mask>]).Delete()

	`$too_old = [datetime]::Now.AddDays(-20)
	`$selected = `$RecycleBin.List() | where { `$_.DecryptInfo().DeletionDate -le `$too_old }
	`$selected.Delete()

Notes:

	<mask> is the standard file mask like '*.txt'
	[] brackets mean parameter isn't mandatory

"@
	$help | Write-Output
}

$method['List'] = {
	.{ param ([Parameter(Mandatory=$false)][System.String]$Mask)} @args

	$actual_list = $this._ComWrapper.Items() | select
	if ($Mask) { $actual_list = $actual_list | where -Property 'Name' -like -Value $Mask }
	$sked = @()

	$actual_list | foreach {
		$rec = $_ | select 'Name','Type','ModifyDate',
			@{Name = 'Actions';		Expression = { $_.Verbs() | select }},
			@{Name = 'Object';		Expression = { gi -LiteralPath $_.Path -Force }},
			@{Name = 'InfoFile';	Expression = {
				$seppos = $_.Path.LastIndexOf(92)
				$parent = $_.Path.Substring(0, $seppos)
				$child =  $_.Path.Substring($seppos + 1).Replace('$R','$I')
				gi -LiteralPath "$parent\$child" -Force
			}}

		$rec | Add-Member -MemberType 'ScriptMethod' -Name 'DecryptInfo' -Value {
			[byte[]]$bb = cat $this.InfoFile -Encoding 'Byte'

		##	[uint64[]]$length_raw = [char[]][System.Text.Encoding]::Unicode.GetString($bb[8..15])
		##	$length = 0
		##	for ($i = 0; $i -le 3; $i++) { $length += $length_raw[$i] -shl $i*16 }

			$timestamp_raw = [BitConverter]::ToInt64($bb[16..23], 0)
			$ref_date	= [DateTime]::FromBinary(5116597250427387904).ToLocalTime() ## 1601-01-01 00:00:00.000 UTC
			$timespamp	= $ref_date.AddTicks($timestamp_raw)

			$full_name	= [System.Text.Encoding]::Unicode.GetString($bb[24..543])
			$seppos		= $full_name.LastIndexOf(92)
			$paret_path	= $full_name.Substring(0, $seppos + 1)

			New-Object -TypeName 'PSObject' -Property @{
													ParentPath = $paret_path;
													DeletionDate = $timespamp;
												##	SystemSize = $length;
												}
		}

		$rec | Add-Member -MemberType 'ScriptMethod' -Name 'Delete' -Value {
			$this.Object, $this.InfoFile | recycle -WipeOut
		}

		$rec | Add-Member -MemberType 'ScriptMethod' -Name 'Restore' -Value {
			$this.Actions[0].DoIt()
			if (!$this.Object.Exists)
			{
				$this.InfoFile.Delete()
			}
		}

		$rec | Add-Member -MemberType 'ScriptMethod' -Name 'Measure' -Value {

			Set-Variable -Name _sum -Value @{
												Item = $this.Name;
												Links = 0;
												Files = 0;
												Folders = 0;
												Size = 0
							} -Option AllScope

			function calculate ([System.Object]$Obj, [System.IO.DirectoryInfo]$Fol)
			{
				if (-not $Obj)
				{
					$Obj = $Fol | ls -Force
				}
				if ($Obj)
				{
					$Obj | foreach {
						if (($_.Attributes -band 0x0400) -eq 0x0400)
						{
							++$_sum.Links
						}
						elseif (($_.Attributes -band 0x0010) -ne 0x0010)
						{
							try
							{
								[UInt64]$_sum.Size += ($_ | gi -Force -Stream '*' | measure Length -Sum).Sum
							}
							catch
							{
								[UInt64]$_sum.Size += $_.Length
							}
							finally
							{
								++$_sum.Files
							}
						}
						else
						{
							++$_sum.Folders
							calculate -Fol $_
						}
					}
				}
			}
			calculate -Obj $this.Object
			return New-Object -TypeName 'PSObject' -Property $_sum
		}
		$sked += $rec
	}
	return $sked
}

$method['Clear'] = {
	.{ param ([Parameter(Mandatory=$false)][System.String]$Mask)} @args

	$wipe_list = $this.List($Mask)
	if ($wipe_list)
	{
		$wipe_list.Delete()
		$true
	}
	else
	{
		$false
	}

	[RecycleBin]::SHUpdateRecycleBinIcon()
}

$method['Measure'] = {
	.{ param ([Parameter(Mandatory=$false)][System.String]$Mask)} @args

	$res = @{
		Links = 0;
		Files = 0;
		Folders = 0;
		Size = 0
	}

	$this.List($Mask) | ForEach-Object -Process {
		$item = $_.Measure()
		$res.Links   += $item.Links
		$res.Files   += $item.Files
		$res.Folders += $item.Folders
		[UInt64]$res.Size += $item.Size
	}

	return New-Object -TypeName 'PSObject' -Property $res
}
$method['Restore'] = {
	.{ param ([Parameter(Mandatory=$false)][System.String]$Mask)} @args

	$items_list = $this.List($Mask)

	if (-not $items_list)
	{
		return $false
	}

	$confirmation = [bool]$Mask
	if (-not $confirmation)
	{
						[console]::Write('Are you sure to restore ALL items? [Y/N]: ')
		$confirmation = [console]::ReadKey().Key -eq 'Y' 
						[console]::WriteLine()
	}
	if ($confirmation)
	{
		$items_list.Restore()
		$true
	}
	else
	{
		$false
	}
}

$method['ShowItems'] = {
	.{ param ([Parameter(Mandatory=$false)][System.String]$Mask)} @args

	$items_list = $this.List($Mask)
	if (-not $items_list)
	{
		return $false
	}

	$output_list = @()
	$id = 0

	$items_list | ForEach-Object -Process {

		$item_measure = $_.Measure()
		$item_size = $item_measure.Size | ConvertTo-LitheralSize

		$item_children = ""
		if ($item_measure.Folders)
		{
			$files = $links = $folders = ""
			if ($item_measure.Files) { $files = "F/$($item_measure.Files); " }
			if ($item_measure.Links) { $links = "L/$($item_measure.Links); " }
			if ($item_measure.Folders - 1) { $folders = "D/$($item_measure.Folders - 1); " }
			$item_children = $folders + $files + $links
		}
		$desc = $_.DecryptInfo()
		$item = New-Object -TypeName 'PSObject'
		$item | Add-Member -MemberType 'NoteProperty' -Name 'ID'			-Value $id
		$item | Add-Member -MemberType 'NoteProperty' -Name 'Size'			-Value $item_measure.Size
		$item | Add-Member -MemberType 'NoteProperty' -Name 'Literal'		-Value $item_size
		$item | Add-Member -MemberType 'NoteProperty' -Name 'Parent'		-Value $desc.ParentPath
		$item | Add-Member -MemberType 'NoteProperty' -Name 'Child'			-Value $_.Name
		$item | Add-Member -MemberType 'NoteProperty' -Name 'Type'			-Value $_.Type
		$item | Add-Member -MemberType 'NoteProperty' -Name 'Encapsulates'	-Value $item_children
		$item | Add-Member -MemberType 'NoteProperty' -Name 'ModifyDate'	-Value $_.ModifyDate
		$item | Add-Member -MemberType 'NoteProperty' -Name 'Deleted'		-Value $desc.DeletionDate
	##	$item | Add-Member -MemberType 'NoteProperty' -Name 'Object'		-Value $_.Object.FullName
		$output_list += $item
		$id++
	}
	$output_list | ogv -Title "Recycle Bin Items ($Mask)"
	return $true
}

$bin = New-Object -TypeName 'PSObject'

$bin | Add-Member -MemberType 'NoteProperty' -Name '_ComWrapper' -Value (
	New-Object -ComObject 'Shell.Application'
).Namespace(0xA)

$method.Keys | ForEach-Object -Process {
	$bin | Add-Member -MemberType 'ScriptMethod' -Name $_ -Value $method[$_]
}

New-Variable -Name 'RecycleBin' -Value $bin -Option 'Constant'
Remove-Variable -Name 'method', 'bin'
## -- Recycle Bin Object --

