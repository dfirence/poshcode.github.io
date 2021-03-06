#initial directiry
$dir = (gci $MyInvocation.MyCommand.Name).Directory
#path of MUICache on WInXP
$key = "Software\Microsoft\Windows\ShellNoRoam\MUICache"
#log stores into script path
$csv = (Split-Path (gci $MyInvocation.InvocationName).FullName) + "\MUICacheView.csv"

function ItemsCounting {
  $tlStrip.Text = $lstView.Items.Count.ToString() + " item(s)"
}

function BuildItemsList([string]$nod) {
  $rk = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($key)
  $itm = $lstView.Items.Add($nod, $i)
  $itm.SubItems.Add($rk.GetValue($nod).ToString())
  $rk.Close()
}

function InvokeScaning {
  $lstView.Items.Clear()
  $imgList.Images.Clear()
  
  [int]$i = 0
  $rk = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($key)
  $rk.GetValueNames() | % {
    if ($rk.GetValueKind($_).ToString() -ne "Binary") {
      if ($mnuHide.Checked) {
        if (-not ($_.StartsWith("@"))) {
          BuildItemsList($_)
          ++$i
          $imgList.Images.Add([Drawing.Icon]::ExtractAssociatedIcon($_).ToBitmap())
        }
      }
      else {
        BuildItemsList($_)
        if (-not ($_.StartsWith("@"))) {
          ++$i
          $imgList.Images.Add([Drawing.Icon]::ExtractAssociatedIcon($_).ToBitmap())
        } else {
          $sub = $_.Substring(1, $_.IndexOf(",") - 1)
          if ($sub -imatch "%\w+%") {$sub = $sub -replace "%\w+%", "$env:systemroot"}
          if ($sub -match "^explorer.exe$") {$sub = $env:windir + "\" + $sub}
          if ($sub -match "^\w+.dll$") {$sub = [Environment]::SystemDirectory + "\" + $sub}
          ++$i
          $imgList.Images.Add([Drawing.Icon]::ExtractAssociatedIcon($sub).ToBitmap())
        }
      }#mnuHide status
    }#not binary
  }
  $rk.Close()
}

function ChangeLanguage([string]$loc) {
  switch ($loc) {
    "en" {
      $mnuIEng.Checked = $true
      $mnuIRus.Checked = $false
      
      $mnuFile.Text = "&File"
      $mnuScan.Text = "S&can"
      $mnuSave.Text = "&Save"
      $mnuExit.Text = "E&xit"
      $mnuEdit.Text = "&Edit"
      $mnuKill.Text = "&Delete Item"
      $mnuView.Text = "&View"
      $mnuHide.Text = "&Hide System Entries"
      $mnuSBar.Text = "Show Status &Bar"
      $mnuFont.Text = "&Font..."
      $mnuLang.Text = "&Language"
      $mnuIEng.Text = "English"
      $mnuIRus.Text = "Russian"
      $mnuHelp.Text = "&Help"
      $mnuInfo.Text = "About"
      $chPath_.Text = "Application Path"
      $chDesc_.Text = "Application Description"
    }#en
    "ru" {
      $mnuIEng.Checked = $false
      $mnuIRus.Checked = $true
      
      $mnuFile.Text = "&&#1060;&#1072;&#1081;&#1083;"
      $mnuScan.Text = "&#1057;&#1085;&#1080;&#1084;&#1086;&&#1082;"
      $mnuSave.Text = "&&#1057;&#1086;&#1093;&#1088;&#1072;&#1085;&#1080;&#1090;&#1100;"
      $mnuExit.Text = "&#1042;&&#1099;&#1093;&#1086;&#1076;"
      $mnuEdit.Text = "&&#1055;&#1088;&#1072;&#1074;&#1082;&#1072;"
      $mnuKill.Text = "&&#1059;&#1076;&#1072;&#1083;&#1080;&#1090;&#1100; &#1079;&#1085;&#1072;&#1095;&#1077;&#1085;&#1080;&#1077;"
      $mnuView.Text = "&&#1042;&#1080;&#1076;"
      $mnuHide.Text = "&&#1057;&#1082;&#1088;&#1099;&#1074;&#1072;&#1090;&#1100; &#1089;&#1080;&#1089;&#1090;&#1077;&#1084;&#1085;&#1099;&#1077;"
      $mnuSBar.Text = "&#1057;&#1090;&#1088;&#1086;&#1082;&#1072; &#1089;&#1086;&#1089;&#1090;&#1086;&#1103;&#1085;&&#1080;&#1103;"
      $mnuFont.Text = "&&#1064;&#1088;&#1080;&#1092;&#1090;..."
      $mnuLang.Text = "&&#1071;&#1079;&#1099;&#1082;"
      $mnuIEng.Text = "&#1040;&#1085;&#1075;&#1083;&#1080;&#1081;&#1089;&#1082;&#1080;&#1081;"
      $mnuIRus.Text = "&#1056;&#1091;&#1089;&#1089;&#1082;&#1080;&#1081;"
      $mnuHelp.Text = "&&#1057;&#1087;&#1088;&#1072;&#1074;&#1082;&#1072;"
      $mnuInfo.Text = "&#1054; &#1087;&#1088;&#1086;&#1075;&#1088;&#1072;&#1084;&#1084;&#1077;"
      $chPath_.Text = "&#1055;&#1088;&#1080;&#1083;&#1086;&#1078;&#1077;&#1085;&#1080;&#1077;"
      $chDesc_.Text = "&#1054;&#1087;&#1080;&#1089;&#1072;&#1085;&#1080;&#1077;"
    }#ru
  }
}

$mnuSave_Click= {
  if ($lstView.Items.Count -ne 0) {
    (New-Object Windows.Forms.SaveFileDialog) | % {
      $_.FileName = "MUICacheView"
      $_.Filter = "CSV (*.csv)|*.csv"
      $_.InitialDirectory = $dir
      
      if ($_.ShowDialog() -eq [Windows.Forms.DialogResult]::OK) {
        $sw = New-Object IO.StreamWriter($_.FileName, [Text.Encoding]::Default)
        $sw.WriteLine("Application Path, Application Description")
        $lstView.Items | % {
          $sw.WriteLine($($_.Text + ', ' + $_.SubItems[1].Text))
        }
        $sw.Flush()
        $sw.Close()
      }
    }#for each
  }#if
}

$mnuKIll_Click= {
  $rk = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey($key, $true)
  
  for ([int]$i = 0; $i -lt $lstView.Items.Count; $i++) {
    if ($lstView.Items[$i].Selected) {
      $rk.DeleteValue($lstView.Items[$i].Text, $false)
      $lstView.Items[$i].Remove()
      $i--
    }
  }
  
  ItemsCounting
}

$mnuHide_Click= {
  [bool]$tgl =! $mnuHide.Checked
  $mnuHide.Checked = $tgl
  
  InvokeScaning
  ItemsCounting
}

$mnuSBar_Click= {
  [bool]$tgl =! $mnuSBar.Checked
  $mnuSBar.Checked = $tgl
  $sbInfo_.Visible = $tgl
}

$mnuFont_Click= {
  (New-Object Windows.Forms.FontDialog) | % {
    $_.MaxSize = 12
    $_.ShowEffects = $false
    
    if ($_.ShowDialog() -eq [Windows.Forms.DialogResult]::OK) {
      $lstView.Font = $_.Font
    }#if
  }#for each
}

function frmMain_Show {
  Add-Type -Assembly System.Windows.Forms
  [Windows.Forms.Application]::EnableVisualStyles()
  
  $ico = [Drawing.Icon]::ExtractAssociatedIcon($pshome + "\powershell.exe")
  
  $frmMain = New-Object Windows.Forms.Form
  $mnuMain = New-Object Windows.Forms.MenuStrip
  $mnuFile = New-Object Windows.Forms.ToolStripMenuItem
  $mnuScan = New-Object Windows.Forms.ToolStripMenuItem
  $mnuSave = New-Object Windows.Forms.ToolStripMenuItem
  $mnuNul1 = New-Object Windows.Forms.ToolStripSeparator
  $mnuExit = New-Object Windows.Forms.ToolStripMenuItem
  $mnuEdit = New-Object Windows.Forms.ToolStripMenuItem
  $mnuKill = New-Object Windows.Forms.ToolStripMenuItem
  $mnuView = New-Object Windows.Forms.ToolStripMenuItem
  $mnuHide = New-Object Windows.Forms.ToolStripMenuItem
  $mnuSBar = New-Object Windows.Forms.ToolStripMenuItem
  $mnuNul2 = New-Object Windows.Forms.ToolStripSeparator
  $mnuFont = New-Object Windows.Forms.ToolStripMenuItem
  $mnuNul3 = New-Object Windows.Forms.ToolStripSeparator
  $mnuLang = New-Object Windows.Forms.ToolStripMenuItem
  $mnuIEng = New-Object Windows.Forms.ToolStripMenuItem
  $mnuIRus = New-Object Windows.Forms.ToolStripMenuItem
  $mnuHelp = New-Object Windows.Forms.ToolStripMenuItem
  $mnuInfo = New-Object Windows.Forms.ToolStripMenuItem
  $lstView = New-Object Windows.Forms.ListView
  $imgList = New-Object Windows.Forms.ImageList
  $chPath_ = New-Object Windows.Forms.ColumnHeader
  $chDesc_ = New-Object Windows.Forms.ColumnHeader
  $stStrip = New-Object Windows.Forms.StatusStrip
  $tlStrip = New-Object Windows.Forms.ToolStripStatusLabel
  #
  #mnuMain
  #
  $mnuMain.Items.AddRange(@($mnuFile, $mnuEdit, $mnuView, $mnuHelp))
  #
  #mnuFile
  #
  $mnuFile.DropDownItems.AddRange(@($mnuScan, $mnuSave, $mnuNul1, $mnuExit))
  #
  #mnuScan
  #
  $mnuScan.ShortcutKeys = "F5"
  $mnuScan.Add_Click({InvokeScaning;ItemsCounting})
  #
  #mnuSave
  #
  $mnuSave.ShortcutKeys = "Control, S"
  $mnuSave.Add_Click($mnuSave_Click)
  #
  #mnuExit
  #
  $mnuExit.ShortcutKeys = "Control, X"
  $mnuExit.Add_Click({$frmMain.Close()})
  #
  #mnuEdit
  #
  $mnuEdit.DropDownItems.AddRange(@($mnuKill))
  #
  #mnuKill
  #
  $mnuKill.ShortcutKeys = "Del"
  $mnuKill.Add_Click($mnuKill_Click)
  #
  #mnuView
  #
  $mnuView.DropDownItems.AddRange(@($mnuHide, $mnuSBar, $mnuNul2, $mnuFont, $mnuNul3, $mnuLang))
  #
  #mnuHide
  #
  $mnuHide.Checked = $true
  $mnuHide.ShortcutKeys = "Control, H"
  $mnuHide.Add_Click($mnuHide_Click)
  #
  #mnuSBar
  #
  $mnuSBar.Checked = $true
  $mnuSBar.ShortcutKeys = "Control, B"
  $mnuSBar.Add_Click($mnuSBar_Click)
  #
  #mnuFont
  #
  $mnuFont.Add_Click($mnuFont_Click)
  #
  #mnuLang
  #
  $mnuLang.DropDownItems.AddRange(@($mnuIEng, $mnuIRus))
  #
  #mnuIEng
  #
  $mnuIEng.Add_Click({ChangeLanguage("en")})
  #
  #mnuIRus
  #
  $mnuIRus.Add_Click({ChangeLanguage("ru")})
  #
  #mnuHelp
  #
  $mnuHelp.DropDownItems.AddRange(@($mnuInfo))
  #
  #mnuInfo
  #
  $mnuInfo.Add_Click({frmAbout_Show})
  #
  #lstView
  #
  $lstView.AllowColumnReorder = $true
  $lstView.Columns.AddRange(@($chPath_, $chDesc_))
  $lstView.Dock = "Fill"
  $lstView.FullRowSelect = $true
  $lstView.MultiSelect = $false
  $lstView.SmallImageList = $imgList
  $lstView.Sorting = "Ascending"
  $lstView.View = "Details"
  #
  #imgList
  #
  $imgList.ImageSize = New-Object Drawing.Size(17, 15)
  #
  #chPath_
  #
  $chPath_.Width = 275
  #
  #chName_
  #
  $chDesc_.Width = 330
  #
  #sbInfo_
  #
  $stStrip.Items.AddRange(@($tlStrip))
  $stStrip.SizingGrip = $false
  #
  #tlStrip
  #
  $tlStrip.Alignment = "Left"
  $tlStrip.BorderStyle = "Raised"
  #
  #frmMain
  #
  $frmMain.ClientSize = New-Object Drawing.Size(573, 217)
  $frmMain.Controls.AddRange(@($lstView, $stStrip, $mnuMain))
  $frmMain.MainMenuStrip = $mnuMain
  $frmMain.MaximizeBox = $false
  $frmMain.Icon = $ico
  $frmMain.StartPosition = "CenterScreen"
  $frmMain.Text = "MUICacheView"
  $frmMain.Add_Load({ItemsCounting; ChangeLanguage("en")})
  
  [void]$frmMain.ShowDialog()
}

function frmAbout_Show {
  $frmMain = New-Object Windows.Forms.Form
  $pbImage = New-Object Windows.Forms.PictureBox
  $lblName = New-Object Windows.Forms.Label
  $lblCopy = New-Object Windows.Forms.Label
  $btnExit = New-Object Windows.Forms.Button
  #
  #pbImage
  #
  $pbImage.Location = New-Object Drawing.Point(16, 16)
  $pbImage.Size = New-Object Drawing.Size(32, 32)
  $pbImage.SizeMode = "StretchImage"
  #
  #lblName
  #
  $lblName.Font = New-Object Drawing.Font("Microsoft Sans Serif", 8.5, [Drawing.FontStyle]::Bold)
  $lblName.Location = New-Object Drawing.Point(53, 19)
  $lblName.Size = New-Object Drawing.Size(360, 18)
  $lblName.Text = "MUICacheView v1.03"
  #
  #lblCopy
  #
  $lblCopy.Location = New-Object Drawing.Point(67, 37)
  $lblCopy.Size = New-Object Drawing.Size(360, 15)
  $lblCopy.Text = "Copyright (C) 2012-2013 gregzakh@gmail.com"
  #
  #btnExit
  #
  $btnExit.Location = New-Object Drawing.Point(135, 57)
  $btnExit.Text = "OK"
  #
  #frmMain
  #
  $frmMain.AcceptButton = $btnExit
  $frmMain.CancelButton = $btnExit
  $frmMain.ClientSize = New-Object Drawing.Size(350, 90)
  $frmMain.ControlBox = $false
  $frmMain.Controls.AddRange(@($pbImage, $lblName, $lblCopy, $btnExit))
  $frmMain.FormBorderStyle = "FixedSingle"
  $frmMain.ShowInTaskbar = $false
  $frmMain.StartPosition = "CenterParent"
  $frmMain.Text = "About..."
  $frmMain.Add_Load({$pbImage.Image = $ico.ToBitmap()})
  
  [void]$frmMain.ShowDialog()
}

frmMain_Show
