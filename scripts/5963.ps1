#Requires -version 2
<#
Microsoft PowerShell Source File
NAME  : UserManagement.ps1 v3.10
AUTHOR: YellowOnline
DATE  : 19-29/05/2015; 27-31/07/2015
#>

$ForestName = "microsoft.com"
$Credentials = Get-Credential
$Username = $Credentials.UserName
$Password = $Credentials.GetNetworkCredential().Password
$WorkingPath = $ENV:HOMESHARE

#region Assemblies
[void][Reflection.Assembly]::Load("System, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
[void][Reflection.Assembly]::Load("System.Windows.Forms, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
[void][Reflection.Assembly]::Load("System.Drawing, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
[void][Reflection.Assembly]::Load("mscorlib, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
[void][Reflection.Assembly]::Load("System.Data, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
[void][Reflection.Assembly]::Load("System.Xml, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
[void][Reflection.Assembly]::Load("System.DirectoryServices, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
[void][reflection.assembly]::Load("System.Core, Version=3.5.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089")
[void][reflection.assembly]::Load("System.ServiceProcess, Version=2.0.0.0, Culture=neutral, PublicKeyToken=b03f5f7f11d50a3a")
#endregion Assemblies

#region Functions (Yellow)
Function Convert-DNtoEMail ([string]$DN)
	{
	[string]$EMail = $DN
	Return $EMail;
	}

Function Get-DN ($FQDN)
	{
	$FQDNArray = $FQDN.Split(".")
	$Separator = ","
	For ($x = 0; $x -LT $FQDNArray.Length ; $x++)
		{ 
		If ($x -EQ ($FQDNArray.Length - 1)) { $Separator = "" }
		[string]$DN += "DC=" + $FQDNArray[$x] + $Separator
		}
	Return $DN
	}

Function Get-FQDN ($x)
	{
	#OK, this is quick and dirty
	$y = $x -Split "DC="
	$a = $y | Select-Object -Skip 1 | % {$_.Replace(",",".")}
	$b = $a + $y[0] -Replace "CN=","/" -Replace "OU=","/" -Replace ",","" #to do: escaped commas \, -> regex
	$b = -join $b
	$b
	}

Function Get-UserStatus ($UAC)
	{
	Switch ($UAC) 
    	{ 
        512 {"Enabled"} 
        514 {"Disabled"} 
        66048 {"Enabled"} 
        66050 {"Disabled"} 
		Default {"Unknown"}
        }
	}

Function Prepare-Filter
	{
	$i = 0
	ForEach ($Row in $Table.Rows){$i++}
	$txtLog.Text = $txtLog.Text + "$i row(s)`r`n"
		
	$Columns = $Table | Get-Member | Where-Object {$_.MemberType -EQ 'Property'} | Select-Object Name
	ForEach ($Column in $Columns) 
		{            
	    $cbxColumn.Items.Add($Column.Name)            
	    } 

	$Operators = @("LIKE","NOT LIKE")
	ForEach ($Operator in $Operators) 
		{            
	    $cbxOperator.Items.Add($Operator)            
	    } 
	$cbxOperator.SelectedIndex = 0	
	}
#endregion Functions (Yellow)	

#region Functions (Sapien)
Function OnApplicationLoad() 
	{
	Return $True
	}

Function OnApplicationExit()
	{
	$script:ExitCode = 0
	}

Function Load-DataGridView()
	{
	<#
	.SYNOPSIS
		This functions helps you load items into a DataGridView.

	.DESCRIPTION
		Use this function to dynamically load items into the DataGridView control.

	.PARAMETER  DataGridView
		The ComboBox control you want to add items to.

	.PARAMETER  Item
		The object or objects you wish to load into the ComboBox's items collection.
	
	.PARAMETER  DataMember
		Sets the name of the list or table in the data source for which the DataGridView is displaying data.

	#>
	Param (
		[ValidateNotNull()]
		[Parameter(Mandatory=$true)]
		[System.Windows.Forms.DataGridView]$DataGridView,
		[ValidateNotNull()]
		[Parameter(Mandatory=$true)]
		$Item,
	    [Parameter(Mandatory=$false)]
		[string]$DataMember
	)
	$DataGridView.SuspendLayout()
	$DataGridView.DataMember = $DataMember
	
	If ($Item -is [System.ComponentModel.IListSource] -Or $Item -is [System.ComponentModel.IBindingList] -Or $Item -is [System.ComponentModel.IBindingListView])
		{
		$DataGridView.DataSource = $Item
		}
	Else
		{
		$array = New-Object System.Collections.ArrayList
		
		If ($Item -is [System.Collections.IList])
			{
			$array.AddRange($Item)
			}
		Else
			{	
			$array.Add($Item)	
			}
		$DataGridView.DataSource = $array
		}
	$DataGridView.ResumeLayout()
	}

Function ConvertTo-DataTable()
	{
	<#
		.SYNOPSIS
			Converts objects into a DataTable.
	
		.DESCRIPTION
			Converts objects into a DataTable, which are used for DataBinding.
	
		.PARAMETER  InputObject
			The input to convert into a DataTable.
	
		.PARAMETER  Table
			The DataTable you wish to load the input into.
	
		.PARAMETER RetainColumns
			This switch tells the function to keep the DataTable's existing columns.
		
		.PARAMETER FilterWMIProperties
			This switch removes WMI properties that start with an underline.
	
		.EXAMPLE
			$DataTable = ConvertTo-DataTable -InputObject (Get-Process)
	#>
	[OutputType([System.Data.DataTable])]
	Param([ValidateNotNull()]$InputObject,[ValidateNotNull()][System.Data.DataTable]$Table,[switch]$RetainColumns,[switch]$FilterWMIProperties)
	If($Table -EQ $null)
		{
		$Table = New-Object System.Data.DataTable
		}

	If($InputObject -is [System.Data.DataTable])
		{
		$Table = $InputObject
		}
	Else
		{
		If (-Not $RetainColumns -Or $Table.Columns.Count -EQ 0)
			{
			#Clear out the Table Contents
			$Table.Clear()

			If ($InputObject -EQ $Null)
				{
				Return 
				} 
			
			$object = $Null
			#find the first non null value
			ForEach ($item in $InputObject)
				{
				If ($item -NE $Null)
					{
					$object = $item
					Break	
					}
				}

			If ($object -EQ $null) 
				{
				Return 
				}
			
			#Get all the properties in order to create the columns
			ForEach ($prop in $object.PSObject.Get_Properties())
				{
				If (-Not $FilterWMIProperties -Or -Not $prop.Name.StartsWith('__'))#filter out WMI properties
					{
					#Get the type from the Definition string
					$type = $Null
					
					If ($prop.Value -NE $Null)
						{
						Try
							{
							$type = $prop.Value.GetType()
							} 
						Catch 
							{
							}
						}

					If ($type -NE $Null) # -and [System.Type]::GetTypeCode($type) -ne 'Object')
						{
		      			[void]$Table.Columns.Add($prop.Name, $type) 
						}
					Else #Type info not found
						{ 
						[void]$Table.Columns.Add($prop.Name) 	
						}
					}
		    	}
			
			If ($object -is [System.Data.DataRow])
				{
				ForEach($item in $InputObject)
					{	
					$Table.Rows.Add($item)
					}
				Return  @(,$Table)
				}
			}
		Else
			{
			$Table.Rows.Clear()	
			}
		
		ForEach ($item in $InputObject)
			{		
			$row = $Table.NewRow()
			
			If($item)
				{
				ForEach ($prop in $item.PSObject.Get_Properties())
					{
					If($Table.Columns.Contains($prop.Name))
						{
						$row.Item($prop.Name) = $prop.Value
						}
					}
				}
			[void]$Table.Rows.Add($row)
			}
		}
	Return @(,$Table)	
	}

Function Load-ListBox()
	{
<#
	.SYNOPSIS
		This functions helps you load items into a ListBox or CheckedListBox.

	.DESCRIPTION
		Use this function to dynamically load items into the ListBox control.

	.PARAMETER  ListBox
		The ListBox control you want to add items to.

	.PARAMETER  Items
		The object or objects you wish to load into the ListBox's Items collection.

	.PARAMETER  DisplayMember
		Indicates the property to display for the items in this control.
	
	.PARAMETER  Append
		Adds the item(s) to the ListBox without clearing the Items collection.
	
	.EXAMPLE
		Load-ListBox $ListBox1 "Red", "White", "Blue"
	
	.EXAMPLE
		Load-ListBox $listBox1 "Red" -Append
		Load-ListBox $listBox1 "White" -Append
		Load-ListBox $listBox1 "Blue" -Append
	
	.EXAMPLE
		Load-ListBox $listBox1 (Get-Process) "ProcessName"
#>
	Param (
		[ValidateNotNull()]
		[Parameter(Mandatory=$true)]
		[System.Windows.Forms.ListBox]$ListBox,
		[ValidateNotNull()]
		[Parameter(Mandatory=$true)]
		$Items,
	    [Parameter(Mandatory=$false)]
		[string]$DisplayMember,
		[switch]$Append
	)
	
	if(-not $Append)
		{
		$listBox.Items.Clear()	
		}
	
	if($Items -is [System.Windows.Forms.ListBox+ObjectCollection])
		{
		$listBox.Items.AddRange($Items)
		}
	elseif ($Items -is [Array])
		{
		$listBox.BeginUpdate()
		foreach($obj in $Items)
			{
			$listBox.Items.Add($obj)
			}
		$listBox.EndUpdate()
		}
	else
		{
		$listBox.Items.Add($Items)	
		}

	$listBox.DisplayMember = $DisplayMember	
	}

Function Load-ComboBox 
{
<#
	.SYNOPSIS
		This functions helps you load items into a ComboBox.

	.DESCRIPTION
		Use this function to dynamically load items into the ComboBox control.

	.PARAMETER  ComboBox
		The ComboBox control you want to add items to.

	.PARAMETER  Items
		The object or objects you wish to load into the ComboBox's Items collection.

	.PARAMETER  DisplayMember
		Indicates the property to display for the items in this control.
	
	.PARAMETER  Append
		Adds the item(s) to the ComboBox without clearing the Items collection.
	
	.EXAMPLE
		Load-ComboBox $combobox1 "Red", "White", "Blue"
	
	.EXAMPLE
		Load-ComboBox $combobox1 "Red" -Append
		Load-ComboBox $combobox1 "White" -Append
		Load-ComboBox $combobox1 "Blue" -Append
	
	.EXAMPLE
		Load-ComboBox $combobox1 (Get-Process) "ProcessName"
#>
	Param (
		[ValidateNotNull()]
		[Parameter(Mandatory=$true)]
		[System.Windows.Forms.ComboBox]$ComboBox,
		[ValidateNotNull()]
		[Parameter(Mandatory=$true)]
		$Items,
	    [Parameter(Mandatory=$false)]
		[string]$DisplayMember,
		[switch]$Append
	)
	
	if(-not $Append)
	{
		$ComboBox.Items.Clear()	
	}
	
	if($Items -is [Object[]])
	{
		$ComboBox.Items.AddRange($Items)
	}
	elseif ($Items -is [Array])
	{
		$ComboBox.BeginUpdate()
		foreach($obj in $Items)
		{
			$ComboBox.Items.Add($obj)	
		}
		$ComboBox.EndUpdate()
	}
	else
	{
		$ComboBox.Items.Add($Items)	
	}

	$ComboBox.DisplayMember = $DisplayMember	
}
#endregion Functions (Sapien)

#region Main functions
Function Main([String]$Commandline)
	{
	If((Call-MainForm_pff) -EQ "OK"){}
	$global:ExitCode = 0
	}

Function Call-MainForm_pff
	{
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$frmMain = New-Object 'System.Windows.Forms.Form'
	$btnReset = New-Object 'System.Windows.Forms.Button'
	$cbxAdvanced = New-Object 'System.Windows.Forms.CheckBox'
	$txtAdvancedFilter = New-Object 'System.Windows.Forms.TextBox'
	$btnFilter = New-Object 'System.Windows.Forms.Button'
	$txtSearchText = New-Object 'System.Windows.Forms.TextBox'
	$cbxOperator = New-Object 'System.Windows.Forms.ComboBox'
	$cbxColumn = New-Object 'System.Windows.Forms.ComboBox'
	$btnClearLog = New-Object 'System.Windows.Forms.Button'
	$txtLog = New-Object 'System.Windows.Forms.TextBox'
	$btnCommitToAD = New-Object 'System.Windows.Forms.Button'
	$btnExportSelectionToCSV = New-Object 'System.Windows.Forms.Button'
	$btnDeleteSelectionFromCSV = New-Object 'System.Windows.Forms.Button'
	$boxPicture2 = New-Object 'System.Windows.Forms.PictureBox'
	$boxPicture1 = New-Object 'System.Windows.Forms.PictureBox'
	$btnGetDataFromAD = New-Object 'System.Windows.Forms.Button'
	$btnSaveCSV = New-Object 'System.Windows.Forms.Button'
	$btnOpenCSV = New-Object 'System.Windows.Forms.Button'
	$dgvResults = New-Object 'System.Windows.Forms.DataGridView'
	$btnExit = New-Object 'System.Windows.Forms.Button'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'
	
	$FormEvent_Load={}
	
	$btnExit_Click={$frmMain.Close()}
	
	$btnSave_Click=
		{
		$dlgSaveFile 					= New-Object System.Windows.Forms.SaveFileDialog
		$dlgSaveFile.ShowHelp 			= $True
		$dlgSaveFile.AddExtension 		= ".csv"
		$dlgSaveFile.InitialDirectory 	= "$WorkingPath"
		$dlgSaveFile.Filter 			= "CSV files (*.csv)| *.csv"
		$dlgSaveFile.OverwritePrompt 	= $True
		$dlgSaveFile.CreatePrompt 		= $True
		[void]$dlgSaveFile.ShowDialog()
		$dgvResults.Rows | Select-Object -Expand DataBoundItem | Export-CSV $dlgSaveFile.FileName -NoTypeInformation -Encoding UTF8 -Delimiter ";"
		#TODO: catch 'Cancel'
		}
	
	$btnLoad_Click={
		$dlgOpenFile 					= New-Object System.Windows.Forms.OpenFileDialog
		$dlgOpenFile.ShowHelp 			= $True
		$dlgOpenFile.InitialDirectory 	= "$WorkingPath"
		$dlgOpenFile.Filter 			= "CSV files (*.csv)| *.csv"
		[void]$dlgOpenFile.ShowDialog()
		$Data = Import-Csv $dlgOpenFile.FileName -Delimiter ";"
		$Table = ConvertTo-DataTable -InputObject $Data -FilterWMIProperties
		Load-DataGridView -DataGridView $dgvResults -Item $Table
		}
	
	$btnGetDataFromAD_Click={If((Call-ChildForm_pff) -EQ 'OK'){}}
	
	$dgvResults_ColumnHeaderMouseClick=[System.Windows.Forms.DataGridViewCellMouseEventHandler]{
		If($dgvResults.DataSource -is [System.Data.DataTable])
			{
			$Column = $dgvResults.Columns[$_.ColumnIndex]
			$Direction = [System.ComponentModel.ListSortDirection]::Ascending
			
			If ($Column.HeaderCell.SortGlyphDirection -EQ 'Descending')
				{
				$Direction = [System.ComponentModel.ListSortDirection]::Descending
				}
			$dgvResults.Sort($dgvResults.Columns[$_.ColumnIndex], $Direction)
			}
		}
	
	$btnExportSelectionToCSV_Click=
		{
		$dlgExportSelection 					= New-Object System.Windows.Forms.SaveFileDialog
		$dlgExportSelection.ShowHelp 			= $True
		$dlgExportSelection.AddExtension 		= ".csv"
		$dlgExportSelection.InitialDirectory 	= "$WorkingPath"
		$dlgExportSelection.Filter 				= "CSV files (*.csv)| *.csv"
		$dlgExportSelection.OverwritePrompt 	= $True
		$dlgExportSelection.CreatePrompt 		= $True
		[void]$dlgExportSelection.ShowDialog()
		$dgvResults.SelectedRows | Select-Object -Expand DataBoundItem | Export-CSV $dlgExportSelection.FileName -NoTypeInformation -Encoding UTF8 -Delimiter ";"
		#TODO: catch 'Cancel'
		}
	
	$btnDeleteSelectionFromCSV_Click=
		{
		ForEach ($SelectedRow in $dgvResults.SelectedRows)
			{
			$dgvResults.Rows.Remove($SelectedRow)
			}
		}
	
	$btnCommitSelectionToAD_Click={If((Call-ChildForm2_pff) -EQ 'OK'){}}
	
	$btnClearLog_Click={$txtLog.Text = ""}
	
	$btnFilter_Click=
		{
		If (!$AdvancedFilter){$Query = "$($cbxColumn.Text) $($cbxOperator.Text) `'*$($txtSearchText.Text)*`'"}
		Else {$Query = $txtAdvancedFilter.Text}
		Try {$Table.DefaultView.RowFilter = $Query}
		Catch {$txtLog.Text = $txtLog.Text + "$($error[0])`r`n"}
		Load-DataGridView -DataGridView $dgvResults -Item $Table.DefaultView
		$i = 0
		ForEach ($Row in $Table.DefaultView){$i++}
		$txtLog.Text = $txtLog.Text + "$i row(s)`r`n"
		}
	
	$btnReset_Click=
		{
		$Query = "$('Company') $('LIKE') '**'"
		$txtAdvancedFilter.Text = $Query
		Try {$Table.DefaultView.RowFilter = $Query}
		Catch {$txtLog.Text = $txtLog.Text + "$($error[0])`r`n"}
		Load-DataGridView -DataGridView $dgvResults -Item $Table.DefaultView
		$i = 0
		ForEach ($Row in $Table.DefaultView){$i++}
		$txtLog.Text = $txtLog.Text + "$i row(s)`r`n"
		}
	
	$cbxAdvanced_CheckedChanged=
		{
		If ($cbxAdvanced.Checked -EQ $True)
			{
			$txtAdvancedFilter.Visible = $True
			$cbxColumn.Enabled = $False
			$cbxOperator.Enabled = $False
			$txtSearchText.Enabled = $False
			$AdvancedFilter = $True
			}
		If ($cbxAdvanced.Checked -EQ $False)
			{
			$txtAdvancedFilter.Visible = $False
			$cbxColumn.Enabled = $True
			$cbxOperator.Enabled = $True
			$txtSearchText.Enabled = $True
			$AdvancedFilter = $False
			}
		}
	
	$Form_StateCorrection_Load={$frmMain.WindowState = $InitialFormWindowState}
	
	$Form_StoreValues_Closing=
		{
		$script:MainForm_cbxAdvanced = $cbxAdvanced.Checked
		$script:MainForm_txtAdvancedFilter = $txtAdvancedFilter.Text
		$script:MainForm_txtSearchText = $txtSearchText.Text
		$script:MainForm_cbxOperator = $cbxOperator.Text
		$script:MainForm_cbxColumn = $cbxColumn.Text
		$script:MainForm_txtLog = $txtLog.Text
		}

	
	$Form_Cleanup_FormClosed=
		{
		Try
			{
			$btnReset.remove_Click($btnReset_Click)
			$cbxAdvanced.remove_CheckedChanged($cbxAdvanced_CheckedChanged)
			$txtAdvancedFilter.remove_KeyDown($btnFilter_Click)
			$btnFilter.remove_Click($btnFilter_Click)
			$txtSearchText.remove_KeyDown($btnFilter_Click)
			$btnClearLog.remove_Click($btnClearLog_Click)
			$btnCommitToAD.remove_Click($btnCommitSelectionToAD_Click)
			$btnExportSelectionToCSV.remove_Click($btnExportSelectionToCSV_Click)
			$btnDeleteSelectionFromCSV.remove_Click($btnDeleteSelectionFromCSV_Click)
			$btnGetDataFromAD.remove_Click($btnGetDataFromAD_Click)
			$btnSaveCSV.remove_Click($btnSave_Click)
			$btnOpenCSV.remove_Click($btnLoad_Click)
			$dgvResults.remove_ColumnHeaderMouseClick($dgvResults_ColumnHeaderMouseClick)
			$btnExit.remove_Click($btnExit_Click)
			$frmMain.remove_Load($FormEvent_Load)
			$frmMain.remove_Load($Form_StateCorrection_Load)
			$frmMain.remove_Closing($Form_StoreValues_Closing)
			$frmMain.remove_FormClosed($Form_Cleanup_FormClosed)
			}
		Catch [Exception]{ }
		}

	$frmMain.Controls.Add($btnReset)
	$frmMain.Controls.Add($cbxAdvanced)
	$frmMain.Controls.Add($txtAdvancedFilter)
	$frmMain.Controls.Add($btnFilter)
	$frmMain.Controls.Add($txtSearchText)
	$frmMain.Controls.Add($cbxOperator)
	$frmMain.Controls.Add($cbxColumn)
	$frmMain.Controls.Add($btnClearLog)
	$frmMain.Controls.Add($txtLog)
	$frmMain.Controls.Add($btnCommitToAD)
	$frmMain.Controls.Add($btnExportSelectionToCSV)
	$frmMain.Controls.Add($btnDeleteSelectionFromCSV)
	$frmMain.Controls.Add($boxPicture2)
	$frmMain.Controls.Add($boxPicture1)
	$frmMain.Controls.Add($btnGetDataFromAD)
	$frmMain.Controls.Add($btnSaveCSV)
	$frmMain.Controls.Add($btnOpenCSV)
	$frmMain.Controls.Add($dgvResults)
	$frmMain.Controls.Add($btnExit)
	$frmMain.ClientSize = '1024, 814'
	$frmMain.MinimumSize = '1024, 814'
	$frmMain.Name = "frmMain"
	$frmMain.StartPosition = 'CenterScreen'
	$frmMain.Text = "User Management v3.10"
	$frmMain.add_Load($FormEvent_Load)

	$btnReset.Anchor = 'Bottom, Right'
	$btnReset.FlatStyle = 'Flat'
	$btnReset.ForeColor = 'ControlDarkDark'
	$btnReset.Location = '937, 710'
	$btnReset.Name = "btnReset"
	$btnReset.Size = '75, 23'
	$btnReset.TabIndex = 17
	$btnReset.Text = "Reset"
	$btnReset.UseVisualStyleBackColor = $True
	$btnReset.add_Click($btnReset_Click)

	
	$cbxAdvanced.Anchor = 'Bottom, Right'
	$cbxAdvanced.Location = '937, 738'
	$cbxAdvanced.Name = "cbxAdvanced"
	$cbxAdvanced.Size = '77, 24'
	$cbxAdvanced.TabIndex = 16
	$cbxAdvanced.Text = "Advanced"
	$cbxAdvanced.UseVisualStyleBackColor = $True
	$cbxAdvanced.add_CheckedChanged($cbxAdvanced_CheckedChanged)

	$txtAdvancedFilter.Anchor = 'Bottom, Right'
	$txtAdvancedFilter.Location = '574, 712'
	$txtAdvancedFilter.Name = "txtAdvancedFilter"
	$txtAdvancedFilter.Size = '356, 20'
	$txtAdvancedFilter.TabIndex = 14
	$txtAdvancedFilter.Visible = $False
	$txtAdvancedFilter.add_KeyDown($btnFilter_Click)
	
	$btnFilter.Anchor = 'Bottom, Right'
	$btnFilter.FlatStyle = 'Flat'
	$btnFilter.ForeColor = 'ControlDarkDark'
	$btnFilter.Location = '937, 686'
	$btnFilter.Name = "btnFilter"
	$btnFilter.Size = '75, 23'
	$btnFilter.TabIndex = 13
	$btnFilter.Text = "Filter"
	$btnFilter.UseVisualStyleBackColor = $True
	$btnFilter.add_Click($btnFilter_Click)

	$txtSearchText.Anchor = 'Bottom, Right'
	$txtSearchText.Location = '830, 686'
	$txtSearchText.Name = "txtSearchText"
	$txtSearchText.Size = '100, 20'
	$txtSearchText.TabIndex = 12
	$txtSearchText.add_KeyDown($btnFilter_Click)

	$cbxOperator.Anchor = 'Bottom, Right'
	$cbxOperator.FormattingEnabled = $True
	$cbxOperator.Location = '702, 686'
	$cbxOperator.Name = "cbxOperator"
	$cbxOperator.Size = '121, 21'
	$cbxOperator.TabIndex = 11

	$cbxColumn.Anchor = 'Bottom, Right'
	$cbxColumn.FormattingEnabled = $True
	$cbxColumn.Location = '574, 686'
	$cbxColumn.Name = "cbxColumn"
	$cbxColumn.Size = '121, 21'
	$cbxColumn.TabIndex = 10

	$btnClearLog.Anchor = 'Bottom, Right'
	$btnClearLog.BackColor = 'ControlLight'
	$btnClearLog.FlatStyle = 'Popup'
	$btnClearLog.Location = '469, 686'
	$btnClearLog.Name = "btnClearLog"
	$btnClearLog.Size = '75, 23'
	$btnClearLog.TabIndex = 9
	$btnClearLog.Text = "Clear Log"
	$btnClearLog.UseVisualStyleBackColor = $False
	$btnClearLog.add_Click($btnClearLog_Click)

	$txtLog.Anchor = 'Bottom, Left, Right'
	$txtLog.Location = '12, 686'
	$txtLog.Multiline = $True
	$txtLog.Name = "txtLog"
	$txtLog.ReadOnly = $True
	$txtLog.ScrollBars = 'Vertical'
	$txtLog.Size = '451, 76'
	$txtLog.TabIndex = 8

	$btnCommitToAD.Anchor = 'Bottom, Left'
	$btnCommitToAD.FlatStyle = 'Flat'
	$btnCommitToAD.Location = '747, 779'
	$btnCommitToAD.Name = "btnCommitToAD"
	$btnCommitToAD.Size = '141, 23'
	$btnCommitToAD.TabIndex = 6
	$btnCommitToAD.Text = "&Commit selection to AD"
	$btnCommitToAD.UseVisualStyleBackColor = $True
	$btnCommitToAD.add_Click($btnCommitSelectionToAD_Click)

	$btnExportSelectionToCSV.Anchor = 'Bottom, Left'
	$btnExportSelectionToCSV.FlatStyle = 'Flat'
	$btnExportSelectionToCSV.Location = '600, 779'
	$btnExportSelectionToCSV.Name = "btnExportSelectionToCSV"
	$btnExportSelectionToCSV.Size = '141, 23'
	$btnExportSelectionToCSV.TabIndex = 5
	$btnExportSelectionToCSV.Text = "&Export selection to CSV"
	$btnExportSelectionToCSV.UseVisualStyleBackColor = $True
	$btnExportSelectionToCSV.add_Click($btnExportSelectionToCSV_Click)

	$btnDeleteSelectionFromCSV.Anchor = 'Bottom, Left'
	$btnDeleteSelectionFromCSV.FlatStyle = 'Flat'
	$btnDeleteSelectionFromCSV.Location = '453, 779'
	$btnDeleteSelectionFromCSV.Name = "btnDeleteSelectionFromCSV"
	$btnDeleteSelectionFromCSV.Size = '141, 23'
	$btnDeleteSelectionFromCSV.TabIndex = 4
	$btnDeleteSelectionFromCSV.Text = "&Delete selection f CSV"
	$btnDeleteSelectionFromCSV.UseVisualStyleBackColor = $True
	$btnDeleteSelectionFromCSV.add_Click($btnDeleteSelectionFromCSV_Click)

	$boxPicture2.Image = ''
	$boxPicture2.Location = '12, 13'
	$boxPicture2.Name = "boxPicture2"
	$boxPicture2.Size = '230, 69'
	$boxPicture2.TabIndex = 7
	$boxPicture2.TabStop = $False

	$boxPicture1.Anchor = 'Top, Right'
	$boxPicture1.Image = ''
	$boxPicture1.Location = '778, 13'
	$boxPicture1.Name = "boxPicture1"
	$boxPicture1.Size = '234, 69'
	$boxPicture1.TabIndex = 6
	$boxPicture1.TabStop = $False

	$btnGetDataFromAD.Anchor = 'Bottom, Left'
	$btnGetDataFromAD.FlatStyle = 'Flat'
	$btnGetDataFromAD.Location = '306, 779'
	$btnGetDataFromAD.Name = "btnGetDataFromAD"
	$btnGetDataFromAD.Size = '141, 23'
	$btnGetDataFromAD.TabIndex = 3
	$btnGetDataFromAD.Text = "&Get Data from AD"
	$btnGetDataFromAD.UseVisualStyleBackColor = $True
	$btnGetDataFromAD.add_Click($btnGetDataFromAD_Click)

	$btnSaveCSV.Anchor = 'Bottom, Left'
	$btnSaveCSV.FlatStyle = 'Flat'
	$btnSaveCSV.Location = '12, 779'
	$btnSaveCSV.Name = "btnSaveCSV"
	$btnSaveCSV.Size = '141, 23'
	$btnSaveCSV.TabIndex = 1
	$btnSaveCSV.Text = "&Save CSV"
	$btnSaveCSV.UseVisualStyleBackColor = $True
	$btnSaveCSV.add_Click($btnSave_Click)

	$btnOpenCSV.Anchor = 'Bottom, Left'
	$btnOpenCSV.FlatStyle = 'Flat'
	$btnOpenCSV.Location = '159, 779'
	$btnOpenCSV.Name = "btnOpenCSV"
	$btnOpenCSV.Size = '141, 23'
	$btnOpenCSV.TabIndex = 2
	$btnOpenCSV.Text = "&Open CSV"
	$btnOpenCSV.UseVisualStyleBackColor = $True
	$btnOpenCSV.add_Click($btnLoad_Click)

	$dgvResults.AllowUserToAddRows = $False
	$dgvResults.AllowUserToDeleteRows = $False
	$dgvResults.AllowUserToOrderColumns = $True
	$dgvResults.AllowUserToResizeRows = $False
	$System_Windows_Forms_DataGridViewCellStyle_1 = New-Object 'System.Windows.Forms.DataGridViewCellStyle'
	$System_Windows_Forms_DataGridViewCellStyle_1.BackColor = '255, 255, 192'
	$dgvResults.AlternatingRowsDefaultCellStyle = $System_Windows_Forms_DataGridViewCellStyle_1
	$dgvResults.Anchor = 'Top, Bottom, Left, Right'
	$dgvResults.Location = '12, 88'
	$dgvResults.Name = "dgvResults"
	$dgvResults.ShowEditingIcon = $False
	$dgvResults.Size = '1000, 591'
	$dgvResults.TabIndex = 7
	$dgvResults.add_ColumnHeaderMouseClick($dgvResults_ColumnHeaderMouseClick)

	$btnExit.Anchor = 'Bottom, Right'
	$btnExit.FlatStyle = 'Flat'
	$btnExit.Location = '937, 779'
	$btnExit.Name = "btnExit"
	$btnExit.Size = '75, 23'
	$btnExit.TabIndex = 1
	$btnExit.Text = "E&xit"
	$btnExit.UseVisualStyleBackColor = $True
	$btnExit.add_Click($btnExit_Click)

	$InitialFormWindowState = $frmMain.WindowState
	$frmMain.add_Load($Form_StateCorrection_Load)
	$frmMain.add_FormClosed($Form_Cleanup_FormClosed)
	$frmMain.add_Closing($Form_StoreValues_Closing)
	Return $frmMain.ShowDialog()

	}

Function Call-ChildForm_pff
	{
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$frmSelectDomain = New-Object 'System.Windows.Forms.Form'
	$btnCancel = New-Object 'System.Windows.Forms.Button'
	$btnOK = New-Object 'System.Windows.Forms.Button'
	$boxCheckedList = New-Object 'System.Windows.Forms.CheckedListBox'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'

	$frmSelectDomain_Load=
		{
		$adCtx = New-Object System.DirectoryServices.ActiveDirectory.DirectoryContext("forest", $ForestName, $Username, $Password)
		$Forest = ([System.DirectoryServices.ActiveDirectory.Forest]::GetForest($adCtx))  
		$Domains = $Forest.Domains | Select-Object Name
		ForEach ($Domain in $Domains) 
			{
			Load-Listbox $boxCheckedList $Domain.Name -Append
			}
		}
	
	$btnCancel_Click={$frmSelectDomain.Close()}
	
	$btnOK_Click={
		$MeasureDataFetch = Measure-Command	{
		$SelectedDomains = @()
		$ForestUsers = @()
		ForEach ($objCheckedList in $boxCheckedList.CheckedItems)
			{
			$SelectedDomains += $objCheckedList	
			}
		ForEach ($SelectedDomain in $SelectedDomains) 
			{
			$objDomain = New-Object System.DirectoryServices.DirectoryEntry "LDAP://$SelectedDomain", $Username, $Password
			$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
			$objSearcher.SearchRoot = $objDomain
			$objSearcher.PageSize = 5000
			$objSearcher.Filter = "(&(objectCategory=person)(objectClass=user))"
			$objSearcher.SearchScope = "Subtree"
			$RawUsers = $objSearcher.FindAll()
			$Users = $RawUsers | Select-Object `
			@{e={(Get-FQDN $_.properties.distinguishedname).Split("/")[0]};n='Domain'},`
			@{e={Get-FQDN $_.properties.distinguishedname};n='Distinguished Name'},`
			@{e={$_.properties.samaccountname};n='UserName'},`
			@{e={[datetime]::FromFileTimeUtc([int64]$_.properties.lastlogontimestamp[0])};n='LastLogon'},`
			@{e={Get-UserStatus $_.properties.useraccountcontrol};n='Status'},`
			@{e={$_.properties.givenname};n='GivenName'},`
			@{e={$_.properties.sn};n='Surname'},`
			@{e={$_.properties.displayname};n='DisplayName'},`
			@{e={$_.properties.mail};n='Mail'},`
			@{e={$_.properties.altrecipient};n='Forwarding'},`
			@{e={$_.properties.description};n='Description'},`
			@{e={$_.properties.title};n='Title'},`
			@{e={$_.properties.streetaddress};n='StreetAddress'},`
			@{e={$_.properties.postalcode};n='PostalCode'},`
			@{e={$_.properties.l};n='City'},`
			@{e={$_.properties.c};n='Country'},`
			@{e={$_.properties.company};n='Company'},`
			@{e={$_.properties.wwwhomepage};n='HomePage'},`
			@{e={$_.properties.telephonenumber};n='OfficePhone'},`
			@{e={$_.properties.homephone};n='HomePhone'},`
			@{e={$_.properties.mobile};n='MobilePhone'},`
			@{e={$_.properties.facsimiletelephonenumber};n='Fax'}
			$ForestUsers = $ForestUsers + $Users
			}
		}
		$TempDataFromAD = $($WorkingPath + "\" + "Temp.csv")
		$ForestUsers | Export-CSV $TempDataFromAD -Delimiter ";" -Encoding UTF8 -NoTypeInformation		
		$Data = Import-Csv $TempDataFromAD -Delimiter ";"
		$script:Table = ConvertTo-DataTable -InputObject $Data -FilterWMIProperties
		Load-DataGridView -DataGridView $dgvResults -Item $Table
		$txtLog.Text = $txtLog.Text + "Query took " + $MeasureDataFetch.TotalSeconds + " seconds`r`n"
		Remove-Item $TempDataFromAD -Force
		Prepare-Filter
		$frmSelectDomain.Close()
		}
		
	$Form_StateCorrection_Load=
		{
		$frmSelectDomain.WindowState = $InitialFormWindowState
		}
	
	$Form_StoreValues_Closing=
		{
		$script:ChildForm_boxCheckedList = $boxCheckedList.SelectedItems
		}

	
	$Form_Cleanup_FormClosed=
		{
		Try
		{
			$btnCancel.remove_Click($btnCancel_Click)
			$btnOK.remove_Click($btnOK_Click)
			$frmSelectDomain.remove_Load($frmSelectDomain_Load)
			$frmSelectDomain.remove_Load($Form_StateCorrection_Load)
			$frmSelectDomain.remove_Closing($Form_StoreValues_Closing)
			$frmSelectDomain.remove_FormClosed($Form_Cleanup_FormClosed)
		}
		Catch [Exception]{ }
	}

	$frmSelectDomain.Controls.Add($btnCancel)
	$frmSelectDomain.Controls.Add($btnOK)
	$frmSelectDomain.Controls.Add($boxCheckedList)
	$frmSelectDomain.ClientSize = '284, 335'
	$frmSelectDomain.Name = "frmSelectDomain"
	$frmSelectDomain.ShowIcon = $False
	$frmSelectDomain.StartPosition = 'CenterParent'
	$frmSelectDomain.Text = "Select Domain"
	$frmSelectDomain.add_Load($frmSelectDomain_Load)

	$btnCancel.FlatStyle = 'Flat'
	$btnCancel.Location = '95, 294'
	$btnCancel.Name = "btnCancel"
	$btnCancel.Size = '75, 23'
	$btnCancel.TabIndex = 2
	$btnCancel.Text = "Cancel"
	$btnCancel.UseVisualStyleBackColor = $True
	$btnCancel.add_Click($btnCancel_Click)

	$btnOK.FlatStyle = 'Flat'
	$btnOK.Location = '13, 294'
	$btnOK.Name = "btnOK"
	$btnOK.Size = '75, 23'
	$btnOK.TabIndex = 1
	$btnOK.Text = "OK"
	$btnOK.UseVisualStyleBackColor = $True
	$btnOK.add_Click($btnOK_Click)

	$boxCheckedList.FormattingEnabled = $True
	$boxCheckedList.Location = '13, 13'
	$boxCheckedList.Name = "boxCheckedList"
	$boxCheckedList.Size = '259, 274'
	$boxCheckedList.TabIndex = 0

	$InitialFormWindowState = $frmSelectDomain.WindowState
	$frmSelectDomain.add_Load($Form_StateCorrection_Load)
	$frmSelectDomain.add_FormClosed($Form_Cleanup_FormClosed)
	$frmSelectDomain.add_Closing($Form_StoreValues_Closing)
	Return $frmSelectDomain.ShowDialog()
	}

Function Call-ChildForm2_pff
	{
	[System.Windows.Forms.Application]::EnableVisualStyles()
	$frmCommitAD = New-Object 'System.Windows.Forms.Form'
	$checkboxMobilePhone = New-Object 'System.Windows.Forms.CheckBox'
	$cbxDescription = New-Object 'System.Windows.Forms.CheckBox'
	$cbxLastLogon = New-Object 'System.Windows.Forms.CheckBox'
	$btnADCancel = New-Object 'System.Windows.Forms.Button'
	$btnADOK = New-Object 'System.Windows.Forms.Button'
	$cbxFax = New-Object 'System.Windows.Forms.CheckBox'
	$cbxMobilePhone = New-Object 'System.Windows.Forms.CheckBox'
	$cbxOfficePhone = New-Object 'System.Windows.Forms.CheckBox'
	$lblCommitToAD = New-Object 'System.Windows.Forms.Label'
	$cbxUserName = New-Object 'System.Windows.Forms.CheckBox'
	$cbxSID = New-Object 'System.Windows.Forms.CheckBox'
	$cbxCanonicalName = New-Object 'System.Windows.Forms.CheckBox'
	$cbxHomePage = New-Object 'System.Windows.Forms.CheckBox'
	$cbxCompany = New-Object 'System.Windows.Forms.CheckBox'
	$cbxCountry = New-Object 'System.Windows.Forms.CheckBox'
	$cbxCity = New-Object 'System.Windows.Forms.CheckBox'
	$cbxPostalCode = New-Object 'System.Windows.Forms.CheckBox'
	$cbxStreetAddress = New-Object 'System.Windows.Forms.CheckBox'
	$cbxTitle = New-Object 'System.Windows.Forms.CheckBox'
	$cbxMail = New-Object 'System.Windows.Forms.CheckBox'
	$cbxDisplayName = New-Object 'System.Windows.Forms.CheckBox'
	$cbxSurName = New-Object 'System.Windows.Forms.CheckBox'
	$cbxGivenName = New-Object 'System.Windows.Forms.CheckBox'
	$InitialFormWindowState = New-Object 'System.Windows.Forms.FormWindowState'

	Function OnApplicationLoad() 
		{
		Return $True
		}	
	
	Function OnApplicationExit() 
		{
		$script:ExitCode = 0
		}
	
	$btnADCancel_Click={$frmCommitAD.Close()}
	
	$btnADOK_Click={
		#To be replaced by something that doesn't use the ActiveDirectory module, because it uses ADWS and is very, very slow
		Import-Module ActiveDirectory
		ForEach ($SelectedRow in $dgvResults.SelectedRows)
				{
				$ADCmdlet = "Set-ADUser"
				$ADIdentity ="-Identity $($SelectedRow.Cells["UserName"].Value)"
				$ADServer = "-Server $($SelectedRow.Cells["Domain"].Value)"
				$ADWhatIf = "-WhatIf"
				$ADCommandString = $ADCmdlet + " " + $ADIdentity + " " + $ADServer + " " + "-Credential (New-Object System.Management.Automation.PSCredential $Username,(ConvertTo-SecureString $Password -AsPlainText -Force))"
				If ($cbxGivenName.Checked -And ($($SelectedRow.Cells["GivenName"].Value) -NE ""))			{$ADCommandString = $ADCommandString + " " + "-GivenName '$($SelectedRow.Cells["GivenName"].Value)'"}
				If ($cbxSurName.Checked -And ($($SelectedRow.Cells["Surname"].Value) -NE ""))				{$ADCommandString = $ADCommandString + " " + "-Surname `"$($SelectedRow.Cells["Surname"].Value)`""}
				If ($cbxDisplayName.Checked -And ($($SelectedRow.Cells["DisplayName"].Value) -NE ""))		{$ADCommandString = $ADCommandString + " " + "-DisplayName '$($SelectedRow.Cells["DisplayName"].Value)'"}
				If ($cbxMail.Checked -And ($($SelectedRow.Cells["Mail"].Value) -NE ""))						{$ADCommandString = $ADCommandString + " " + "-Emailaddress '$($SelectedRow.Cells["Mail"].Value)'"}
				If ($cbxDescription.Checked -And ($($SelectedRow.Cells["Description"].Value) -NE ""))		{$ADCommandString = $ADCommandString + " " + "-Description '$($SelectedRow.Cells["Description"].Value)'"}
				If ($cbxTitle.Checked -And ($($SelectedRow.Cells["Title"].Value) -NE ""))					{$ADCommandString = $ADCommandString + " " + "-Title '$($SelectedRow.Cells["Title"].Value)'"}
				If ($cbxStreetAddress.Checked -And ($($SelectedRow.Cells["StreetAddress"].Value) -NE ""))	{$ADCommandString = $ADCommandString + " " + "-StreetAddress '$($SelectedRow.Cells["StreetAddress"].Value)'"}
				If ($cbxPostalCode.Checked -And ($($SelectedRow.Cells["PostalCode"].Value) -NE ""))			{$ADCommandString = $ADCommandString + " " + "-PostalCode '$($SelectedRow.Cells["PostalCode"].Value)'"}
				If ($cbxCity.Checked -And ($($SelectedRow.Cells["City"].Value) -NE ""))						{$ADCommandString = $ADCommandString + " " + "-City '$($SelectedRow.Cells["City"].Value)'"}
				If ($cbxCountry.Checked -And ($($SelectedRow.Cells["Country"].Value) -NE ""))				{$ADCommandString = $ADCommandString + " " + "-Country '$($SelectedRow.Cells["Country"].Value)'"}
				If ($cbxCompany.Checked -And ($($SelectedRow.Cells["Company"].Value) -NE ""))				{$ADCommandString = $ADCommandString + " " + "-Company '$($SelectedRow.Cells["Company"].Value)'"}
				If ($cbxHomePage.Checked -And ($($SelectedRow.Cells["HomePage"].Value) -NE ""))				{$ADCommandString = $ADCommandString + " " + "-Homepage '$($SelectedRow.Cells["Homepage"].Value)'"}
				If ($cbxOfficePhone.Checked -And ($($SelectedRow.Cells["OfficePhone"].Value) -NE ""))		{$ADCommandString = $ADCommandString + " " + "-OfficePhone '$($SelectedRow.Cells["OfficePhone"].Value)'"}
				If ($cbxHomePhone.Checked -And ($($SelectedRow.Cells["HomePhone"].Value) -NE ""))			{$ADCommandString = $ADCommandString + " " + "-HomePhone '$($SelectedRow.Cells["HomePhone"].Value)'"}	
				If ($cbxMobilePhone.Checked -And ($($SelectedRow.Cells["MobilePhone"].Value) -NE ""))		{$ADCommandString = $ADCommandString + " " + "-MobilePhone '$($SelectedRow.Cells["MobilePhone"].Value)'"}
				If ($cbxFax.Checked -And ($($SelectedRow.Cells["Fax"].Value) -NE ""))						{$ADCommandString = $ADCommandString + " " + "-Fax '$($SelectedRow.Cells["Fax"].Value)'" }
				Try
					{
					Invoke-Expression $ADCommandString -ErrorAction 'Stop'
					}
				Catch
					{	
					$txtLog.Text = $txtLog.Text + "$($Error[0])`r`n"
					}
				}
		[System.Windows.Forms.MessageBox]::Show("Finished" , "Info" , 0)
		$frmCommitAD.Close()
	}

	$Form_StateCorrection_Load=
		{
		$frmCommitAD.WindowState = $InitialFormWindowState
		}
	
	$Form_StoreValues_Closing=
		{
		$script:ChildForm2_checkboxMobilePhone = $checkboxMobilePhone.Checked
		$script:ChildForm2_cbxDescription = $cbxDescription.Checked
		$script:ChildForm2_cbxLastLogon = $cbxLastLogon.Checked
		$script:ChildForm2_cbxFax = $cbxFax.Checked
		$script:ChildForm2_cbxMobilePhone = $cbxMobilePhone.Checked
		$script:ChildForm2_cbxOfficePhone = $cbxOfficePhone.Checked
		$script:ChildForm2_cbxUserName = $cbxUserName.Checked
		$script:ChildForm2_cbxSID = $cbxSID.Checked
		$script:ChildForm2_cbxCanonicalName = $cbxCanonicalName.Checked
		$script:ChildForm2_cbxHomePage = $cbxHomePage.Checked
		$script:ChildForm2_cbxCompany = $cbxCompany.Checked
		$script:ChildForm2_cbxCountry = $cbxCountry.Checked
		$script:ChildForm2_cbxCity = $cbxCity.Checked
		$script:ChildForm2_cbxPostalCode = $cbxPostalCode.Checked
		$script:ChildForm2_cbxStreetAddress = $cbxStreetAddress.Checked
		$script:ChildForm2_cbxTitle = $cbxTitle.Checked
		$script:ChildForm2_cbxMail = $cbxMail.Checked
		$script:ChildForm2_cbxDisplayName = $cbxDisplayName.Checked
		$script:ChildForm2_cbxSurName = $cbxSurName.Checked
		$script:ChildForm2_cbxGivenName = $cbxGivenName.Checked
		}

	
	$Form_Cleanup_FormClosed=
		{
		Try
			{
			$btnADCancel.remove_Click($btnADCancel_Click)
			$btnADOK.remove_Click($btnADOK_Click)
			$frmCommitAD.remove_Load($Form_StateCorrection_Load)
			$frmCommitAD.remove_Closing($Form_StoreValues_Closing)
			$frmCommitAD.remove_FormClosed($Form_Cleanup_FormClosed)
			}
		Catch [Exception]{ }
	}

	$frmCommitAD.Controls.Add($checkboxMobilePhone)
	$frmCommitAD.Controls.Add($cbxDescription)
	$frmCommitAD.Controls.Add($cbxLastLogon)
	$frmCommitAD.Controls.Add($btnADCancel)
	$frmCommitAD.Controls.Add($btnADOK)
	$frmCommitAD.Controls.Add($cbxFax)
	$frmCommitAD.Controls.Add($cbxMobilePhone)
	$frmCommitAD.Controls.Add($cbxOfficePhone)
	$frmCommitAD.Controls.Add($lblCommitToAD)
	$frmCommitAD.Controls.Add($cbxUserName)
	$frmCommitAD.Controls.Add($cbxSID)
	$frmCommitAD.Controls.Add($cbxCanonicalName)
	$frmCommitAD.Controls.Add($cbxHomePage)
	$frmCommitAD.Controls.Add($cbxCompany)
	$frmCommitAD.Controls.Add($cbxCountry)
	$frmCommitAD.Controls.Add($cbxCity)
	$frmCommitAD.Controls.Add($cbxPostalCode)
	$frmCommitAD.Controls.Add($cbxStreetAddress)
	$frmCommitAD.Controls.Add($cbxTitle)
	$frmCommitAD.Controls.Add($cbxMail)
	$frmCommitAD.Controls.Add($cbxDisplayName)
	$frmCommitAD.Controls.Add($cbxSurName)
	$frmCommitAD.Controls.Add($cbxGivenName)
	$frmCommitAD.ClientSize = '535, 289'
	$frmCommitAD.Name = "frmCommitAD"
	$frmCommitAD.ShowIcon = $False
	$frmCommitAD.StartPosition = 'CenterParent'
	$frmCommitAD.Tag = "-OfficePhone $($dgvResults.CurrentRow.Cells['OfficePhone'].Value)"
	$frmCommitAD.Text = "Commit to AD"

	$checkboxMobilePhone.Checked = $True
	$checkboxMobilePhone.CheckState = 'Checked'
	$checkboxMobilePhone.Location = '153, 176'
	$checkboxMobilePhone.Name = "checkboxMobilePhone"
	$checkboxMobilePhone.Size = '104, 24'
	$checkboxMobilePhone.TabIndex = 22
	$checkboxMobilePhone.Text = "Mobile Phone"
	$checkboxMobilePhone.UseVisualStyleBackColor = $True

	$cbxDescription.Checked = $True
	$cbxDescription.CheckState = 'Checked'
	$cbxDescription.Location = '12, 116'
	$cbxDescription.Name = "cbxDescription"
	$cbxDescription.Size = '104, 24'
	$cbxDescription.TabIndex = 21
	$cbxDescription.Text = "Description"
	$cbxDescription.UseVisualStyleBackColor = $True

	$cbxLastLogon.Enabled = $False
	$cbxLastLogon.Location = '421, 56'
	$cbxLastLogon.Name = "cbxLastLogon"
	$cbxLastLogon.Size = '104, 24'
	$cbxLastLogon.TabIndex = 20
	$cbxLastLogon.Text = "LastLogon"
	$cbxLastLogon.UseVisualStyleBackColor = $True

	$btnADCancel.FlatStyle = 'Flat'
	$btnADCancel.Location = '285, 247'
	$btnADCancel.Name = "btnADCancel"
	$btnADCancel.Size = '75, 23'
	$btnADCancel.TabIndex = 19
	$btnADCancel.Text = "Cancel"
	$btnADCancel.UseVisualStyleBackColor = $True
	$btnADCancel.add_Click($btnADCancel_Click)

	$btnADOK.FlatStyle = 'Flat'
	$btnADOK.Location = '153, 247'
	$btnADOK.Name = "btnADOK"
	$btnADOK.Size = '75, 23'
	$btnADOK.TabIndex = 18
	$btnADOK.Text = "OK"
	$btnADOK.UseVisualStyleBackColor = $True
	$btnADOK.add_Click($btnADOK_Click)

	$cbxFax.Checked = $True
	$cbxFax.CheckState = 'Checked'
	$cbxFax.Location = '421, 176'
	$cbxFax.Name = "cbxFax"
	$cbxFax.Size = '104, 24'
	$cbxFax.TabIndex = 17
	$cbxFax.Text = "Fax"
	$cbxFax.UseVisualStyleBackColor = $True

	$cbxMobilePhone.Checked = $True
	$cbxMobilePhone.CheckState = 'Checked'
	$cbxMobilePhone.Location = '285, 176'
	$cbxMobilePhone.Name = "cbxMobilePhone"
	$cbxMobilePhone.Size = '104, 24'
	$cbxMobilePhone.TabIndex = 16
	$cbxMobilePhone.Text = "Mobile Phone"
	$cbxMobilePhone.UseVisualStyleBackColor = $True

	$cbxOfficePhone.Checked = $True
	$cbxOfficePhone.CheckState = 'Checked'
	$cbxOfficePhone.Location = '12, 176'
	$cbxOfficePhone.Name = "cbxOfficePhone"
	$cbxOfficePhone.Size = '104, 24'
	$cbxOfficePhone.TabIndex = 15
	$cbxOfficePhone.Text = "Office Phone"
	$cbxOfficePhone.UseVisualStyleBackColor = $True

	$lblCommitToAD.Location = '12, 13'
	$lblCommitToAD.Name = "lblCommitToAD"
	$lblCommitToAD.Size = '260, 23'
	$lblCommitToAD.TabIndex = 14
	$lblCommitToAD.Text = "Select the properties to be committed to AD"

	$cbxUserName.Enabled = $False
	$cbxUserName.Location = '285, 56'
	$cbxUserName.Name = "cbxUserName"
	$cbxUserName.Size = '104, 24'
	$cbxUserName.TabIndex = 13
	$cbxUserName.Text = "UserName"
	$cbxUserName.UseVisualStyleBackColor = $True

	$cbxSID.Enabled = $False
	$cbxSID.Location = '153, 56'
	$cbxSID.Name = "cbxSID"
	$cbxSID.Size = '104, 24'
	$cbxSID.TabIndex = 12
	$cbxSID.Text = "SID"
	$cbxSID.UseVisualStyleBackColor = $True

	$cbxCanonicalName.Enabled = $False
	$cbxCanonicalName.Location = '12, 56'
	$cbxCanonicalName.Name = "cbxCanonicalName"
	$cbxCanonicalName.Size = '130, 24'
	$cbxCanonicalName.TabIndex = 11
	$cbxCanonicalName.Text = "Canonical Name"
	$cbxCanonicalName.UseVisualStyleBackColor = $True

	$cbxHomePage.Checked = $True
	$cbxHomePage.CheckState = 'Checked'
	$cbxHomePage.Location = '421, 116'
	$cbxHomePage.Name = "cbxHomePage"
	$cbxHomePage.Size = '104, 24'
	$cbxHomePage.TabIndex = 10
	$cbxHomePage.Text = "Homepage"
	$cbxHomePage.UseVisualStyleBackColor = $True

	$cbxCompany.Checked = $True
	$cbxCompany.CheckState = 'Checked'
	$cbxCompany.Location = '285, 116'
	$cbxCompany.Name = "cbxCompany"
	$cbxCompany.Size = '104, 24'
	$cbxCompany.TabIndex = 9
	$cbxCompany.Text = "Company"
	$cbxCompany.UseVisualStyleBackColor = $True

	$cbxCountry.Checked = $True
	$cbxCountry.CheckState = 'Checked'
	$cbxCountry.Location = '421, 146'
	$cbxCountry.Name = "cbxCountry"
	$cbxCountry.Size = '104, 24'
	$cbxCountry.TabIndex = 8
	$cbxCountry.Text = "Country"
	$cbxCountry.UseVisualStyleBackColor = $True

	$cbxCity.Checked = $True
	$cbxCity.CheckState = 'Checked'
	$cbxCity.Location = '285, 146'
	$cbxCity.Name = "cbxCity"
	$cbxCity.Size = '104, 24'
	$cbxCity.TabIndex = 7
	$cbxCity.Text = "City"
	$cbxCity.UseVisualStyleBackColor = $True

	$cbxPostalCode.Checked = $True
	$cbxPostalCode.CheckState = 'Checked'
	$cbxPostalCode.Location = '153, 146'
	$cbxPostalCode.Name = "cbxPostalCode"
	$cbxPostalCode.Size = '104, 24'
	$cbxPostalCode.TabIndex = 6
	$cbxPostalCode.Text = "Postal Code"
	$cbxPostalCode.UseVisualStyleBackColor = $True

	$cbxStreetAddress.Checked = $True
	$cbxStreetAddress.CheckState = 'Checked'
	$cbxStreetAddress.Location = '12, 146'
	$cbxStreetAddress.Name = "cbxStreetAddress"
	$cbxStreetAddress.Size = '104, 24'
	$cbxStreetAddress.TabIndex = 5
	$cbxStreetAddress.Text = "Street Address"
	$cbxStreetAddress.UseVisualStyleBackColor = $True

	$cbxTitle.Checked = $True
	$cbxTitle.CheckState = 'Checked'
	$cbxTitle.Location = '153, 116'
	$cbxTitle.Name = "cbxTitle"
	$cbxTitle.Size = '104, 24'
	$cbxTitle.TabIndex = 4
	$cbxTitle.Text = "Title"
	$cbxTitle.UseVisualStyleBackColor = $True

	$cbxMail.Checked = $True
	$cbxMail.CheckState = 'Checked'
	$cbxMail.Location = '421, 86'
	$cbxMail.Name = "cbxMail"
	$cbxMail.Size = '104, 24'
	$cbxMail.TabIndex = 3
	$cbxMail.Text = "Mail"
	$cbxMail.UseVisualStyleBackColor = $True

	$cbxDisplayName.Checked = $True
	$cbxDisplayName.CheckState = 'Checked'
	$cbxDisplayName.Location = '285, 86'
	$cbxDisplayName.Name = "cbxDisplayName"
	$cbxDisplayName.Size = '104, 24'
	$cbxDisplayName.TabIndex = 2
	$cbxDisplayName.Text = "Display Name"
	$cbxDisplayName.UseVisualStyleBackColor = $True

	$cbxSurName.Checked = $True
	$cbxSurName.CheckState = 'Checked'
	$cbxSurName.Location = '153, 86'
	$cbxSurName.Name = "cbxSurName"
	$cbxSurName.Size = '104, 24'
	$cbxSurName.TabIndex = 1
	$cbxSurName.Text = "Surname"
	$cbxSurName.UseVisualStyleBackColor = $True

	$cbxGivenName.Checked = $True
	$cbxGivenName.CheckState = 'Checked'
	$cbxGivenName.Location = '12, 86'
	$cbxGivenName.Name = "cbxGivenName"
	$cbxGivenName.Size = '104, 24'
	$cbxGivenName.TabIndex = 0
	$cbxGivenName.Text = "Given Name"
	$cbxGivenName.UseVisualStyleBackColor = $True

	$InitialFormWindowState = $frmCommitAD.WindowState
	$frmCommitAD.add_Load($Form_StateCorrection_Load)
	$frmCommitAD.add_FormClosed($Form_Cleanup_FormClosed)
	$frmCommitAD.add_Closing($Form_StoreValues_Closing)
	Return $frmCommitAD.ShowDialog()
	}

Main ($CommandLine)
#EOF
