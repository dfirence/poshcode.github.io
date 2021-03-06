$window = show -minw 300 -minh 300 -width 400 -height 400  -AllowsTransparency -WindowStyle none -Background transparent { 
   grid { 
      viewbox -stretch Uniform { 
         Path -Fill "#80D0E0FF" -stroke red -strokethickness 4 `
              -horizontalalign center -verticalalign center `
              -data "M79,3L65,82 17,91 50,138 96,157 104,192 175,154 190,167 218,78 156,76 157,9 111,39z" 
      }
      Button -Margin 150 "Click Me" 
   }
} -On_MouseLeftButtonDown { 
   $this.DragMove() 
} -On_Deactivated { 
   $this.Opacity = .5
} -On_Activated {
   $this.Opacity = 1
} -async -passthru 

## Later, you can mess with the window in various ways from the host, because we did -async -passthru:
invoke-uiwindow $window { $this.Opacity = 1 }


