## du.ps1 Get-DiskUsage
###############################
## Note: $unit can be: kb, mb, gb, or an empty string (to get bytes)
###############################
## -Force causes du to include System ReparsePoints 
##   This means including folders like Vista's ~\Documents\My Pictures (which is a symlink to ~\Pictures)
## -Total forces a final "total" sum row which represents the total for $Path
##
function du {
PARAM($path = "$pwd", [switch]$force, $unit="MB", $round=2, [switch]$total) 
   &{ 
   foreach($dir in (get-childitem $path -force | 
         Where { $_.PSIsContainer -and ($Force -or ($_.Attributes -notmatch "ReparsePoint" -or
                                                    $_.Attributes -notmatch "System"))})) 
   { 
      get-childitem -lit $dir -recurse -force | measure-object -sum -prop Length -EA "SilentlyContinue"  |
         Select-Object @{Name="Path"; Expr={$dir}}, Count, Sum
   } } | Tee-Object -Variable Totals | 
       Select-Object Path, Count, @{Name="Size($unit)"; Expr={[Math]::Round($_.Sum/"1$unit",$round)}} 
   if($total) {
      $totals = $totals | measure-object -Sum -Prop "Count","Sum"
      Get-Item $path | Select @{Name="Path"; Expr={$_}}, 
                              @{Name="Count"; Expr={$totals[0].Sum}}, 
                              @{Name="Size($unit)"; Expr={[Math]::Round((($totals[1].Sum)/"1$unit"),$round)}}
   }
}

