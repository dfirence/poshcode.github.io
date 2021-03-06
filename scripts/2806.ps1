New-UIWidget -AsJob -Content { 
    $shadow = DropShadowEffect -Color Black -Shadow 0 -Blur 8
   Grid {
      Ellipse -Fill Transparent -Stroke Black -StrokeThickness 4  -Width 300 -Height 300 
      Ellipse -Fill Transparent -Stroke Black -StrokeThickness 6  -Width 290 -Height 290 -StrokeDashArray 1,11.406
      Ellipse -Fill Transparent -Stroke Black -StrokeThickness 10 -Width 280 -Height 280 -StrokeDashArray 64.25
      Ellipse -Fill Transparent -Stroke Black -StrokeThickness 5  -Width 255 -Height 255 -StrokeDashArray 60,59
      Ellipse -Name Hour -Fill Transparent -Stroke White -StrokeThickness 100 -Width 255 -Height 255 -StrokeDashArray 0.04,300 -RenderTransformOrigin "0.5,0.5" -RenderTransform { RotateTransform -Angle -90 } -Effect $shadow 
      Ellipse -Name Minute -Fill Transparent -Stroke '#FFC0B7B7' -StrokeThickness 100 -Width 275 -Height 275 -StrokeDashArray 0.05,300 -RenderTransformOrigin "0.5,0.5" -RenderTransform { RotateTransform -Angle -90 } -Effect $shadow 
      Ellipse -Name Second -Fill Transparent -Stroke '#FF31C2FF' -StrokeThickness 100 -Width 215 -Height 215 -StrokeDashArray 0.02,300 -RenderTransformOrigin "0.5,0.5" -RenderTransform { RotateTransform -Angle -90 } -Effect $shadow 
    }
} -Refresh "00:00:00.2" -Update { 
   $now = Get-Date
   $deg = (1/60) * 360
   
   $Hour.RenderTransform.Angle = $now.Hour * 5 * $deg -90
   $Minute.RenderTransform.Angle = $now.Minute * $deg -90
   $Second.RenderTransform.Angle = $now.Second * $deg -90
}
