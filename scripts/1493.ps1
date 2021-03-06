

## Update all fast running (1 minute) timerjobs to run onece every 30+ minutes instead 
## Jos Verlinde 
## Version 1 - Sharepoint 2010 B2 

$Jobs = @(Get-SPTimerJob | Where-Object { $_.Schedule.Interval -le 5 -and $_.Schedule.Description -eq "Minutes" })
if ( $Jobs.count -GT 0 ) {
    ## Add 30 mintues to all these timerjobs
    foreach ($job in $Jobs) { 
        Write-Host -foregroundcolor green $job.name
        
        $Sched = $job.Schedule
        $Sched.Interval= $Sched.Interval+30 
        $job.Schedule=$Sched
        $job.Update()
    }

    Get-SPTimerJob | Where-Object {  $_.Schedule.Description -eq "Minutes" }
} else {
    Write-Host -foregroundcolor green "No fast running timerjobs found"
}

