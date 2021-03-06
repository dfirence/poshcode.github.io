function Get-UserStatus {
  $script:usr = [Security.Principal.WindowsIdentity]::GetCurrent()
  return (New-Object Security.Principal.WindowsPrincipal $usr).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
  )
}

function Get-ImageFromString($img) {
  [Drawing.Image]::FromStream((New-Object IO.MemoryStream(
    ($$ = [Convert]::FromBase64String($img)), 0, $$.Length))
  )
}

function Get-NameSpaces([String]$root) {
  (New-Object Management.ManagementClass(
      $root, [Management.ManagementPath]'__NAMESPACE', $null
    )
  ).PSBase.GetInstances() | % {
    return (New-Object Windows.Forms.TreeNode).Nodes.Add($_.Name)
  }
}

function Get-SubNameSpaces([Windows.Forms.TreeNode[]]$nodes) {
  foreach ($nod in $nodes) {
    Get-NameSpaces ('root\' + $nod.FullPath) | % {$nod.Nodes.Add($_)}
  }
}

function Reset-AllMessages {
  $lvList2, $lvList3, $lvList4 | % {$_.Items.Clear()}
  $rtbText.Clear()
  $sbLbl_2, $sbLbl_3, $sbLbl_4 | % {$_.Text = [String]::Empty}
}

$mnuMore_Click= {
  $toggle =! $mnuMore.Checked
  $mnuMore.Checked = $toggle
  $scSplt1.Panel2Collapsed =! $toggle
}

$mnuSBar_Click= {
  $toggle =! $mnuSBar.Checked
  $mnuSBar.Checked = $toggle
  $sbStrip.Visible = $toggle
}

$mnuText_Click= {
  $toggle =! $mnuText.Checked
  $mnuText.Checked = $toggle
  $rtbText.Clear()
}

$tvRoots_AfterSelect= {
  $lvList1.Items.Clear()
  Reset-AllMessages
  
  if ($tvRoots.SelectedNode) {
    $cur = 'root\' + $tvRoots.SelectedNode.FullPath
    $sbLbl_2.Text = $cur
    
    (New-Object Management.ManagementClass(
        ('root\' + $tvRoots.SelectedNode.FullPath), $obj
      )
    ).PSBase.GetSubclasses($enm) | % {
      $itm = $lvList1.Items.Add($_.Name, 1)
      try {$itm.SubItems.Add($_.PSBase.Qualifiers.Item("Description").Value)}
      catch {$itm.SubItems.Add("<Not described>")}
    }
    
    $lvList1.AutoResizeColumns([Windows.Forms.ColumnHeaderAutoResizeStyle]::ColumnContent)
    $sbLbl_1.Text = "Total Classes: " + $lvList1.Items.Count.ToString()
  }
}

$lvList1_Click= {
  Reset-AllMessages
  
  for ($i = 0; $i -lt $lvList1.Items.Count; $i++) {
    if ($lvList1.Items[$i].Selected) {
      $path = $cur + ":" + $lvList1.Items[$i].Text
      $sbLbl_2.Text = $path
      
      $wmi = (New-Object Management.ManagementClass($path, $obj)).PSBase

      $wmi.Methods | % {
        $itm = $lvList2.Items.Add($_.Name, 2)
        $itm.SubItems.Add($_.Origin)
        $itm.SubItems.Add([String]::Empty)
        $itm.SubItems.Add([String]::Empty)
        $itm.SubItems.Add([String]::Empty)
        try {
          $itm.SubItems.Add($_.PSBase.Qualifiers["Description"].Value)
        }
        catch {
          $itm.SubItems.Add([String]::Empty)
        }
      }

      $wmi.Properties | % {
        $itm = $lvList2.Items.Add($_.Name, 3)
        $itm.SubItems.Add([String]::Empty)
        $itm.SubItems.Add($_.Type.ToString())
        $itm.SubItems.Add($_.IsLocal.ToString())
        $itm.SubItems.Add($_.IsArray.ToString())
        try {
          $itm.SubItems.Add($_.PSBase.Qualifiers["Description"].Value)
        }
        catch {
          $itm.SubItems.Add([String]::Empty)
        }
      }

      $wmi.Derivation | % {$lvList3.Items.Add($_, 1)}

      $wmi.Qualifiers | % {
        $itm = $lvList4.Items.Add($_.Name, 4)
        $itm.SubItems.Add($_.Value.ToString())
        $itm.SubItems.Add($_.IsAmended.ToString())
        $itm.SubItems.Add($_.IsLocal.ToString())
        $itm.SubItems.Add($_.IsOverridable.ToString())
        $itm.SubItems.Add($_.PropagatesToInstance.ToString())
        $itm.SubItems.Add($_.PropagatesToSubclass.ToString())
      }

      if ($mnuText.Checked) {
        $ErrorActionPreference = 0
        $wmi.GetInstances() | % {
          $rtbText.AppendText("$('=' * 100)`n")
          foreach ($prop in $_.PSBase.Properties) {
            $rtbText.SelectionFont = $bold
            $rtbText.AppendText($prop.Name + ": ")
            $rtbText.SelectionFont = $norm

            if ($prop.Value -eq $null) {
              $rtbText.AppendText("`n")
            }
            elseif ($prop.IsArray) {
              $ofs = "`n"
              $rtbText.AppendText("$($prop.Value)")
              $ofs = $null
              $rtbText.AppendText("`n")
            }
            else {
              $rtbText.AppendText("$($prop.Value)`n")
            }
          }
          $rtbText.AppendText("`n$('=' * 100)`n")
        }
        $ErrorActionPreference = 2
      }
    }
  }
  
  $lvList2.AutoResizeColumns([Windows.Forms.ColumnHeaderAutoResizeStyle]::ColumnContent)
  if ($lvList3.Items.Count -ne 0) {
    $lvList3.AutoResizeColumns([Windows.Forms.ColumnHeaderAutoResizeStyle]::ColumnContent)
  }
  $sbLbl_3.Text = "Methods: " + $wmi.Methods.Count.ToString()
  $sbLbl_4.Text = "Properties: " + $wmi.Properties.Count.ToString()
}

$frmMain_Load= {
  if (Get-UserStatus) {
    Get-NameSpaces 'root' | % {$tvRoots.Nodes.Add($_)}
    Get-SubNameSpaces $tvRoots.Nodes
    
    $obj = New-Object Management.ObjectGetOptions
    $enm = New-Object Management.EnumerationOptions
    #set both "True"
    $obj.UseAmendedQualifiers = $true
    $enm.EnumerateDeep = $true
    
    $sbLbl_1.Text = "Ready"
  }
  else {
    $sbLbl_1.Font = New-Object Drawing.Font("Microsoft Sans Serif", 8, [Drawing.FontStyle]::Bold)
    $sbLbl_1.ForeColor = "Crimson"
    $sbLbl_1.Text = ($usr.Name + " is not an administrator.")
  }
}

function frmMain_Show {
  [void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
  [Windows.Forms.Application]::EnableVisualStyles()
  #
  #fonts
  #
  $bold = New-Object Drawing.Font("Microsoft Sans Serif", 8, [Drawing.FontStyle]::Bold)
  $norm = New-Object Drawing.Font("Microsoft Sans Serif", 8, [Drawing.FontStyle]::Regular)
  #
  #resources
  #
  $ico = [Drawing.Icon]::ExtractAssociatedIcon(($PSHome + '\powershell.exe'))
  #
  #namespace picture
  #
  $img1 = "Qk1mAgAAAAAAADYAAAAoAAAADQAAAA4AAAABABgAAAAAADACAAAAAAAAAAAAAAAAAAAAAAAA//////" + `
          "//////////////////////////////////////////////AP///////////wAAAAAAAAAAAP///wAA" + `
          "AAAAAAAAAP///////////wD///////8AAAAAAAD///////////////////8AAAAAAAD///////8A//" + `
          "//////AAAAAAAA////////////////////AAAAAAAA////////AP///////wAAAAAAAP//////////" + `
          "/////////wAAAAAAAP///////wD///////8AAAAAAAD///////////////////8AAAAAAAD///////" + `
          "8A////////AAAAAAAA////////////////////AAAAAAAA////////AAAAAAAAAAAAAP//////////" + `
          "/////////////////wAAAAAAAAAAAAD///////8AAAAAAAD///////////////////8AAAAAAAD///" + `
          "////8A////////AAAAAAAA////////////////////AAAAAAAA////////AP///////wAAAAAAAP//" + `
          "/////////////////wAAAAAAAP///////wD///////8AAAAAAAD///////////////////8AAAAAAA" + `
          "D///////8A////////////AAAAAAAAAAAA////AAAAAAAAAAAA////////////AP//////////////" + `
          "/////////////////////////////////////wA="
  #
  #class picture
  #
  $img2 = "Qk02BQAAAAAAADYEAAAoAAAAEAAAABAAAAABAAgAAAAAAAABAAAAAAAAAAAAAAABAAAAAQAA////AN" + `
          "ju9gDYm1sA+O7jAMS3rQAUquEA/ez9ANrv9gDTZdIA2+/3AJeAbwCZMwAADGKBAI0tjAAOeJ4A/fD9" + `
          "AP/NmQD97f0A+q36ANxw2wAXmMgAbNbzAPuY+gCF4fUAUMvxAFDL8gA0wO8A997iAOm0fAC1YzUA+v" + `
          "TtABy17QDZbNgAa9f0AB217gA1wPAAHbXtALM8sgCF4PUAhuH0APnw5wD68uoAT8vxABy27gBr1vQA" + `
          "yXNDAIbh9QAvvu8ANMDwAPnx6QD///8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADIyMjIyMjIyMjIAAwAyMjIyMjIyMjIyMjIAMQsDADIyMj" + `
          "IyMjIyMjIyHh0CCwMAMjIyMjIyMjIECgIQHAILAwAyMjIyMjIyBDIDAhAcAgsDMjIyADIyMgQyMgMC" + `
          "EC0oADIyAAcAMjIEMjIyGwIpADIyAAcOBwAyBDIyBg0bADIyAAcOKw4HAAQyBiUTDREAMgEOKhovDA" + `
          "oKCiASFhMNEQAFFyEYMCIMATIGCBIWEw0RAQUuFRkjHwwBMgYIEggGAAAJBSYVGRokDAEADwgPADIy" + `
          "AAkFJywYFAEAMgAPADIyMjIACQUXFAEAMjIyADIyMjIyMgAJBQEAMjIyMjIyMjI="
  #
  #method picture
  #
  $img3 = "Qk3mBAAAAAAAADYEAAAoAAAAEAAAAAsAAAABAAgAAAAAALAAAAAAAAAAAAAAAAABAAAAAQAA0GnPAK" + `
          "61rADw1fAAq/D3APuY+gDvpe4ArNXVALxvuwDy2/IAfi5+AKlQqACePJ4Aq+XpAPPg8gD7q/oAfS18" + `
          "APuZ+gDVb9UAl1KWAN6Y3QDUbtMA+5v6AOzS7ACtu7UAjjWNAK6kmADkyuQA4q/iAOyR6wCqUqkAci" + `
          "RxAO3Y7QDuvu4A+5/6AKzOzAD05vQAj0aOAJFOkADr0esArpmKANJt0QCWOJUA8OPwAO+d7gDz4/MA" + `
          "qE+nAPuu+gCr4uUAp1CmAOjR6AB7K3oA55jmAK6nnADmzOYA46zjAKzEwQDqkOkAgDB/AKpQqQB/MH" + `
          "4AfC58AHUndQDPiM8A////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAD8/Pz8/Pz8/Pz8/Fh41Pz8/Pz8/Pz8/Pz8/Hwo5PSY/Pz" + `
          "8/Pz8/Pz8/MToACSkyAj8/Ay8iFzQ/GgooFDsLGA8/Pz8/Pz8/Px0AEQcTJAsJPwMMBjcBGT8tKAcF" + `
          "ISsSPD8/Pz8/Pz8/MAcFFQQQMyU/Pz8DBgEnPz4bDgQEOD4jPz8/Pz8/Pz8CPiAuHD4NPz8/Pz8/Pz" + `
          "8/Pwg+Nj4sPz8/Pz8/Pz8/Pz8/CD4qPz8/"
  #
  #property picture
  #
  $img4 = "Qk02BQAAAAAAADYEAAAoAAAAEAAAABAAAAABAAgAAAAAAAABAAAAAAAAAAAAAAABAAAAAQAAxK+iAP" + `
          "///wD7/f8AVE5GAN+dfQBu6/8Aj6SsAP//9gBo7f8AVE9NAPzw6ADRyMEA0sjBAEphcABST0sAS2Fw" + `
          "AP///gACIS4AUk9MAHLh+QAVJzMAQaxTAFdNWQD+/v0Aeo+ZAOfr7QB6zeIA//nsADKy3wAVk8QAKZ" + `
          "c/ANnPyABhwd4AMDpPAP/l1gDCyNAA+OLSAKOsuABZeFsA+/TvAHx1cwCnkokAMp5BADG76gBdXGAA" + `
          "adv2AFOElQBXa4AAwsrOAH/j+QDf5OUA/d7LAP328gDRx8AAUmBnANq6qgC/yM0A/8WkAEBmUQCTtp" + `
          "kAhcyFAP/w4QCa06QAEajsAGrd9wD/6tIAGIwyAP77+ACAl6MAXnWEAAsQGwBccYAAHGYpAP/p3ABp" + `
          "nIkALqnWAPvu5gD/7eMAW21/AFjS8wCBprUAU1BMAIPh9gCknZYA/+LQACK6+gCw6/oAEAcKAP36+A" + `
          "BBPVAAT1ZlAEvH7QBYmK4AcMF9APHKtwD/6tUAcuL6AP7+/ABfoqYA//78ABRijgBRTksA+uneALCt" + `
          "rAD/+/kAQVxyANPJwgBWz/IAVL3cANTZ3QBOS0sAgJagAFCQjABAw+0AZ9f0AOXJuQBRcosAlbjEAO" + `
          "PZ0wBzhZMA4unpAIbT5QAdmcgAVlFNAB/Q/wD///8AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" + `
          "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAH19fX19fX19fX19fX19fX0obgkJCXtRDhIOZQN9fX19Hw" + `
          "ECAgcHBxs9X0EDfX19fQwBAABoAAAAAAAzA319fX0MAQICY1gnTGYkVAN9fX19agEAABAAAAAAACID" + `
          "fX19fTUBAgIBF0M0CgpJA319fX0LAQICAQFhZ2l2TQN9fX19CwF4RTIBMA1LRixTfX07SAReBnkPKQ" + `
          "0gFnwUVxFaJkIEOXMGUg8aNghZHHodZDoeBAQENwYxLgghLU9xKz9wKn19fX0ZLwhcBRNAa1tVYhV9" + `
          "fX19I1ZOBQUFYHJsdEo8fX19fSV1bVBEbxh3Rzg+XX19fX19fX19fX19fX19fX0="
  #
  #qualifier picture
  #
  $img5 = "Qk32AgAAAAAAADYAAAAoAAAADgAAABAAAAABABgAAAAAAMACAAAAAAAAAAAAAAAAAAAAAAAA4evr//" + `
          "//////////////////////////////////////////////////AACZqKyZqKyZqKyZqKyZqKyZqKyZ" + `
          "qKyZqKyZqKyZqKyZqKyZqKyZqKz///8AAJmorP///+Ts7eTs7eTs7eTs7eTs7eTs7eTs7OTs7OTs7O" + `
          "Ps7JmorP///wAAmais////5+7u5+7v5+7v5+7v////////////////5+7u5u7umais////AACZqKz/" + `
          "///n7u7n7u/n7u+ZqKyZqKyZqKyZqKzn7u7n7u7m7u6ZqKz///8AAJmorP///+rw7+rw7////5morP" + `
          "///////////////+rw7+rv75morP///wAAmais////6vDvmaismaismaismaismaismais6vDv6vDv" + `
          "6u/vmais////AACZqKz////s8fCZqKz////////////////////////s8fHs8fGZqKz///8AAJmorP" + `
          "///+zx8JmorJmorJmorJmorJmorJmorOzx8ezx8ezx8ZmorP///wAAmais////7/Lwmais////7/Lx" + `
          "////////////////7vLx7/Lwmais////AACZqKz////v8vCZqKz///+ZqKyZqKyZqKyZqKzu8vHu8v" + `
          "Hv8vCZqKz///8AAJmorP////Dz8ZmorP///5morP////////////////Dz8f///5morP///wAAmais" + `
          "////8PPxmaismaismaismaismaismais8PPxmaismaismais7/PxAACZqKz////09PL19PP19PP19P" + `
          "P09PP09PP09PP09POZqKyZqKz08/P08/MAAJmorP///////////////////////////////////5mo" + `
          "rPTz8/Tz8/Tz8wAAmaismaismaismaismaismaismaismaismaismais9PTy9PTz9PTz9PTzAAA="
  #
  #form objects
  #
  $frmMain = New-Object Windows.Forms.Form
  $mnuMain = New-Object Windows.Forms.MenuStrip
  $mnuFile = New-Object Windows.Forms.ToolStripMenuItem
  $mnuExit = New-Object Windows.Forms.ToolStripMenuItem
  $mnuView = New-Object Windows.Forms.ToolStripMenuItem
  $mnuMore = New-Object Windows.Forms.ToolStripMenuItem
  $mnuSbar = New-Object Windows.Forms.ToolStripMenuItem
  $mnuTune = New-Object Windows.Forms.ToolStripMenuItem
  $mnuText = New-Object Windows.Forms.ToolStripMenuItem
  $mnuHelp = New-Object Windows.Forms.ToolStripMenuItem
  $mnuInfo = New-Object Windows.Forms.ToolStripMenuItem
  $scSplt1 = New-Object Windows.Forms.SplitContainer
  $scSplt2 = New-Object Windows.Forms.SplitContainer
  $scSplt3 = New-Object Windows.Forms.SplitContainer
  $tvRoots = New-Object Windows.Forms.TreeView
  $tabCtrl = New-Object Windows.Forms.TabControl
  $tpPage1 = New-Object Windows.Forms.TabPage
  $tpPage2 = New-Object Windows.Forms.TabPage
  $tpPage3 = New-Object Windows.Forms.TabPage
  $lvList1 = New-Object Windows.Forms.ListView
  $lvList2 = New-Object Windows.Forms.ListView
  $lvList3 = New-Object Windows.Forms.ListView
  $lvList4 = New-Object Windows.Forms.ListView
  $chCol_1 = New-Object Windows.Forms.ColumnHeader
  $chCol_2 = New-Object Windows.Forms.ColumnHeader
  $chCol_3 = New-Object Windows.Forms.ColumnHeader
  $chCol_4 = New-Object Windows.Forms.ColumnHeader
  $chCol_5 = New-Object Windows.Forms.ColumnHeader
  $chCol_6 = New-Object Windows.Forms.ColumnHeader
  $chCol_7 = New-Object Windows.Forms.ColumnHeader
  $chCol_8 = New-Object Windows.Forms.ColumnHeader
  $chCol_9 = New-Object Windows.Forms.ColumnHeader
  $chCol10 = New-Object Windows.Forms.ColumnHeader
  $chCol11 = New-Object Windows.Forms.ColumnHeader
  $chCol12 = New-Object Windows.Forms.ColumnHeader
  $chCol13 = New-Object Windows.Forms.ColumnHeader
  $chCol14 = New-Object Windows.Forms.ColumnHeader
  $chCol15 = New-Object Windows.Forms.ColumnHeader
  $chCol16 = New-Object Windows.Forms.ColumnHeader
  $rtbText = New-Object Windows.Forms.RichTextBox
  $imgList = New-Object Windows.Forms.ImageList
  $sbStrip = New-Object Windows.Forms.StatusStrip
  $sbLbl_1 = New-Object Windows.Forms.ToolStripStatusLabel
  $sbLbl_2 = New-Object Windows.Forms.ToolStripStatusLabel
  $sbLbl_3 = New-Object Windows.Forms.ToolStripStatusLabel
  $sbLbl_4 = New-Object Windows.Forms.ToolStripStatusLabel
  #
  #mnuMain
  #
  $mnuMain.Items.AddRange(@($mnuFile, $mnuView, $mnuTune, $mnuHelp))
  #
  #mnuFile
  #
  $mnuFile.DropDownItems.AddRange(@($mnuExit))
  $mnuFile.Text = "&File"
  #
  #mnuExit
  #
  $mnuExit.ShortcutKeys = "Control", "X"
  $mnuExit.Text = "E&xit"
  $mnuExit.Add_Click({$frmMain.Close()})
  #
  #mnuView
  #
  $mnuView.DropDownItems.AddRange(@($mnuMore, $mnuSBar))
  $mnuView.Text = "&View"
  #
  #mnuMore
  #
  $mnuMore.Checked = $true
  $mnuMore.ShortcutKeys = "Control", "L"
  $mnuMore.Text = "Detai&ls Pane"
  $mnuMore.Add_Click($mnuMore_Click)
  #
  #mnuSBar
  #
  $mnuSBar.Checked = $true
  $mnuSBar.Text = "&Status Bar"
  $mnuSBar.Add_Click($mnuSBar_Click)
  #
  #mnuTune
  #
  $mnuTune.DropDownItems.AddRange(@($mnuText))
  $mnuTune.Text = "&Options"
  #
  #mnuText
  #
  $mnuText.ShortcutKeys = "F12"
  $mnuText.Text = "Read Instances"
  $mnuText.Add_Click($mnuText_Click)
  #
  #mnuHelp
  #
  $mnuHelp.DropDownItems.AddRange(@($mnuInfo))
  $mnuHelp.Text = "&Help"
  #
  #mnuInfo
  #
  $mnuInfo.Text = "About..."
  $mnuInfo.Add_Click({frmInfo_Show})
  #
  #scSplt1
  #
  $scSplt1.Dock = "Fill"
  $scSplt1.Orientation = "Horizontal"
  $scSplt1.Panel1.Controls.Add($scSplt2)
  $scSplt1.Panel2.Controls.Add($tabCtrl)
  $scSplt1.Panel2MinSize = 23
  $scSplt1.SplitterDistance = 330
  $scSplt1.SplitterWidth = 1
  #
  #scSplt2
  #
  $scSplt2.Dock = "Fill"
  $scSplt2.Panel1.Controls.Add($tvRoots)
  $scSplt2.Panel2.Controls.Add($scSplt3)
  $scSplt2.Panel1MinSize = 17
  $scSplt2.SplitterDistance = 30
  $scSplt2.SplitterWidth = 1
  #
  #tabCtrl
  #
  $tabCtrl.Controls.AddRange(@($tpPage1, $tpPage2, $tpPage3))
  $tabCtrl.Dock = "Fill"
  #
  #tpPage1
  #
  $tpPage1.Controls.AddRange(@($lvList3))
  $tpPage1.Text = "Derivation"
  $tpPage1.UseVisualStyleBackColor = $true
  #
  #lvList3
  #
  $lvList3.Columns.AddRange(@($chCol_9))
  $lvList3.Dock = "Fill"
  $lvList3.SmallImageList = $imgList
  $lvList3.Sorting = "Ascending"
  $lvList3.View = "Details"
  #
  #chCol_9
  #
  $chCol_9.Text = "Class"
  $chCol_9.Width = 130
  #
  #tpPage2
  #
  $tpPage2.Controls.AddRange(@($lvList4))
  $tpPage2.Text = "Qualifiers"
  $tpPage2.UseVisualStyleBackColor = $true
  #
  #lvList4
  #
  $lvList4.Columns.AddRange(@($chCol10, $chCol11, $chCol12, $chCol13, $chCol14, $chCol15, $chCol16))
  $lvList4.Dock = "Fill"
  $lvList4.FullRowSelect = $true
  $lvList4.MultiSelect = $false
  $lvList4.ShowItemToolTips = $true
  $lvList4.SmallImageList = $imgList
  $lvList4.Sorting = "Ascending"
  $lvList4.View = "Details"
  #
  #chCol10
  #
  $chCol10.Text = "Name"
  $chCol10.Width = 170
  #
  #chCol11
  #
  $chCol11.Text = "Value"
  $chCol11.Width = 130
  #
  #chCol12
  #
  $chCol12.Text = "IsAmended"
  $chCol12.Width = 70
  #
  #chCol13
  #
  $chCol13.Text = "IsLocal"
  $chCol13.Width = 50
  #
  #chCol14
  #
  $chCol14.Text = "IsOverridable"
  $chCol14.Width = 80
  #
  #chCol15
  #
  $chCol15.Text = "PropagatesToInstance"
  $chCol15.Width = 130
  #
  #chCol16
  #
  $chCol16.Text = "PropagatesToSubclass"
  $chCol16.Width = 130
  #
  #tpPage3
  #
  $tpPage3.Controls.AddRange(@($rtbText))
  $tpPage3.Text = "Instances"
  $tpPage3.UseVisualStyleBackColor = $true
  #
  #rtbText
  #
  $rtbText.Dock = "Fill"
  #
  #tvRoots
  #
  $tvRoots.Dock = "Fill"
  $tvRoots.ImageList = $imgList
  $tvRoots.Select()
  $tvRoots.Sorted = $true
  $tvRoots.Add_AfterExpand({Get-SubNameSpaces $_.Node.Nodes})
  $tvRoots.Add_AfterSelect($tvRoots_AfterSelect)
  #
  #scSplt3
  #
  $scSplt3.Dock = "Fill"
  $scSplt3.Orientation = "Horizontal"
  $scSplt3.Panel1.Controls.Add($lvList1)
  $scSplt3.Panel2.Controls.Add($lvList2)
  $scSplt3.SplitterWidth = 1
  #
  #lvList1
  #
  $lvList1.Columns.AddRange(@($chCol_1, $chCol_2))
  $lvList1.Dock = "Fill"
  $lvList1.FullRowSelect = $true
  $lvList1.MultiSelect = $false
  $lvList1.ShowItemToolTips = $true
  $lvList1.SmallImageList = $imgList
  $lvList1.Sorting = "Ascending"
  $lvList1.View = "Details"
  $lvList1.Add_Click($lvList1_Click)
  #
  #chCol_1
  #
  $chCol_1.Text = "Class"
  $chCol_1.Width = 130
  #
  #chCol_2
  #
  $chCol_2.Text = "Description"
  $chCol_2.Width = 130
  #
  #lvList2
  #
  $lvList2.AllowColumnReorder = $true
  $lvList2.Columns.AddRange(@($chCol_3, $chCol_4, $chCol_5, $chCol_6, $chCol_7, $chCol_8))
  $lvList2.Dock = "Fill"
  $lvList2.FullRowSelect = $true
  $lvList2.MultiSelect = $false
  $lvList2.ShowItemToolTips = $true
  $lvList2.SmallImageList = $imgList
  $lvList2.Sorting = "Ascending"
  $lvList2.View = "Details"
  #
  #chCol_3
  #
  $chCol_3.Text = "Name"
  $chCol_3.Width = 70
  #
  #chCol_4
  #
  $chCol_4.Text = "Origin"
  $chCol_4.Width = 90
  #
  #chCol_5
  #
  $chCol_5.Text = "Type"
  $chCol_5.Width = 70
  #
  #chCol_6
  #
  $chCol_6.Text = "IsLocal"
  $chCol_6.Width = 70
  #
  #chCol_7
  #
  $chCol_7.Text = "IsArray"
  $chCol_7.Width = 70
  #
  #chCol_8
  #
  $chCol_8.Text = "Description"
  $chCol_8.Width = 230
  #
  #imgList
  #
  $img1, $img2, $img3, $img4, $img5 | % {$imgList.Images.Add((Get-ImageFromString $_))}
  #
  #sbStrip
  #
  $sbStrip.Items.AddRange(@($sbLbl_1, $sbLbl_2, $sbLbl_3, $sbLbl_4))
  #
  #sbLbl_X
  #
  $sbLbl_1, $sbLbl_2, $sbLbl_3, $sbLbl_4 | % {$_.AutoSize = $true}
  $sbLbl_2.ForeColor = "DarkBlue"
  $sbLbl_3, $sbLbl_4 | % {$_.ForeColor = "DarkMagenta"}
  #
  #frmMain
  #
  $frmMain.ClientSize = New-OBject Drawing.Size(800, 600)
  $frmMain.Controls.AddRange(@($scSplt1, $sbStrip, $mnuMain))
  $frmMain.Icon = $ico
  $frmMain.MainMenuStrip = $mnuMain
  $frmMain.StartPosition = "CenterScreen"
  $frmMain.Text = "WMI Explorer"
  $frmMain.Add_Load($frmMain_Load)
  
  [void]$frmMain.ShowDialog()
}

function frmInfo_Show {
  $frmInfo = New-Object Windows.Forms.Form
  $pbImage = New-Object Windows.Forms.PictureBox
  $lblName = New-Object Windows.Forms.Label
  $lblCopy = New-Object Windows.Forms.Label
  $btnExit = New-Object Windows.Forms.Button
  #
  #pbImage
  #
  $pbImage.Image = $ico.ToBitmap()
  $pbImage.Location = New-Object Drawing.Point(16, 16)
  $pbImage.Size = New-Object Drawing.Size(32, 32)
  $pbImage.SizeMode = "StretchImage"
  #
  #lblName
  #
  $lblName.Font = New-Object Drawing.Font("Microsoft Sans Serif", 9, [Drawing.FontStyle]::Bold)
  $lblName.Location = New-Object Drawing.Point(53, 19)
  $lblName.Size = New-Object Drawing.Size(360, 18)
  $lblName.Text = "WMI Explorer v2.03"
  #
  #lblCopy
  #
  $lblCopy.Location = New-Object Drawing.Point(67, 37)
  $lblCopy.Size = New-Object Drawing.Size(360, 23)
  $lblCopy.Text = "(C) 2013 greg zakharov forum.script-coding.com"
  #
  #btnExit
  #
  $btnExit.Location = New-Object Drawing.Point(135, 67)
  $btnExit.Text = "OK"
  #
  #frmInfo
  #
  $frmInfo.AcceptButton = $btnExit
  $frmInfo.CancelButton = $btnExit
  $frmInfo.ClientSize = New-Object Drawing.Size(350, 110)
  $frmInfo.ControlBox = $false
  $frmInfo.Controls.AddRange(@($pbImage, $lblName, $lblCopy, $btnExit))
  $frmInfo.FormBorderStyle = "FixedSingle"
  $frmInfo.ShowInTaskBar = $false
  $frmInfo.StartPosition = "CenterParent"
  $frmInfo.Text = "About..."
  $frmInfo.Add_Load($frmInfo_Load)

  [void]$frmInfo.ShowDialog()
}

frmMain_Show
