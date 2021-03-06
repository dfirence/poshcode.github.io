# Start of Settings
$VC1 = "VI server"
# Max CPU usage for non HA cluster
$limitResourceCPUClusNonHA = 0.6 
# Max MEM usage for non HA cluster
$limitResourceMEMClusNonHA = 0.6 
# End of Settings

function Write-CustomOut ($Details){
	$LogDate = Get-Date -Format T
	Write-Host "$($LogDate) $Details"
	#write-eventlog -logname Application -source "Windows Error Reporting" -eventID 12345 -entrytype Information -message "Quick-capacity-check: $Details"
}

# Adding PowerCLI core snapin
if (!(get-pssnapin -name VMware.VimAutomation.Core -erroraction silentlycontinue)) {
	add-pssnapin VMware.VimAutomation.Core
}
	
Write-CustomOut "Connecting to VI Server"

$VIConnection = Connect-VIServer $VC1
if (-not $VIConnection.IsConnected) {
	Write-Host "Unable to connect to vCenter, please make sure you have entered/updated the vCenter server address correctly "
	Write-Host " to specify a username and password edit the connection string in this file at $VIConnection$"
	break
}

Write-CustomOut "Collecting Detailed Cluster Resources"

$clusviews = Get-View -ViewType ClusterComputeResource


$capacityinfo = @()
foreach ($cluv in ($clusviews | Sort Name)) {
		$clucapacity = "" |Select ClusterName, "Estimated VMs Left (Based on CPU)", "Estimated VMs Left (Based on MEM)", "vCPU/pCPU ratio", "VM/VMHost ratio"
		if ( $cluv.Configuration.DasConfig.Enabled -eq $true ) {
			$DasRealCpuCapacity = $cluv.Summary.EffectiveCpu - (($cluv.Summary.EffectiveCpu * $cluv.Configuration.DasConfig.FailoverLevel)/$cluv.Summary.NumEffectiveHosts)
			$DasRealMemCapacity = $cluv.Summary.EffectiveMemory - (($cluv.Summary.EffectiveMemory * $cluv.Configuration.DasConfig.FailoverLevel)/$cluv.Summary.NumEffectiveHosts)
		} else {
			$DasRealCpuCapacity = $cluv.Summary.EffectiveCpu * $limitResourceCPUClusNonHA
			$DasRealMemCapacity = $cluv.Summary.EffectiveMemory * $limitResourceMEMClusNonHA
		}
		
		$cluvmlist = (Get-Cluster $cluv.name|Get-VM)
		
		#CPU
			$CluCpuUsage = (get-view $cluv.ResourcePool).Summary.runtime.cpu.OverallUsage
		$CluCpuUsageAvg = $CluCpuUsage
		if ($cluvmlist -and $cluv.host -and $CluCpuUsageAvg -gt 0){
			$VmCpuAverage = $CluCpuUsageAvg/(Get-Cluster $cluv.name|Get-VM).count
			$CpuVmLeft = [math]::round(($DasRealCpuCapacity-$CluCpuUsageAvg)/$VmCpuAverage,0)
		}
		elseif ($CluCpuUsageAvg -eq 0) {$CpuVmLeft = "N/A"}
		else {$CpuVmLeft = 0}
		
	
		#MEM
			$CluMemUsage = (get-view $cluv.ResourcePool).Summary.runtime.memory.OverallUsage
		$CluMemUsageAvg = $CluMemUsage/1MB
		if ($cluvmlist -and $cluv.host -and $CluMemUsageAvg -gt 100){
			$VmMemAverage = $CluMemUsageAvg/(Get-Cluster $cluv.name|Get-VM).count
			$MemVmLeft = [math]::round(($DasRealMemCapacity-$CluMemUsageAvg)/$VmMemAverage,0)
		}
		elseif ($CluMemUsageAvg -lt 100) {$CluMemUsageAvg = "N/A"}
		else{$MemVmLeft = 0}
	
		$clucapacity.ClusterName = $cluv.name
		$clucapacity."Estimated VMs Left (Based on CPU)" = $CpuVmLeft
		$clucapacity."Estimated VMs Left (Based on MEM)" = $MemVmLeft
		if ($cluvmlist){
			$vCPUpCPUratio = [math]::round(($cluvmlist|Measure-Object -Sum -Property NumCpu).sum / $cluv.summary.NumCpuThreads,0)
			$clucapacity."vCPU/pCPU ratio" = $vCPUpCPUratio
		}
		else {$clucapacity."vCPU/pCPU ratio" = "0 (vCPU < pCPU)"}
		if ($cluvmlist){
			$clucapacity."VM/VMHost ratio" = [math]::round(($cluvmlist).count/$cluv.summary.numEffectiveHosts,0)
		}
		else {$clucapacity."VM/VMHost ratio" = 0}

		$capacityinfo += $clucapacity
}

$capacityinfo | Sort ClusterName

# Disconnect vCenter server
Disconnect-VIServer -server "$VC1" -Force -Confirm:$false
