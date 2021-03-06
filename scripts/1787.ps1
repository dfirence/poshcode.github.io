function Reset-Tray {
   Add-Type -Assembly UIAutomationClient

   $Window = Add-Type -Name ([char[]](65..90 | Get-Random -count 10) -join "") -Member @"
   [DllImport("user32")]
   public static extern IntPtr PostMessage(IntPtr hWnd, UInt32 Msg, Int32 wParam, Int32 lParam);

   public static void SendMouseMove(IntPtr hWnd, ushort x, ushort y) {
      int point = (y << 16) + x;
      PostMessage(hWnd, 0x200, 0, point);
   } 
"@ -Passthru 


   $tray = [System.Windows.Automation.AutomationElement]::RootElement.FindAll( "Descendants" , [System.Windows.Automation.Condition]::TrueCondition ) | 
           Where { $_.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::ClassNameProperty) -like "SysPager" } | 
           ForEach { $_.FindAll( "Children" , [System.Windows.Automation.Condition]::TrueCondition ) } |
           Where { $_.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::NameProperty) -like "*Notification Area" }

   $handle = $tray.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::NativeWindowHandleProperty)
   $rect = $tray.GetCurrentPropertyValue([System.Windows.Automation.AutomationElement]::BoundingRectangleProperty) 
   $y = $rect.Height/2
   for ( $x = 0; $x -lt $rect.Width; $x += 8) {
      $Window::SendMouseMove( $handle, $x, $y )
   }
}

