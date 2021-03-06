<# Begin ---- Global Variables - Script Limited Scope ---- #>
#Script Author Information
$script:ProgramName = "Admin Launcher"
$script:ProgramDate = "4 Oct 2011"
$script:ProgramAuthor = "Geoffrey Guynn"
$script:ProgramAuthorEmail = [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String("Z2VvZmZyZXlAZ3V5bm4ub3Jn"))

#Configuration Variables
$script:xmlConfig = New-Object System.Data.DataSet("AdminLauncher")
$script:xmlConfigFile = "$Env:AppData\AdminLauncher\config.xml"

#Script Information
$script:WorkingFileName = $MyInvocation.MyCommand.Definition
$script:WorkingDirectory = Split-Path $script:WorkingFileName -Parent
$script:ScriptVersion = "2.0.1.0"

#Password Container (to keep plaintext passwords out of memory)
$script:SecurePassword = New-Object System.Security.SecureString
<# End ---- Global Variables - Script Limited Scope ---- #>

<# Begin ---- Debugging Options ---- #>
#DebugPreference - SilentlyContinue is the default.
$script:DebugPreference = "SilentlyContinue"
#ErrorActionPreference - Continue is the default.
$Script:ErrorActionPreference = "Continue"
<# End ---- Debugging Options ---- #>

<# Begin ---- Startup Checks ---- #>
Function IsAdmin{ #Is the current user an administrator
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($id)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}
Function RestartScript{ #Restart the script.
    param(
		[string]$Verb = "open"
	)
    $ProcessStartInfo = New-Object System.Diagnostics.ProcessStartInfo
    $ProcessStartInfo.UseShellExecute = $True
    $ProcessStartInfo.WorkingDirectory = $script:WorkingDirectory
    $ProcessStartInfo.FileName =  "powershell.exe"
    $ProcessStartInfo.Arguments = "-version `"2.0`" -sta -NonInteractive -noLogo -WindowStyle `"Hidden`" -ExecutionPolicy `"Unrestricted`" -file `"$script:WorkingFileName`""
    $ProcessStartInfo.Verb = $verb
    $ProcessStartInfo.WindowStyle = "Hidden"
    
    #Debug Options - Disable under normal execution.
    if($script:DebugPreference -ne "SilentlyContinue"){
		$ProcessStartInfo.Arguments = "-version `"2.0`" -sta -ExecutionPolicy `"Unrestricted`" -file `"$script:WorkingFileName`""
		$ProcessStartInfo.WindowStyle = "Normal"
	}	
	
	try{
        $Process = [System.Diagnostics.Process]::Start($ProcessStartInfo)
    }
    catch [System.ComponentModel.Win32Exception]{
    }
}
Function LoadCheck{
    $verb = $Null
    #The GUI requires a single thread apartmentstate configuration.
    if($host.Runspace.ApartmentState -ne [System.Threading.ApartmentState]::STA){
        $Verb = "open"
    }
	#The script could break under powershell version 3.
	if ($host.version.major -ne 2){ #Restart powershell with version 2.0
		$Verb = "open"
	}
    #Check to see if the launcher is running under an elevated token. This is a UAC check.
    if (-not(IsAdmin)){
        $Verb = "runas"
    }
    #If one of the conditions above was true, re-launch the application to fix the problem.
    if ($Verb -ne $Null){
        RestartScript $Verb
        #Terminate the old script, so it doesn't load another launcher.
        break
    }
}
#Run the loadcheck function.
#LoadCheck
<# End ---- Startup Checks ---- #>

<# Begin ---- Import Global Objects ---- #>
#The old "LoadWithPartialName" can break in the future, Add-Type is the recommended best practice.
#[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
#[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
Add-Type -AssemblyName "System.Windows.Forms"
Add-Type -AssemblyName "System.Drawing"
<# End ---- Import Global Objects ---- #>

<# Begin ---- Windows Forms Object Declarations - Main Form ---- #>
$form_MainLauncher = New-Object System.Windows.Forms.Form
$tlp_Main = New-Object System.Windows.Forms.TableLayoutPanel
$cb_Main_Domain = New-Object System.Windows.Forms.ComboBox
#$ep_Main = New-Object System.Windows.Forms.ErrorProvider
$gb_Main_Programs = New-Object System.Windows.Forms.GroupBox
$gb_Main_RunAs = New-Object System.Windows.Forms.GroupBox
$lbl_Main_Domain = New-Object System.Windows.Forms.Label
$lbl_Main_Password = New-Object System.Windows.Forms.Label
$lbl_Main_UserName = New-Object System.Windows.Forms.Label
$ms_Main_MenuStrip = New-Object System.Windows.Forms.MenuStrip
$mtb_Main_Password = New-Object System.Windows.Forms.MaskedTextBox
$ss_Main_StatusStrip = New-Object System.Windows.Forms.StatusStrip
$tb_Main_UserName = New-Object System.Windows.Forms.TextBox
$tsmi_Main_Configure = New-Object System.Windows.Forms.ToolStripMenuItem
$tsmi_Main_Exit = New-Object System.Windows.Forms.ToolStripMenuItem
$tsmi_Main_Export = New-Object System.Windows.Forms.ToolStripMenuItem
$tsmi_Main_File = New-Object System.Windows.Forms.ToolStripMenuItem
$tsmi_Main_Import = New-Object System.Windows.Forms.ToolStripMenuItem
$tsmi_Main_Reset = New-Object System.Windows.Forms.ToolStripMenuItem
$tssl_Main_StatusStripLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$tt_Main_Tooltip = New-Object System.Windows.Forms.Tooltip
<# End ---- Windows Forms Object Declarations - Main Form ---- #>

<# Begin ---- Windows Forms Object Declarations - Config Form ---- #>
$form_Config = New-Object System.Windows.Forms.Form
$tlp_Config = New-Object System.Windows.Forms.TableLayoutPanel
$btn_Config_Done = New-Object System.Windows.Forms.Button
$gb_Config_Programs = New-Object System.Windows.Forms.GroupBox

#Programs Datagridview
$dgv_Config_Programs = New-Object System.Windows.Forms.DataGridView
$dgc_Config_Arguments = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$dgc_Config_Command = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
$dgc_Config_Name = New-Object System.Windows.Forms.DataGridViewTextBoxColumn
<# End ---- Windows Forms Object Declarations - Config Form ---- #>

<# Begin ---- Windows Forms Object Declarations - Dialogs ---- #>
$dlg_OpenFile = New-Object System.Windows.Forms.OpenFileDialog
$dlg_SaveFile = New-Object System.Windows.Forms.SaveFileDialog
<# End ---- Windows Forms Object Declarations - Dialogs ---- #>

<# Begin ---- Windows Form Objects - Suspend Layouts ---- #>
$form_MainLauncher.SuspendLayout()
$form_Config.SuspendLayout()
$tlp_Main.SuspendLayout()
$tlp_Config.SuspendLayout()
$gb_Main_Programs.SuspendLayout()
$gb_Main_RunAs.SuspendLayout()
$gb_Config_Programs.SuspendLayout()
$ss_Main_StatusStrip.SuspendLayout()
$ms_Main_MenuStrip.SuspendLayout()
<# End ---- Windows Form Objects - Suspend Layouts ---- #>

<# Begin ---- Object Definitions - Main Form ---- #>
$form_MainLauncher | % {
    $_.AutoScaleDimensions = New-Object System.Drawing.SizeF(6, 13)
    $_.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font
    $_.Autosize = $True
    $_.BackColor = [System.Drawing.SystemColors]::Control
    $_.Controls.Add($tlp_Main)
    $_.Controls.Add($ss_Main_StatusStrip)
    $_.Controls.Add($ms_Main_MenuStrip)
    $_.MainMenuStrip = $ms_Main_MenuStrip
    $_.MaximumSize = New-Object System.Drawing.Size(275, [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height)
    $_.MinimumSize = New-Object System.Drawing.Size(275, 194)
    $_.Name = "form_MainLauncher"
    $_.Size = New-Object System.Drawing.Size(275, 194)
    $_.Text = "Admin Launcher"
    $_.TopMost = $True
}
$tlp_Main | % {
	$_.Autosize = $True
	$_.AutosizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
	$_.BackColor = [System.Drawing.SystemColors]::GradientInactiveCaption
	$_.ColumnCount = 1
	$_.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
	$_.Controls.Add($gb_Main_Programs, 0, 1)
	$_.Controls.Add($gb_Main_RunAs, 0, 0)
	$_.Dock = [System.Windows.Forms.DockStyle]::Fill
	$_.Location = New-Object System.Drawing.Point(0, 24)
	$_.Name = "tlp_Main"
	$_.RowCount = 2;
	$_.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 109))) | Out-Null
	$_.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
	$_.Size = New-Object System.Drawing.Size(259, 295)
	$_.TabIndex = 9
}
$cb_Main_Domain | % {
	$tt_Main_Tooltip.SetToolTip($_, "Select a domain from the list.") | Out-Null
	$_.Anchor =([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right)
	$_.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
	$_.FormattingEnabled = $True
	$_.Location = New-Object System.Drawing.Point(58, 71)
	$_.Name = "cb_Main_Domain"
	$_.Size = New-Object System.Drawing.Size(189, 21)
	$_.TabIndex = 4
}
$gb_Main_Programs | % {
	$_.Autosize = $True
	$_.AutosizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
	$_.Dock = [System.Windows.Forms.DockStyle]::Fill
	$_.Location = New-Object System.Drawing.Point(3, 112)
	$_.Name = "gb_Main_Programs"
	$_.Size = New-Object System.Drawing.Size(253, 180)
	$_.TabIndex = 9
	$_.TabStop = $False
	$_.Text = "Programs"
}
$gb_Main_RunAs | % {
	$_.Controls.Add($lbl_Main_Domain)
	$_.Controls.Add($cb_Main_Domain)
	$_.Controls.Add($mtb_Main_Password)
	$_.Controls.Add($tb_Main_UserName)
	$_.Controls.Add($lbl_Main_Password)
	$_.Controls.Add($lbl_Main_UserName)
	$_.Dock = [System.Windows.Forms.DockStyle]::Fill
	$_.Location = New-Object System.Drawing.Point(3, 3)
	$_.Name = "gb_Main_RunAs"
	$_.Size = New-Object System.Drawing.Size(253, 103)
	$_.TabIndex = 10
	$_.TabStop = $False
	$_.Text = "Run-As Credentials"
}
$lbl_Main_Domain | % {
	$_.Location = New-Object System.Drawing.Point(6, 74)
	$_.Name = "lbl_Main_Domain"
	$_.Size = New-Object System.Drawing.Size(46, 13)
	$_.TabIndex = 5
	$_.Text = "Domain"
}
$lbl_Main_Password | % {
	$_.Location = New-Object System.Drawing.Point(6, 48)
	$_.Name = "lbl_Main_Password"
	$_.Size = New-Object System.Drawing.Size(56, 13)
	$_.TabIndex = 1
	$_.Text = "Password:"
}
$lbl_Main_UserName | % {
	$_.Location = New-Object System.Drawing.Point(6, 22)
	$_.Name = "lbl_Main_UserName"
	$_.Size = New-Object System.Drawing.Size(60, 13)
	$_.TabIndex = 0
	$_.Text = "UserName:"
}
$ms_Main_MenuStrip | % {
	$_.BackColor = [System.Drawing.SystemColors]::Control
	$_.Items.Add($tsmi_Main_File) | Out-Null
	$_.Location = New-Object System.Drawing.Point(0, 0)
	$_.Name = "ms_Main_MenuStrip"
	$_.RenderMode = [System.Windows.Forms.ToolStripRenderMode]::System
	$_.Size = New-Object System.Drawing.Size(259, 24)
	$_.TabIndex = 3
	$_.Text = $Null
}
$mtb_Main_Password | % {
	$tt_Main_Tooltip.SetToolTip($_, "Enter a password.") | Out-Null
	$_.Anchor =([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right)
	$_.Location = New-Object System.Drawing.Point(68, 45)
	$_.Name = "mtb_Main_Password"
	$_.PasswordChar = '*'
	$_.Size = New-Object System.Drawing.Size(179, 20)
	$_.TabIndex = 3
}
$ss_Main_StatusStrip | % {
	$_.BackColor = [System.Drawing.SystemColors]::Control
	$_.Items.Add($tssl_Main_StatusStripLabel) | Out-Null
	$_.Location = New-Object System.Drawing.Point(0, 319)
	$_.Name = "ss_Main_StatusStrip"
	$_.Size = New-Object System.Drawing.Size(259, 22)
	$_.TabIndex = 2
	$_.Text = $Null
}
$tb_Main_UserName | % {
	$tt_Main_Tooltip.SetToolTip($_, "Enter a username.") | Out-Null
	$_.Anchor =([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right)
	$_.Location = New-Object System.Drawing.Point(72, 19)
	$_.Name = "tb_Main_UserName"
	$_.Size = New-Object System.Drawing.Size(175, 20)
	$_.TabIndex = 2

}
$tsmi_Main_Configure | % {
	$_.Name = "tsmi_Main_Configure"
	$_.Size = New-Object System.Drawing.Size(155, 22)
	$_.Text = "Configure"
}
$tsmi_Main_Exit | % {
	$_.Name = "tsmi_Main_Exit"
	$_.Size = New-Object System.Drawing.Size(155, 22)
	$_.Text = "Exit"
}
$tsmi_Main_Export | % {
	$_.Name = "tsmi_Main_Export"
	$_.Size = New-Object System.Drawing.Size(155, 22)
	$_.Text = "Export Settings"
}
$tsmi_Main_File | % {
	$_.DropDownItems.AddRange([System.Windows.Forms.ToolStripItem[]](
		$tsmi_Main_Configure,
		$tsmi_Main_Import,
		$tsmi_Main_Export,
		$tsmi_Main_Reset,
		$tsmi_Main_Exit
	))
	$_.Name = "fileToolStripMenuItem"
	$_.Size = New-Object System.Drawing.Size(37, 20)
	$_.Text = "File"
}
$tsmi_Main_Import | % {
	$_.Name = "tsmi_Main_Import"
	$_.Size = New-Object System.Drawing.Size(155, 22)
	$_.Text = "Import Settings"
}
$tsmi_Main_Reset | % {
	$_.Name = "tsmi_Main_Reset"
	$_.Size = New-Object System.Drawing.Size(155, 22)
	$_.Text = "Reset Default Settings"
}
$tssl_Main_StatusStripLabel | % {
	$_.BackColor = [System.Drawing.SystemColors]::Control
	$_.Name = "tssl_Main_StatusStripLabel"
	$_.Size = New-Object System.Drawing.Size(118, 17)
	$_.Text = $Null
}
<# End ---- Object Definitions - Main Form ---- #>

<# Begin ---- Object Definitions - Config Form ---- #>
$form_Config | % {
	$_.AutoScaleDimensions = New-Object System.Drawing.SizeF(6, 13)
	$_.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Font
	$_.ClientSize = New-Object System.Drawing.Size(472, 375)
	$_.Controls.Add($tlp_Config)
	$_.MinimumSize = New-Object System.Drawing.Size(825, 450)
	$_.Name = "form_Config"
	$_.Text = "Config - The script will save new rows and update the launcher if the entry has a name and command."
	$_.TopMost = $True
}
$tlp_Config | % {
	$_.BackColor = [System.Drawing.SystemColors]::GradientInactiveCaption
	$_.ColumnCount = 4
	$_.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
	$_.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 75))) | Out-Null
	$_.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 75))) | Out-Null
	$_.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Absolute, 75))) | Out-Null
	$_.Controls.Add($gb_Config_Programs, 0, 0)
	$_.Controls.Add($btn_Config_Done, 3, 1)
	$_.Dock = [System.Windows.Forms.DockStyle]::Fill
	$_.Location = New-Object System.Drawing.Point(0, 0)
	$_.Name = "tlp_Config"
	$_.RowCount = 2
	$_.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100))) | Out-Null
	$_.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 27))) | Out-Null
	$_.Size = New-Object System.Drawing.Size(472, 375)
	$_.TabIndex = 0
}
$btn_Config_Done | % {
	$_.Anchor = [System.Windows.Forms.AnchorStyles]::Left
	$_.BackColor = [System.Drawing.SystemColors]::Control
	$_.Location = New-Object System.Drawing.Point(400, 351)
	$_.Name = "btn_Config_Done"
	$_.Size = New-Object System.Drawing.Size(69, 21)
	$_.TabIndex = 1
	$_.Text = "Done"
	$_.UseVisualStyleBackColor = $True
}
$gb_Config_Programs | % {
	$tlp_Config.SetColumnSpan($_, 4)
	$_.Controls.Add($dgv_Config_Programs)
	$_.Dock = [System.Windows.Forms.DockStyle]::Fill
	$_.Location = New-Object System.Drawing.Point(3, 3)
	$_.Name = "gb_Config_Programs"
	$_.Size = New-Object System.Drawing.Size(1, 1)
	$_.TabIndex = 0
	$_.TabStop = $False
	$_.Text = "Programs"
}

#Programs Datagridview
$dgv_Config_Programs | % {
	$_.AutoSizeColumnsMode = [System.Windows.Forms.DataGridViewAutoSizeColumnsMode]::Fill
	$_.BackgroundColor = [System.Drawing.SystemColors]::GradientInactiveCaption
	$_.ColumnHeadersHeightSizeMode = [System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode]::AutoSize
	$_.Columns.AddRange([System.Windows.Forms.DataGridViewColumn[]]($dgc_Config_Name,$dgc_Config_Command, $dgc_Config_Arguments)) | Out-Null
	$_.Dock = [System.Windows.Forms.DockStyle]::Fill
	$_.Location = New-Object System.Drawing.Point(3, 16)
	$_.Name = "dgv_Config_Programs"
	$_.RowHeadersVisible = $False
	$_.SelectionMode = [System.Windows.Forms.DataGridViewSelectionMode]::FullRowSelect
	$_.Size = New-Object System.Drawing.Size(850, 400)
	$_.TabIndex = 0
}
$dgc_Config_Arguments | % {
	$_.AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill
	$_.DataPropertyName = "Arguments"
	$_.FillWeight = 35
	$_.HeaderText = "Arguments"
	$_.Name = "dgc_Config_Arguments"
}
$dgc_Config_Command | % {
	$_.AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill
	$_.DataPropertyName = "Command"
	$_.FillWeight = 60
	$_.HeaderText = "Command"
	$_.Name = "dgc_Config_Command"
}
$dgc_Config_Name | % {
	$_.AutoSizeMode = [System.Windows.Forms.DataGridViewAutoSizeColumnMode]::Fill
	$_.DataPropertyName = "Name"
	$_.FillWeight = 20
	$_.HeaderText = "Name"
	$_.Name = "dgc_Config_Name"
}
<# End ---- Object Definitions - Config Form ---- #>

<# Begin ---- Object Definitions - Dialogs ---- #>
$dlg_OpenFile | % {
	$_.InitialDirectory = "$env:USERPROFILE\Documents"
	$_.Filter = "Xml Document(*.xml)|*.xml"
}
$dlg_SaveFile | % {
	$_.InitialDirectory = "$env:USERPROFILE\Documents"
	$_.Filter = "Xml Document(*.xml)|*.xml"
	$_.FileName = "AdminLauncher_Settings.xml"
}
<# End ---- Object Definitions - Dialogs ---- #>

<# Begin ---- Admin Launcher Helper Functions ---- #>
Function Add-Program{
    param(
        [System.Data.DataSet]$DataSet
        , #The name of the program
        [String]$Name
        , #The command for the program
        [string]$Command = $Null
        , #Any arguments required by the program
        [string]$Arguments = $Null
    )
    $htProgram = @{
        DataSet = $DataSet
        TableName = "Programs"
        RowData = @{
            Name = $Name
            Command = $Command
            Arguments = $Arguments
        }
    }
    
    Add-Row @htProgram
}
Function Add-ProgramButtons{
	#Suspend layouts so the screen doesn't flicker as each element is removed and then added.
    $form_MainLauncher.SuspendLayout()
    $gb_Main_Programs.SuspendLayout()
	
    while ($gb_Main_Programs.haschildren){ #Remove all old programs. Disposing them avoids a memory leak as the objects are recreated.
        $gb_Main_Programs.controls | % {
            $_.Dispose()
            $gb_Main_Programs.Controls.Remove($_)
        }
    }
    #Sort the list of programs by name, then create a button for each one.
    foreach ($Program in $script:xmlconfig.Tables["Programs"].Select($Null, "Name Asc")){
        if ($gb_Main_Programs.HasChildren){#As we add buttons, we need to find the lowest one and properly offset by 22 from it. We'll sort the buttons by their y coordinate and calculate the lowest on each iteration.
            $yCoordinate = (@($gb_Main_Programs.Controls | Sort-Object @{Expression={$_.location.Y}} -descending)[0].Location.Y) + 22
        }
        else{ #The offset we'd use for our first button.
			$yCoordinate = 16
		}
		
        #Generate tooltip information.
        $tt_Main_TooltipString = "Launch $($Program.Name)"
        if (![DBNull]::Value.Equals($Program.Command) -and $Program.Command){$tt_Main_TooltipString += "`r  Command: $($Program.Command)"}
        if (![DBNull]::Value.Equals($Program.Arguments) -and $Program.Arguments){$tt_Main_TooltipString += "`r  Arguments: $($Program.Arguments)"}
        
		#Create the button at our calculated coordinates.
        $TempButton = New-Object System.Windows.Forms.Button
		$TempButton | % {
			$_.Anchor =([System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Left -bor [System.Windows.Forms.AnchorStyles]::Right)
			$_.Autosize = $True
			$_.AutosizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
			$_.BackColor = [System.Drawing.SystemColors]::Control
			$_.Location = New-Object System.Drawing.Point(6, $yCoordinate)
			$_.Name = ("btn_" + ($Program.Name -Replace " ","_")) #Replace all spaces with underlines. (This avoids errors.)
			$_.Size = New-Object System.Drawing.Size(241, 23)
			$_.TabIndex = 0
			$_.Text = $Program.Name
			$_.UseVisualStyleBackColor = $True
			
			#Event Handler to launch the program properly.
			$_.Add_Click({event_Click_ProgramButton $this $_})
			
			#Connect the tooltip to the button.
			$tt_Main_Tooltip.SetToolTip($_, $tt_Main_TooltipString)
			
			#Add the button to our form.
			$gb_Main_Programs.Controls.Add($_)			
		}
    }
    $gb_Main_Programs.PerformLayout()
    $form_MainLauncher.ResumeLayout($False)
    $form_MainLauncher.PerformLayout()
    if ($form_MainLauncher.WindowState -ne [System.Windows.Forms.FormWindowState]::Maximumized){
        AutoSize-Form $form_MainLauncher
    }
}
Function Add-Row{
    param([System.Data.DataSet]$DataSet, [string]$TableName, [hashtable]$RowData)
    $NewRow = $DataSet.Tables[$TableName].NewRow()
    $RowData.keys | % {$NewRow.$_ = $RowData.$_}
    $DataSet.Tables[$TableName].Rows.Add($NewRow)
}
Function Add-Table{
    param([System.Data.Dataset]$DataSet, [string]$TableName, [array]$Columns)
    $dtTable = New-Object System.Data.DataTable($TableName)
    $dtTable.Columns.AddRange(@($Columns))
    $DataSet.Tables.Add($dtTable)
}
Function Apply-Config{
    Add-ProgramButtons
}
Function Autosize-Form{
    param(
		[System.Windows.Forms.Form]$Form
	)
	
    $Form.AutosizeMode = [System.Windows.Forms.AutoSizeMode]::GrowAndShrink
    $Form.AutosizeMode = [System.Windows.Forms.AutoSizeMode]::GrowOnly
}
Function Create-Config{
    #Create a brand new dataset.
    $script:xmlConfig = New-Object System.Data.DataSet("AdminLauncher")
    #Determine program files location for 32bit/64bit apps.
    switch ([intptr]::Size -eq 8){
        $True{$ProgramFiles = (Get-Item "${env:ProgramFiles(x86)}").FullName}
        $False{$ProgramFiles = (Get-Item "${env:ProgramFiles}").FullName}
    }
    #Define table structures for the config tables.
    $htSettings = @{
        DataSet=$script:xmlConfig
        TableName="Settings"
        Columns=@("Program", "ProgramDate", "Version", "Author", "AuthorEmail", "UserName", "UserDomain")
    }
    $htPrograms = @{
        DataSet=$script:xmlConfig
        TableName="Programs"
        Columns=@("Name", "Command", "Arguments")
    }
    #Add base configuration tables to the dataset.
    Add-Table @htSettings
    Add-Table @htPrograms
    #Capture configuration data.
	if ("$env:USERDNSDOMAIN"){
		$UserDomain = "$env:USERDNSDOMAIN"
	}
	else{
		$UserDomain = "$env:COMPUTERNAME"
	}
	
    $htSettings = @{
        DataSet=$script:xmlConfig
        TableName="Settings"
        RowData = @{
            Program=$script:ProgramName
			ProgramDate=$script:ProgramDate
            Version=$script:ScriptVersion
            Author=$script:ProgramAuthor
			AuthorEmail =$script:ProgramAuthorEmail
            UserName="$env:USERNAME"
            UserDomain=$UserDomain
        }
    }
    #Add configuration data to the dataset.
    Add-Row @htSettings
    #Define each default program and add it to the dataset.
    Add-Program -DataSet $script:xmlConfig -Name "Active Directory" -Command "$env:WINDIR\system32\mmc.exe" -Arguments "$env:WINDIR\system32\dsa.msc"
    Add-Program -DataSet $script:xmlConfig -Name "ADSI Editor" -Command "$env:WINDIR\system32\mmc.exe" -Arguments "$env:WINDIR\system32\adsiedit.msc"
    Add-Program -DataSet $script:xmlConfig -Name "Computer Management" -Command "$env:WINDIR\system32\mmc.exe" -Arguments "$env:WINDIR\system32\compmgmt.msc /s"
    Add-Program -DataSet $script:xmlConfig -Name "DHCP Configuration" -Command "$env:WINDIR\system32\mmc.exe" -Arguments "$env:WINDIR\system32\dhcpmgmt.msc"
    Add-Program -DataSet $script:xmlConfig -Name "DNS Configuration" -Command "$env:WINDIR\system32\mmc.exe" -Arguments "$env:WINDIR\system32\dnsmgmt.msc /s"
    Add-Program -DataSet $script:xmlConfig -Name "Group Policy Management" -Command "$env:WINDIR\system32\mmc.exe" -Arguments "$env:WINDIR\system32\gpmc.msc"
    Add-Program -DataSet $script:xmlConfig -Name "Powershell Console" -Command "$pshome\powershell.exe" -Arguments "-STA"
    Add-Program -DataSet $script:xmlConfig -Name "Powershell ISE" -Command "$pshome\powershell_ISE.exe"
    Add-Program -DataSet $script:xmlConfig -Name "Print Management" -Command "$env:WINDIR\system32\mmc.exe" -Arguments "$env:WINDIR\system32\printmanagement.msc"
    Add-Program -DataSet $script:xmlConfig -Name "Remote Desktop" -Command "$env:WINDIR\system32\mstsc.exe"
}
Function Get-DomainInfo{
    #Get the current forest.
    try{ #This can fail if we're not on a domain. Let's make sure to catch exceptions gracefully.
        $Forest = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest()
        $MemberDomains = @()
        $ForestSites = @($Forest.Sites)
        
        if ($ForestSites){
            $ForestSites | % {
                if ($_.Domains){
                    $_.Domains | % {
                        if ($MemberDomains -notcontains $_.Name){
                            $MemberDomains += $_.Name.ToUpper()
                        }
                    }
                }
            }
        }
        else{ #Get other domains from forest trusts.
            $ForestTrusts = @($Forest.GetAllTrustRelationships())
            if ($ForestTrusts){
                $DomainNames = $ForestTrusts |
                    ? {$_.TrustType -eq [System.DirectoryServices.ActiveDirectory.TrustType]::Forest} |
                    % {$_.TrustedDomainInformation |
                    % {$_.dnsName}}
                if ($DomainNames){
                    $DomainNames | % {
                        $MemberDomains += $_.ToUpper()
                    }
                }
            }
        }
    }
    catch{ #We don't need to do anything if this fails. The array will be generated regardless.
    }
    finally{
		if ($MemberDomains){
			#Add the user's current domain to the array if not already present.
			if ($MemberDomains -notcontains $env:USERDNSDOMAIN){
				$MemberDomains += $env:USERDNSDOMAIN
			}
            
			#Add the domain information to the dropdown list.
			$cb_Main_Domain.Items.AddRange(($MemberDomains | Sort-Object -unique))
			
			if ($script:xmlConfig.Tables["Cache"]){ #Use cached information if we have any.
				if (![DBNull]::Value.Equals($script:xmlConfig.Tables["Cache"].Rows[0].Domain) -and $script:xmlConfig.Tables["Cache"].Rows[0].Domain){
					$cb_Main_Domain.Text = $script:xmlConfig.Tables["Cache"].Rows[0].Domain
				}
			}
            elseif ($env:USERDNSDOMAIN){ #Use domain info if available.
                $cb_Main_Domain.Text = $env:USERDNSDOMAIN
            }
            else{ #Use item 1 from the list.
                $cb_Main_Domain.Text = $cb_Main_Domain.Items[0]
            }
		}
        elseif ($env:USERDNSDOMAIN){ #Use domain info if available.
            $cb_Main_Domain.Items.Add($env:USERDNSDOMAIN)
            $cb_Main_Domain.Text = $env:USERDNSDOMAIN
        }
		else{ #There is no domain membership, use local computer name.
			$cb_Main_Domain.Items.Add($env:COMPUTERNAME)
			$cb_Main_Domain.Text = $env:COMPUTERNAME
		}
    }
}
Function Load-Config{
    if (Test-Path $script:xmlConfigFile){ #The config exists, read it.
        $script:xmlConfig.ReadXml($script:xmlConfigFile) | Out-Null
        $script:xmlConfig.AcceptChanges()
    }
    else{ #The config doesn't exist, create it.
        Create-Config
        if (!(Test-Path (Split-Path -Path $script:xmlConfigFile -Parent))){
            mkdir (Split-Path -Path $script:xmlConfigFile -Parent)
        }
        [void]$script:xmlConfig.WriteXml($script:xmlConfigFile)
        $script:xmlConfig.AcceptChanges()
    }
    #Validate the config file according to our schema.
    if (Validate-Config $script:xmlConfig){
        if ($script:xmlConfig.Tables["Cache"]){
            if (![DBNull]::Value.Equals($script:xmlConfig.Tables["Cache"].Rows[0].Name) -and $script:xmlConfig.Tables["Cache"].Rows[0].Name){
                $tb_Main_UserName.Text = $script:xmlConfig.Tables["Cache"].Rows[0].Name
            }
            if (![DBNull]::Value.Equals($script:xmlConfig.Tables["Cache"].Rows[0].Domain) -and $script:xmlConfig.Tables["Cache"].Rows[0].Domain){
                $cb_Main_Domain.Text = $script:xmlConfig.Tables["Cache"].Rows[0].Domain
            }
        }
        Apply-Config
    }
    #Something is wrong with the config file, offer to recreate it or exit if it is not re-created.
    else{
        $htPrompt = @{
            Caption="Invalid Configuration File!"
            Message="An incompatible configuration file exists!`nWould you like to re-build one from the default settings?"
            DialogOptions="YesNo"
        }
        $DialogResult = [System.Windows.Forms.MessageBox]::Show($htPrompt.Message, $htPrompt.Caption, $htPrompt.DialogOptions)
        if ($DialogResult -eq [System.Windows.Forms.DialogResult]::Yes){
            rm -force $script:xmlConfigFile -EA "SilentlyContinue"
            Load-Config
        }
        else{$form_MainLauncher.Close()}
    }
}
Function Validate-Config{
    param([System.Data.DataSet]$DataSet)
    try{
		#Read settings table from the XML dataset.
		$SettingsInfo = $DataSet.Tables["Settings"].Rows[0]
		
        if ($SettingsInfo.Program -eq $script:ProgramName){ #ProgramName matches
			if ($SettingsInfo.Author -eq $script:ProgramAuthor){ #ProgramAuthor matches
				return $True
			}
			else{
				return $False
			}
		}
		else{
			return $False
		}
	}
    catch{ #Any exceptions will read as a failed validation.
		return $False
	}
}
<# End ---- Admin Launcher Helper Functions ---- #>

<# Begin ---- Admin Launcher Event Handler Functions ---- #>
Function event_Load_form_MainLauncher{
    param(
        $object,
        $e
    )
    #Populate data fields.
    $tssl_Main_StatusStripLabel.Text = "Launcher Ready"
    #Load the configuration
    Load-Config
    Get-DomainInfo
}
Function event_Click_tsmi_Main_Import{
    param(
        $object,
        $e
    )
	
    $DialogResult = $dlg_OpenFile.ShowDialog()
    try{
        if ($DialogResult -eq [System.Windows.Forms.DialogResult]::OK){
            $ImportData = New-Object System.Data.DataSet
            [void]$ImportData.ReadXml($dlg_OpenFile.FileName)
            if (Validate-Config $ImportData){
                $htPrompt = @{
                    Caption="Import Settings"
                    Message="You have chosen to import settings, this will erase all existing settings.`r`n`r`nAre you sure you want to do this?"
                    DialogOptions="YesNo"
                }
                $DialogResult = [System.Windows.Forms.MessageBox]::Show($htPrompt.Message, $htPrompt.Caption, $htPrompt.DialogOptions)
                if ($DialogResult -eq [System.Windows.Forms.DialogResult]::Yes){
                    $ImportData.Tables.Remove("Settings")
                    $ImportData.AcceptChanges()
                    $htSettings = @{
                        DataSet=$ImportData
                        TableName="Settings"
                        Columns=@("Program", "Version", "Author", "UserName", "UserDomain")
                    }
                    Add-Table @htSettings
                    $htSettings = @{
                        DataSet=$ImportData
                        TableName="Settings"
                        RowData = @{
                            Program=$script:ProgramName
                            Version=$script:ScriptVersion
                            Author=$script:ProgramAuthor
                            UserName="$env:USERNAME"
                            UserDomain="$env:USERDNSDOMAIN"
                        }
                    }
                    Add-Row @htSettings
                    $script:xmlConfig = $ImportData.Copy()
                    Apply-Config
                    $tssl_Main_StatusStripLabel.Text = "Import successful!"
                }
            }
            else {Throw "Invalid configuration file!"}
        }
    }
    catch{
        $htError = @{
            Caption="Import Settings"
            Message=("Your settings could not be imported! The following error was reported.`r`n`r`n" + $error[0].exception.message)
            DialogOptions="OkCancel"
        }
        [System.Windows.Forms.MessageBox]::Show($htError.Message, $htError.Caption, $htError.DialogOptions)
    }
}
Function event_Click_tsmi_Main_Export{
    param(
        $object,
        $e
    )
	
    if ($dlg_SaveFile.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK){
        try{
            $xmlSave = $script:xmlConfig.Copy()
            if ($xmlSave.Tables["Settings"].Rows[0].Username -ne $Null) {$xmlSave.Tables["Settings"].Rows[0].Username = $Null}
            if ($xmlSave.Tables["Settings"].Rows[0].UserDomain -ne $Null) {$xmlSave.Tables["Settings"].Rows[0].UserDomain = $Null}
            if ($xmlSave.Tables["Cache"] -ne $Null){
                try{
                    $xmlSave.Tables["Cache"].Rows[0].Name = $Null
                    $xmlSave.Tables["Cache"].Rows[0].Domain = $Null
                }
                catch{}
            }
            [void]$xmlSave.WriteXml($dlg_SaveFile.FileName)
        }
        catch{}
    }
}
Function event_Click_tsmi_Main_Reset{
    param(
        $object,
        $e
    )
	
    $htPrompt = @{
        Caption="Reset all settings"
        Message="You have chosen to reset all settings to default. This will remove ALL changes you have made. Are you sure you want to do this?"
        DialogOptions="YesNo"
    }
    $DialogResult = [System.Windows.Forms.MessageBox]::Show($htPrompt.Message, $htPrompt.Caption, $htPrompt.DialogOptions)
    if ($DialogResult -eq [System.Windows.Forms.DialogResult]::Yes){
        if (Test-Path $script:xmlConfigFile){
            Remove-Item  -Path $script:xmlConfigFile -Force
        }
		Load-Config
		Autosize-Form $form_MainLauncher
    }
}
Function event_Activated_form_Config{
    param(
        $object,
        $e
    )
	
    #Sort the table by program name. (So each time config opens, they're alphabetical)
    $script:xmlConfig.Tables["Programs"].DefaultView.Sort = "Name"
    
    #Bind the gridview to the config file's programs table.
    $dgv_Config_Programs.DataSource = $script:XmlConfig.Tables["Programs"]   
}
Function event_Deactivate_form_Config{
    param(
        $object,
        $e
    )

    if ($object.DialogResult -eq [System.Windows.Forms.DialogResult]::OK){ #If the user pressed the done button, commit the changes to our main config.
        
        #Make sure to remove any programs that do not have a name.
        foreach ($Row in $script:xmlConfig.Tables["Programs"].Rows){
            if ([DBNull]::Value.Equals($Row.Name) -or !$Row.Name){
                $Row.Delete()
            }
        }
        if ($script:xmlConfig.HasChanges()){
            $script:xmlConfig.Tables["Programs"].AcceptChanges()
            [void]$script:xmlConfig.WriteXml($script:xmlConfigFile)
            Add-ProgramButtons $script:xmlConfig
        }
    }
    else{
        if ($script:xmlConfig.HasChanges()){
            $script:xmlConfig.Tables["Programs"].RejectChanges()
        }
    }
}
Function event_Click_ProgramButton{
    param(
		$object,
		$e
	)
    
    #Reference the xml program that this button represents.
    $CurrentProgram = $script:xmlconfig.Tables["Programs"] | ? {$object.Text -eq $_.Name}
    
    $tssl_Main_StatusStripLabel.Text = "$($CurrentProgram.Name) starting..."

    #Build the command string based on what parameters we have.
    if (![DBNull]::Value.Equals($CurrentProgram.Command) `
        -and $CurrentProgram.Command
    ){
        $sb_StartElevatedProcess = {
            param(
                $CurrentProgram
            )

            $ProcInfo = New-Object System.Diagnostics.ProcessStartInfo($CurrentProgram.Command)

            if ($CurrentProgram.Arguments){
                $ProcInfo.Arguments = $CurrentProgram.Arguments
            }

            $ProcInfo.UseShellExecute = $True
            $ProcInfo.Verb = "RunAs"
            try{
                $Proc = [Diagnostics.Process]::Start($ProcInfo)
            }
            catch{
                throw $_
            }
        }
        try{
            $job_params = @{
                ScriptBlock = $sb_StartElevatedProcess
                ArgumentList = $CurrentProgram
            }
            
            if ($cb_Main_Domain.Text -and $tb_Main_UserName.Text -and $mtb_Main_Password.Text){
                $Credential = New-Object System.Management.Automation.PSCredential("$($cb_Main_Domain.Text)\$($tb_Main_UserName.Text)",$SecurePassword)
                $job_params.Credential = $Credential
            }            

            $Job = Start-Job @job_params
            Wait-Job $Job
            if ($Job.State -ne "Completed"){throw}
            $tssl_Main_StatusStripLabel.Text = "$($CurrentProgram.Name) launched."
        }
        catch{
            $tssl_Main_StatusStripLabel.Text = "$($CurrentProgram.Name) failed!"
            $htError = @{
                Caption="Program Button"
                Message=("The program failed to launch!`r`n`r`n" + $error[0].exception.message)
                DialogOptions="OkCancel"
            }
            [System.Windows.Forms.MessageBox]::Show($htError.Message, $htError.Caption, $htError.DialogOptions)
        }
    }
    #The program did not have a command defined, change the status bar to reflect this and exit the event handler.
    else{$tssl_Main_StatusStripLabel.Text = "Program: $($CurrentProgram.Name) has no command!"}
}
Function event_KeyUp_tb_Main_UserName{
    param(
		$object, 
		$e
	)

    #Update the config in memory with the new username
    if ($tb_Main_UserName.Text -and $cb_Main_Domain.Text){
        $script:xmlConfigHasChanged = $True
        if ($script:xmlConfig.Tables["Cache"]-eq $Null){
            $htCache = @{
                DataSet=$script:xmlconfig
                TableName="Cache"
                Columns=@("Name", "Domain")
            }
            $htRow = @{
                DataSet=$script:xmlconfig
                TableName="Cache"
                RowData=@{
                    Name=$tb_Main_UserName.Text
                    Domain=$cb_Main_Domain.Text
                }
            }
            Add-Table @htCache
            Add-Row @htRow
        }
        else{
            $script:xmlConfig.Tables["Cache"].Rows[0].Name = $tb_Main_UserName.Text
            $script:xmlConfig.Tables["Cache"].Rows[0].Domain = $cb_Main_Domain.Text
        }
    }
}
Function event_KeyDown_tb_Main_UserName{
    param(
		$object, 
		[System.Windows.Forms.KeyEventArgs]$e
	)

    $enumKeys = [System.Windows.Forms.Keys]

    $e.Handled = $True
    $e.SuppressKeyPress = $True
    $SelectionStart = $object.SelectionStart
    switch ($e.KeyCode){
        $EnumKeys::Enter {
            $form_MainLauncher.SelectNextControl($object, $true, $true, $true, $true)
        }
        default{
            $e.Handled = $False
            $e.SuppressKeyPress = $False
        }
    }
}
Function event_KeyDown_mtb_Main_Password{ #Catch special keys on the password box.
    param(
		$object, 
		[System.Windows.Forms.KeyEventArgs]$e
	)

    $enumKeys = [System.Windows.Forms.Keys]

    $e.Handled = $True
    $e.SuppressKeyPress = $True
    $SelectionStart = $object.SelectionStart

    switch ($e.KeyCode){
        $enumKeys::Enter {
            #Make the enter key act like a tab key.
            $form_MainLauncher.SelectNextControl($object, $true, $true, $true, $true)
        }
        $enumKeys::Back {
            #They want to delete a selection of text.
            #Loop through each letter in their selection and perform a delete for each one.
            if ($object.SelectionLength -gt 0){
                foreach($Letter in [char[]]$object.SelectedText){
                    $SecurePassword.RemoveAt($SelectionStart)
                    $object.Text = $object.Text.Remove($SelectionStart, 1)
                }
            }
            #They have no selection and are not at the beginning of the string.
            #Determine where they are and delete the preceding character.
            elseif ($object.SelectionStart -gt 0){
                $SecurePassword.RemoveAt(($object.SelectionStart - 1))
                $object.Text = $object.Text.Remove($object.SelectionStart - 1, 1)
            }
            #They are at the beginning of the string with no selection
            #Do nothing.
            else{
                return
            }
        }
        $enumKeys::Delete {
            #They are at the end of the string.
            #Do nothing
            if ($object.SelectionStart -ge $SecurePassword.Length){
                return
            }
            #They want to delete a selection of text.
            #Loop through each letter in their selection and perform a delete for each one.
            elseif ($object.SelectionLength -gt 0){
                foreach($Letter in [char[]]$object.SelectedText){
                    $SecurePassword.RemoveAt($SelectionStart)
                    $object.Text = $object.Text.Remove($SelectionStart, 1)
                }
            }
            #They have no selection and are somewhere before the end of the string.
            #Delete the letter at their location.
            else{
                $SecurePassword.RemoveAt($object.SelectionStart)
                $object.Text = $object.Text.Remove($object.SelectionStart, 1)
            }
        }
        #Control+V clipboard paste
        {$e.Modifiers -eq $enumKeys::Control -and $e.KeyCode -eq $EnumKeys::V}{
            if ([System.Windows.ClipBoard]::GetText()){ #Only paste if there is data on the clipboard.
                if ($object.SelectionStart -ge $SecurePassword.Length){ #Only paste onto the end or onto a blank password box.
                    foreach ($Letter in [char[]][System.Windows.Clipboard]::GetText()){
                        $SecurePassword.AppendChar($Letter)
                        [string]$object.Text += "*"
                    }
                    $SelectionStart = $SecurePassword.Length
                }
            }
        }
        #They pressed some other key.
        #Tell the system to handle it with the keypress event.
        default{
            $e.Handled = $False
            $e.SuppressKeyPress = $False
        }
    }
    #Reset the selection data.
    $object.SelectionStart = $SelectionStart
}
Function event_KeyPress_mtb_Main_Password{ #Catch all other keypresses on the password box.
    param(
		$object, 
		[System.Windows.Forms.KeyPressEventArgs]$e
	)
	
    $e.Handled = $True
    $SelectionStart = $object.SelectionStart
    #They are at the end of the string.
    #Append each character they enter.
    if ($object.SelectionStart -ge $SecurePassword.Length){
        $SecurePassword.AppendChar($e.KeyChar.ToString())
        [string]$object.Text += "*"
        $SelectionStart++
    }
    #They have a selection of characters.
    #Delete the selection and insert from their location.
    elseif($object.SelectionLength -gt 0){
        #Delete the selection
        foreach($Letter in [char[]]$object.SelectedText){
            $SecurePassword.RemoveAt($SelectionStart)
            $object.Text = $object.Text.Remove($SelectionStart, 1)
        }
        #Insert the single character
        $SecurePassword.InsertAt($SelectionStart, $e.KeyChar.ToString())
        $object.Text = [string]$object.Text.Insert($SelectionStart, "*")
        $SelectionStart++
    }
    #They are somewhere in the string.
    #Insert at their location.
    else{
        #Insert the single character
        $SecurePassword.InsertAt($SelectionStart, $e.KeyChar.ToString())
        $object.Text = [string]$object.Text.Insert($SelectionStart, "*")
        $SelectionStart++
    }
    #Reset the selection data.
    $object.SelectionStart = $SelectionStart
    $object.SelectionLength = 0
}
Function event_FormClosing_form_MainLauncher{
    param(
		$object, 
		$e
	)
	
    if ($script:xmlConfig.HasChanges() -eq $True){
        [void]$script:xmlConfig.WriteXml($script:xmlConfigFile)
    }
}
Function event_Click_tsmi_Main_Configure{
    param(
        $object,
        $e
    )
	
	$form_Config.ShowDialog()
}
Function event_Click_btn_Config_Done{
    param(
        $object,
        $e
    )
	
	$form_Config.DialogResult = [System.Windows.Forms.DialogResult]::OK
}
Function event_Click_tsmi_Main_Exit{
    param(
        $object,
        $e
    )
	
	$form_MainLauncher.Close()
}
<# End ---- Admin Launcher Event Handler Functions ---- #>

<# Begin ---- Admin Launcher Event Handler Definitions ---- #>
#Main Form
$form_MainLauncher.Add_Load({event_Load_form_MainLauncher $this $_})
$form_MainLauncher.Add_FormClosing({event_FormClosing_form_MainLauncher $this $_})
$cb_Main_Domain.Add_SelectionChangeCommitted({event_KeyUp_Tb_Main_UserName $this $_})
$mtb_Main_Password.Add_KeyDown({event_KeyDown_mtb_Main_Password $this $_})
$mtb_Main_Password.Add_KeyPress({event_KeyPress_mtb_Main_Password $this $_})
$tb_Main_UserName.Add_KeyUp({event_KeyUp_tb_Main_UserName $this $_})
$tb_Main_UserName.Add_KeyDown({event_KeyDown_tb_Main_UserName $this $_})
$tsmi_Main_Configure.Add_Click({event_Click_tsmi_Main_Configure $this $_})
$tsmi_Main_Import.Add_Click({event_Click_tsmi_Main_Import $this $_})
$tsmi_Main_Export.Add_Click({event_Click_tsmi_Main_Export $this $_})
$tsmi_Main_Reset.Add_Click({event_Click_tsmi_Main_Reset $this $_})
$tsmi_Main_Exit.Add_Click({event_Click_tsmi_Main_Exit $this $_})

#Config Form
$form_Config.Add_Activated({event_Activated_form_Config $this $_})
$form_Config.Add_Deactivate({event_Deactivate_form_Config $this $_})
$btn_Config_Done.Add_Click({event_Click_btn_Config_Done $this $_})
<# End ---- Admin Launcher Event Handler Definitions ---- #>

<# Begin ---- Admin Launcher layout calls ---- #>
$tlp_Config.ResumeLayout($False)
$gb_Main_Programs.ResumeLayout($False)
$form_Config.ResumeLayout($False)
$ss_Main_StatusStrip.ResumeLayout($False)
$ss_Main_StatusStrip.PerformLayout()
$ms_Main_MenuStrip.ResumeLayout($False)
$ms_Main_MenuStrip.PerformLayout()
$tlp_Main.ResumeLayout($False)
$tlp_Main.PerformLayout()
$gb_Main_Programs.ResumeLayout($False)
$gb_Main_RunAs.ResumeLayout($False)
$gb_Main_RunAs.PerformLayout()
$gb_Config_Programs.ResumeLayout($False)
$gb_Config_Programs.PerformLayout()
$form_MainLauncher.ResumeLayout($False)
$form_MainLauncher.PerformLayout()
<# End ---- Admin Launcher layout calls ---- #>

<# This is the last line of the script, nothing after it will execute until the form is closed. #>
$form_MainLauncher.ShowDialog() | Out-Null

<# Dispose the secure password after we're done using launcher. #>
$SecurePassword.Dispose()
