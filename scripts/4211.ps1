function Get-Temperature {
  # .Link http://cdiac.ornl.gov/epubs/ndp/ushcn/monthly_doc.html
[CmdletBinding()]
param(
	# From http://cdiac.ornl.gov/ftp/ushcn_v2.5_monthly/ushcn2012_tob_tmax.txt.gz
	$maxTemps = "~\Downloads\ushcn2012_tob_tmax.txt",
	# From http://cdiac.ornl.gov/ftp/ushcn_v2.5_monthly/ushcn2012_tob_tmin.txt.gz
	$minTemps = "~\Downloads\ushcn2012_tob_tmin.txt",
  # From http://cdiac.ornl.gov/ftp/ushcn_v2.5_monthly/ushcn-stations.txt
	$StationID = 307167,

  $Years = 5
)

  $max = Select-String USH0+$StationID $maxTemps | % line
  $min = Select-String USH0+$StationID $minTemps | % line

  if($max.Count -ne $min.Count) {
    Write-Warning "TODO: write code to throw away years until we get data in both files."
  }

  $temps = @{}
  foreach($y in (-$Years)..-1) {
    $Year = [int]$max[$y].Substring(12,4)
    $temps.$Year = @{}
    Write-Verbose "$Year $($temps.$Year.GetType().FullName)"
    foreach($Month in 1..12){ 
      Write-Verbose "$Year-$Month"
      $temps.$year.$Month = @{
        "Max" = .1 * [int]$max[$y].Substring((8+($month*9)),5)
        "Min" = .1 * [int]$min[$y].Substring((8+($month*9)),5)
      }
    }
  }
  $temps
}
