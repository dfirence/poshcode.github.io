Function New-DummyVM {
	param(
	[Parameter(Mandatory=$true,HelpMessage="Target Host")]
	[VMware.VimAutomation.Types.VMHost]
	$TargetHost,

	[Parameter(Mandatory=$true,HelpMessage="Target Host")]
	[VMware.VimAutomation.Types.ResourcePool]
	$ResourcePool,

	[Parameter(Mandatory=$true,HelpMessage="New VM Name")]
	[String]
	$NewName
	)
	
	Get-VMHost $TargetHost | New-VM -ResourcePool $ResourcePool -Name $NewName -DiskMB 1
}

Function Add-BulkHosts {
	param(
	[Parameter(Mandatory=$true,HelpMessage="Host name or IP address")]
	[String]
	$HostName,

	[Parameter(HelpMessage="Target Datacenter")]
	[VMware.VimAutomation.Types.Datacenter]
	$Datacenter,

	[Parameter(HelpMessage="Target Folder")]
	[VMware.VimAutomation.Types.Folder]
	$Folder,

	[Parameter(HelpMessage="Target Cluster")]
	[VMware.VimAutomation.Types.Cluster]
	$Cluster,

	[Parameter(HelpMessage="Target Resource Pool")]
	[VMware.VimAutomation.Types.ResourcePool]
	$ResourcePool,

	[Parameter(HelpMessage="Target Port")]
	[Int32]
	$Port=443,

	[Parameter(HelpMessage="User")]
	[String]
	$User = "",

	[Parameter(HelpMessage="Password")]
	[String]
	$Password
	)

	Process {
		if ($Datacenter) {
			$location = $Datacenter
		} elseif ($Folder) {
			$location = $Folder
		} elseif ($Cluster) {
			$location = $Cluster
		} elseif ($ResourcePool) {
			$location = $ResourcePool
		}
		if (!$location) {
			Write-Warning "One of Datacenter, Folder, Cluster or ResourcePool must be specified."
			return
		}

		if ($User -ne "") {
			Add-VMHost -Name $HostName -Location $location -Port $Port -User $User -Password $Password -Force
		} else {
			Add-VMHost -Name $HostName -Location $location -Port $Port -Force
		}
	}
}

Function Get-ExcelFrontEnd {
	param($cmdlet)

	# Load in some Excel interop stuff.
	[reflection.assembly]::loadwithpartialname("microsoft.office.interop.excel") | Out-Null
	$xlDvType                  = "Microsoft.Office.Interop.Excel.XlDVType" -as [type]
	$xlDvAlertStyle            = "Microsoft.Office.Interop.Excel.XlDvAlertStyle" -as [type]
	$xlFormatConditionOperator = "Microsoft.Office.Interop.Excel.XlFormatConditionOperator" -as [type]
	$myDocuments = (Get-Itemproperty "hkcu:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders").Personal
	$csvFile = $myDocuments + "\parameters.csv"

	# We watch this file for writes.
	$startWriteTime = (Get-ChildItem $csvFile -ea SilentlyContinue).LastWriteTime

	# Define what commands will get us various types of data.
	$findObjects = @{
		[VMware.VimAutomation.Types.Cluster]             = { Get-Cluster }             ;
		[VMware.VimAutomation.Types.Datacenter]          = { Get-Datacenter }          ;
		[Datastore]                                      = { Get-Datastore }           ;
		[VMware.VimAutomation.Types.Folder]              = { Get-Folder }              ;
		[VMware.VimAutomation.Types.OSCustomizationSpec] = { Get-OSCustomizationSpec } ;
		[VMware.VimAutomation.Types.ResourcePool]        = { Get-ResourcePool }        ;
		[VMware.VimAutomation.Types.Template]            = { Get-Template }            ;
		[VMware.VimAutomation.Types.VirtualMachine]      = { Get-VM }                  ;
		[VMware.VimAutomation.Types.VMHost]              = { Get-VMHost }
	}
	
	# Parameters to ignore.
	$ignore = @("Verbose", "Debug", "ErrorAction", "WarningAction", "ErrorVariable",
	    "WarningVariable", "OutVariable", "OutBuffer")

	# Determine the names and types of all parameters in the first signature.
	$parameters = (Get-Command $cmdlet).Parameters

	# Locate the cmdlet template.
	$cmdletTemplate = $myDocuments + "\CmdletFrontend.xlsm"
	$ifOffset = 11

	# Launch Excel and initialize things.
	$xl = New-Object -ComObject Excel.Application
	$wb = $xl.Workbooks.Open($cmdletTemplate)
	#$wb = $xl.Workbooks.Add()
	$ifSheet = $wb.worksheets.item(1)
	#$ifSheet.Name = "Interface"
	$ifSheet.StandardWidth = 20
	$dataSheet = $wb.worksheets.item(2)
	#$dataSheet.Name = "Data"
	#$wb.worksheets.item(3).Delete()

	# Populate the easy stuff.
	$ifSheet.Cells.Item(4, 1) = $cmdlet
	#$ifSheet.Cells.Item(7, 5) = $defaultVIServer.Name
	#$ifSheet.Cells.Item(8, 5) = $defaultVIServer.SessionId

	$xl.visible = $true

	# Based on the types, start populating stuff under the Data sheet.
	$i = 0
	foreach ($key in $parameters.keys) {
		if ($ignore -contains $key) {
			continue
		}
		$i++

		$parameter = $parameters[$key]
		$type = $parameter.ParameterType

		# If the type is an array, figure out the real type.
		# XXX

		# Create the column in the Interface sheet.
		$ifSheet.Cells.Item($ifOffset, $i) = $key

		# If we know how to load instances of this type, load the data in now.
		if ($findObjects[$type]) {
			$values = . $findObjects[$type]

			# Put this data in the Data sheet.
			$j = 1
			foreach ($value in $values) {
				$dataSheet.Cells.Item($j++, $i) = $value.Name
			}

			# Turn this into a named data range.
			$rangeName = $key
			Write-Debug $rangeName

			# Convert the range to R1C1 notation.
			$dataRange = "=Data!R1C{0}:R{1}C{2}" -f $i, ($j-1), $i
			Write-Debug $dataRange
			$name = $wb.names.add($rangename, $null, $true, $null, $null, $null, $null, $null, $null, $dataRange, $null)

			$column = [char]([byte][char]"A" + $i - 1)
			$ifRange = "{0}{1}:{2}{3}" -f $column, $ifOffset, $column, 250
			Write-Debug $ifRange
			# Constrain input in the interface sheet based on this data.
			$range = $ifSheet.Range($ifRange).Select()
			$validation = $xl.Selection.Validation.Add($xlDvType::xlValidateList, $xlDvAlertStyle::xlValidAlertStop,
				$xlFormatConditionOperator::xlBetween, "=$rangename", $null)
		}
	}
	
	$range = $ifSheet.Range("A1").Select()

	# Wait for the file to get updated.
	do {
		Write-Debug "Waiting"
		Start-Sleep 1
		$thisWriteTime = (Get-ChildItem $csvFile -ea silentlycontinue).LastWriteTime
	} while ($thisWriteTime -le $startWriteTime)

	# Run the cmdlet with the data specified.
	$xl.Visible = $false
	$wb.Close($false)
	$xl.Quit()
	foreach ($f in (import-csv $csvFile)) {
		$properties = $f | Get-Member -type NoteProperty
 		$argString = ""
		$objects = @()
		$i = 0
		foreach ($property in $properties) {
			$pName = $property.Name
			#Write-Host ("Property name is " + $pName)
			if ($f.$pName -ne "") {
				#Write-Host ("Property value is " + $f.$pName)

				# Resolve the object.
				$parameter = $parameters[$pName]
				$type = $parameter.ParameterType
				$getter = $findObjects[$type]
				$object = $null
				if ($getter) {
					$lookupExpression = ($getter.ToString() + " -name '" + $f.$pName + "' | Select -first 1")
					#Write-Host ("Looking up using " + $lookupExpression)
					$object = Invoke-Expression $lookupExpression
				} else {
					$object = $f.$pName
				}
				$objects += $object
				#Write-Host $objects
				$argString += (" -" + $pName + " `$objects[$i]")
				#Write-Host ("Set " + $pName + " to " + $objects[$i])
				$i++
			}
		}
		$command = $cmdlet + $argString
		#Write-Host $command
		Invoke-Expression $command
	}
}

#Get-ExcelFrontEnd Add-BulkHosts
#Get-ExcelFrontEnd New-DummyVM

