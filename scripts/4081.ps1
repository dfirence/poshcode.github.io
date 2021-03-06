$frmMain_Load= {
  for ($i = 0; $i -lt 2; $i++) {
    for ($j = 0; $j -lt 5; $j++) {
      $num[$i, $j] = $i * 5 + $j + 1
      $btn[$i, $j] = New-Object Windows.Forms.Button
      #
      #btnX
      #
      $btn[$i, $j].Font = New-Object Drawing.Font("Tahoma", 14, [Drawing.FontStyle]::Bold)
      $btn[$i, $j].Left = $j * 50 + 10
      $btn[$i, $j].Parent = $frmMain
      $btn[$i, $j].Size = New-Object Drawing.Size(50, 50)
      $btn[$i, $j].Text = $(if ($num[$i, $j] -eq 10) {'0'} else {$num[$i, $j]})
      $btn[$i, $j].Top = $i * 50 + 5
    }#for
  }#for
}

function frmMain_Show {
  Add-Type -AssemblyName System.Windows.Forms
  [Windows.Forms.Application]::EnableVisualStyles()

  $btn = New-Object "Windows.Forms.Button[,]" 2, 5
  $num = New-Object "int32[,]" 2, 5

  $frmMain = New-Object Windows.Forms.Form
  #
  #frmMain
  #
  $frmMain.ClientSize = New-Object Drawing.Size(270, 110)
  $frmMain.FormBorderStyle = "FixedSingle"
  $frmMain.MaximizeBox = $false
  $frmMain.StartPosition = "CenterScreen"
  $frmMain.Text = "Form1"
  $frmMain.Add_Load($frmMain_Load)

  [void]$frmMain.ShowDialog()
}

frmMain_Show
