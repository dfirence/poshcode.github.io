$ErrorLogFilePreference = "c:\err.txt"


function Get-SystemInfo {
<#
.SYNOPSIS
Gets system info.
.DESCRIPTION
This gets system info.
.PARAMETER ComputerName
A computer name.
.EXAMPLE
Get-SystemInfo -ComputerName WHATEVER
This example gets system info from the computer 'WHATEVER'
#> 
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [ValidateLength(2,5)]
        [string[]]$ComputerName,

        [string]$ErrorLogFile = $ErrorLogFilePreference
    )
    BEGIN {}
    PROCESS {
        foreach ($computer in $computername) {
            try {
                $os = Get-CimInstance -ErrorAction Stop -ClassName Win32_OperatingSystem -ComputerName $Computer
                $comp = Get-CimInstance -ClassName Win32_ComputerSystem -ComputerName $Computer
                $bios = Get-CimInstance -ClassName Win32_BIOS -ComputerName $Computer
                $proc = Get-CimInstance -ClassName Win32_Processor -ComputerName $Computer |
                    Select-Object -First 1

                $properties = @{'ComputerName'=$Computer;
                            'OSVersion'=$os.Version;
                            'SPVersion'=$os.ServicePackMajorVersion;
                            'OSArchitecture'=$os.OSArchitecture;
                            'ProcArchitecture'=$proc.addresswidth;
                            'Manufacturer'=$comp.Manufacturer;
                            'Model'=$comp.model;
                            'BIOSSerial'=$bios.SerialNumber;
                            'RAM'=$comp.TotalPhysicalMemory}
                $object = New-Object -TypeName PSObject -Property $properties
                Write-Output $object
            } catch {
                Write-Warning "OMG, $computer FAIL!!!!"
                Write-Verbose "Logged error to $ErrorLogFile"
                $computer | out-file $ErrorLogFile -append
            }
        } #foreach
    } #PROCESS
    END {}
} #function


function Get-DiskInfo {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [string[]]$ComputerName
    )
    BEGIN {}
    PROCESS {
        foreach ($comp in $computername) {
            try {
                Write-Verbose "Now attempting $comp"
                $params = @{'ComputerName'=$Comp;
                            'ClassName'='Win32_LogicalDisk';
                            'Filter'="DriveType=3";
                            'ErrorAction'='Stop'}
                $disks = Get-CimInstance @params #that's called splatting

                foreach ($disk in $disks) {

                    Write-Verbose "Working on $($disk.deviceid)"
                    $properties = @{'ComputerName'=$comp;
                                    'Drive'=$disk.DeviceID;
                                    'FreeSpace'=$disk.FreeSpace;
                                    'Size'=$disk.Size;
                                    'FreePercent'=($disk.FreeSpace / $disk.Size * 100 -as [int])}
                    $object = New-Object -TypeName PSObject -Property $properties
                    Write-Output $object
                } #foreach disk
            } catch {
                Write-Warning "$comp FAILED"
                $comp | out-file $ErrorLogFilePreference -append
            }
        } #foreach computer
    } #process
    END {}
} #function



function Set-ComputerState {
    [CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='High')]
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True)]
        [string[]]$ComputerName,

        [Parameter(Mandatory=$True)]
        [ValidateSet('PowerOff','LogOff','Restart','Shutdown')]
        [string]$State,

        [switch]$force
    )
    PROCESS {
        switch ($state) {
            'PowerOff' { $arg = 8 }
            'LogOff' { $arg = 0 }
            'Shutdown' { $arg = 1 }
            'Restart' { $arg = 2 }
        }
        if ($force) { $arg += 4 }

        foreach ($comp in $ComputerName) {
            if ($PSCmdlet.ShouldProcess("$state on $comp")) {
                $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $comp
                $os.Win32Shutdown($arg)
            } #if
        } #foreach
    }
} #function


Export-ModuleMember -Variable ErrorLogFilePreference -Function Get-SystemInfo
