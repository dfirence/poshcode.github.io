#requires -version 2.0

<#
    .SYNOPSIS
        Script to run executable with alternate credentials as admin.
    .DESCRIPTION
        This script will try to invoke itself with alternate credentials (using Get-Credential cmdlet) and once it's there it will try to run any executable as elevated.
        Designed to work around problem with elevating process when working remotely via OFC and other remoting tools.
        Using GUI to prompt SD person about executable that is needed.


#>

param (
    # Parameter that should be added to re-run the script once we pass credentials/ alternate user step
    [switch]$Invoke,
    # Name of the process that will be used in re-run scenario
    [string]$ProcessName,
    # User that was passing his credentials - just to double-check if that's the one we need.
    [string]$RunAs
)

$MyPath = $MyInvocation.InvocationName

Add-Type -AssemblyName System.Windows.Forms -PassThru | Foreach -Begin { $Form = @{} } -Process { try { $Form.Add($_.Name,$_) } catch {return} }
Add-Type -AssemblyName System.Drawing

if ($Invoke) {
    $MyPrincipals = [security.principal.WindowsIdentity]::GetCurrent()
    if ($Runas -eq $MyPrincipals.Name) {
        try { 
            Start-Process -FilePath $ProcessName -Verb RunAs
        } catch {
            $Form.MessageBox::Show("Error: $_",'Error!','OK','Error')
        }
    }
    exit
}

# ScriptBlocks to be used by events

$handler_buttonBrowse_Click = {
    $Dialog = New-Object $Form.OpenFileDialog -Property @{
        Filter = 'Application (*.exe)|*.exe|All files (*.*)|*.*'
    }
  
    if ($Dialog.ShowDialog() -eq 'OK' -and $Dialog.FileName) {
        $textboxCmd.Text = $Dialog.FileName
    }
}

$handler_buttonOK_Click = {
    if ($textboxCmd.Text) {
        try {
            $creds = Get-Credential
            $RunAs = $creds.UserName
            $ProcessName = $textboxCmd.Text
            Start-Process -FilePath PowerShell.exe -Credential $creds -ArgumentList "-noprofile -windowStyle Hidden -file $MyPath -Invoke -ProcessName $ProcessName -RunAs $RunAs"
            $MainWindow.Close()
        } catch {
            $Form.MessageBox::Show("Error: $_",'Error!','OK','Error')
        }
    } else {
        $Form.MessageBox::Show('You have to give a path/ name of thing to run!','Path/ name is missing','OK','Error')
    }
}

$handler_buttonCancel_Click =  {
    $Form.MessageBox::Show('Bye!','You canceled me...','OK','Information')
    $MainWindow.Close()
}

$OnLoadForm_StateCorrection = {
	$MainWindow.WindowState = New-Object $Form.FormWindowState
}

# Create controls so it will be possible to add them to the form later
$buttonsSize = New-Object Drawing.Size 75, 23

$MainWindow = New-Object $Form.Form -Property @{
    Text = "Run As Admin"
    MaximizeBox = $False
    MinimizeBox = $False
    HelpButton = $True
    Name = "form1"
    ClientSize = New-Object Drawing.Size 368, 144
    KeyPreview = $True
}
$MainWindow.DataBindings.DefaultDataSourceUpdateMode = 0

$buttonBrowse = New-Object $Form.Button -Property @{
    TabIndex = 4
    Name = "buttonBrowse"
    Size = $buttonsSize
    UseVisualStyleBackColor = $True
    Text = "Browse..."
    Location = New-Object Drawing.Point 260, 85
}
$buttonBrowse.add_Click($handler_buttonBrowse_Click)
$buttonBrowse.DataBindings.DefaultDataSourceUpdateMode = 0

$buttonCancel = New-Object $Form.Button -Property @{
    TabIndex = 3
    Name = "buttonCancel"
    Size = $buttonsSize
    UseVisualStyleBackColor = $True
    Text = "Cancel"
    Location = New-Object Drawing.Point 179, 86
}
$buttonCancel.DataBindings.DefaultDataSourceUpdateMode = 0
$buttonCancel.add_Click($handler_buttonCancel_Click)

$buttonOK = New-Object $Form.Button -Property @{
    TabIndex = 2
    Name = "buttonOK"
    Size = $buttonsSize
    UseVisualStyleBackColor = $True
    Text = "OK"
    Location = New-Object Drawing.Point 98, 86
}
$buttonOK.DataBindings.DefaultDataSourceUpdateMode = 0
$buttonOK.add_Click($handler_buttonOK_Click)

$textboxCmd = New-Object $Form.TextBox -Property @{
    Size = New-Object Drawing.Size 298, 20
    Name = "textboxCmd"
    Location = New-Object Drawing.Point 38, 60
    TabIndex = 1
}
$textboxCmd.DataBindings.DefaultDataSourceUpdateMode = 0

$labelDesc = New-Object $Form.Label -Property @{
    TabIndex = 0
    Size = New-Object Drawing.Size 298,35
    Text = "Type the name of command that you want to run. You can also try to select 'Browse to...' instead."
    Location = New-Object Drawing.Point 38, 24
    Name = "labelDesc"
}
$labelDesc.DataBindings.DefaultDataSourceUpdateMode = 0

$MainWindow.Controls.AddRange(@($textboxCmd, $labelDesc, $buttonBrowse, $buttonCancel, $buttonOK))
$MainWindow.add_Load($OnLoadForm_StateCorrection)

$MainWindow.add_KeyDown({if ($_.KeyCode -eq 'Enter') {& $handler_buttonOK_Click}})
$MainWindow.add_KeyDown({if ($_.KeyCode -eq 'Escape') {& $handler_buttonCancel_Click}})

$helpDescription = @"
This script will try to invoke itself with alternate credentials (using Get-Credential cmdlet) and once it's there it will try to run any executable as elevated.
Designed to work around problem with elevating process when working remotely via OFC and other remoting tools.
Using GUI to prompt SD person about executable that is needed.
"@

$MainWindow.add_HelpButtonClicked({$Form.MessageBox::Show($helpDescription,'Help','OK','Information')})

$MainWindow.ShowDialog()| Out-Null

