## Watch-Process.ps1
## Continuously display a process list, sorted
## by the desired criteria.
##
## usage: poll-process [sortCriteria] [pollInterval]
##
## sortCriteria must be one of "Id", "ProcessName", "MainWindowTitle", 
##                              "Processor", "Disk", or "WorkingSet"
## pollInterval is specified in milliseconds
##
param(
    [string] $sortCriteria = "Processor",
    [int] $pollInterval = 750
    )


## As a heuristic, gets the total IO and Data operations per second, and
## returns their sum.
function get-diskActivity (
    $process = $(throw "Please specify a process for which to get disk usage.")
    )
{
    $processName = get-processName $process
    
    ## We store the performance counter objects in a hashtable.  If we don't,
    ## then they fail to return any information for a few seconds.
    if(-not $ioOtherOpsPerfCounters[$processName])
    {
        $ioOtherOpsPerfCounters[$processName] = `
            new-object System.Diagnostics.PerformanceCounter `
                "Process","IO Other Operations/sec",$processName
    }
    if(-not $ioOtherBytesPerfCounters[$processName])
    {
        $ioOtherBytesPerfCounters[$processName] = `
            new-object System.Diagnostics.PerformanceCounter `
                "Process","IO Other Bytes/sec",$processName
    }
    if(-not $ioDataOpsPerfCounters[$processName])
    {
        $ioDataOpsPerfCounters[$processName] = `
            new-object System.Diagnostics.PerformanceCounter `
                "Process","IO Data Operations/sec",$processName
    }
    if(-not $ioDataBytesPerfCounters[$processName])
    {
        $ioDataBytesPerfCounters[$processName] = `
            new-object System.Diagnostics.PerformanceCounter `
                "Process","IO Data Bytes/sec",$processName
    }


    ## If a process exits between the time we capture the processes and now,
    ## then we will be unable to get its NextValue().  This trap simply
    ## catches the error and continues.
    trap { continue; }

    ## Get the performance counter values
    $ioOther = (100 * $ioOtherOpsPerfCounters[$processName].NextValue()) + `
        ($ioOtherBytesPerfCounters[$processName].NextValue())
    $ioData = (100 * $ioDataOpsPerfCounters[$processName].NextValue()) + `
        ($ioDataBytesPerfCounters[$processName].NextValue())
    
    return [int] ($ioOther + $ioData)    
}

## Get the percentage of time spent by a process.
## Note: this is multiproc "unaware."  We need to divide the
## result by the number of processors.
function get-cpuPercent (
    $process = $(throw "Please specify a process for which to get CPU usage.")
    )
{
    $processName = get-processName $process
    
    ## We store the performance counter objects in a hashtable.  If we don't,
    ## then they fail to return any information for a few seconds.
    if(-not $cpuPerfCounters[$processName])
    {
        $cpuPerfCounters[$processName] = `
            new-object System.Diagnostics.PerformanceCounter `
                "Process","% Processor Time",$processName
    }

    ## If a process exits between the time we capture the processes and now,
    ## then we will be unable to get its NextValue().  This trap simply
    ## catches the error and continues.
    trap { continue; }

    ## Get the performance counter values
    $cpuTime = ($cpuPerfCounters[$processName].NextValue() / $env:NUMBER_OF_PROCESSORS)
    return [int] $cpuTime
}

## Performance counters are keyed by process name.  However,
## processes may share the same name, so duplicates are named
## <process>#1, <process>#2, etc.
function get-processName (
    $process = $(throw "Please specify a process for which to get the name.")
    )
{
    ## If a process exits between the time we capture the processes and now,
    ## then we will be unable to get its information.  This simply
    ## ignores the error.
    $errorActionPreference = "SilentlyContinue"

    $processName = $process.ProcessName
    $localProcesses = get-process -ProcessName $processName | sort Id
    
    if(@($localProcesses).Count -gt 1)
    {
        ## Determine where this one sits in the list
        $processNumber = -1
        for($counter = 0; $counter -lt $localProcesses.Count; $counter++)
        {
            if($localProcesses[$counter].Id -eq $process.Id) { break }
        }
        
        ## Append its unique identifier, if required
        $processName += "#$counter"
    }
    
    return $processName
} 


    ## Store the performance counters we need
    ## for the CPU, and Disk I/O numbers
    $cpuPerfCounters = @{}
    $ioOtherOpsPerfCounters = @{}
    $ioOtherBytesPerfCounters = @{}
    $ioDataOpsPerfCounters = @{}
    $ioDataBytesPerfCounters = @{}
    $processes = $null
    $lastPoll = get-date
    
    $lastSnapshotCount = 0
    $lastWindowHeight = 0
    
    ## The coordinates to which we position the output
    $coords = new-object System.Management.Automation.Host.Coordinates 0,0
    clear-host

    while(-not $host.UI.RawUI.KeyAvailable)
    {
        ## Set the cursor position, get the processes, and store
        ## the time of the snapshot
        $host.UI.RawUI.CursorPosition = $coords
        $processes = get-process | sort Id

        ## Go through all of the processes we captured
        foreach($process in $processes)
        {
            ## Get the disk activity, based on I/O Perf Counters,
            ## for the process in question.  Then, add it as a note.
            $activity = get-diskActivity $process
            $process | add-member NoteProperty Disk $activity

            $cpuPercent = get-cpuPercent $process
            $process | add-member NoteProperty Processor $cpuPercent
         }

        $windowHeight = $host.Ui.RawUi.WindowSize.Height
        ## Since clear-host makes the screen flash, we only do so when
        ## we have fewer processes than we did the last time
        if(($processes.Count -lt $lastSnapshotCount) -or `
            (-not ($lastWindowHeight -eq $windowHeight)))
        { 
            clear-host 
        }
        
        ## Tailor the length of the list to the height of the 
        ## window.  If the window is to short, show no output.
        if($windowHeight -le 7) 
        { 
            $output = $null 
        }
        else 
        {
            $output = $processes | sort -desc $sortCriteria | `
                select-object -First ($windowHeight - 7)
        }
        
        ## Display the results
        $output | format-table Id,ProcessName,MainWindowTitle,Processor,Disk,WorkingSet
        
        if($processes.Count -gt ($windowHeight - 7))
        {
            $notDisplayed = ($processes.Count - $output.Count)
            "[ $notDisplayed process(es) not shown ]"
        }
        
        $lastSnapshotCount = $processes.Count
        $lastWindowHeight = $windowHeight
        
        ## Sleep for their desired amount of elapsed time,
        ## adjusted for how much time we've actually spent working.
        $elapsed = [int] (get-date).Subtract($lastPoll).TotalMilliseconds
        $lastPoll = get-date
        if($pollInterval -gt $elapsed)
        { 
            start-sleep -m ($pollInterval - $elapsed)
        }
    }

