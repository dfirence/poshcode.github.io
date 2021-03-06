<#
.SYNOPSIS
    Drive Space Report

.DESCRIPTION

Drive Space Report
Get-DriveSpace.ps1 [[-computername] <String[]>] [-file <String>] [-Gridview] [-OSOnly] [<CommonParameters>]

Produces a simple drive space report for the computer(s) requested 

.PARAMETER Computername
The computer or list of computers that you want the report generated for. 
if generating the report for multiple computers
separate each computer with a comma.

.PARAMETER File
When used will attempt to read the filename to import list of servers to be tested. 

.PARAMETER OSOnly
Used to provide a report of the OS (C:) drive of the server(s). 
If not specified the report will include all drives on the servers being tested. 

.PARAMETER Gridview
Used to generate the report using powershell's out-gridview option. This will be used for the 
disk space report only. Errors will be displayed on console only. 

.EXAMPLE
Get-Drivespace -Computername computer1

Generates a report for all drives on server computer1

.EXAMPLE
Get-Drivespace -Computername computer1, Computer2 -OSOnly   
    
Generates a drive of the OS drive of Computer 1 and Computer 2
    
.Example
Get-Drivespace 
    
Generates report of local computer

.Example
Get-Drivespace -file c:\somefolder\servers.txt

Will read the contents of c:\somefolder\servers.txt into the command for processing. 
    
.Example
Get-Drivespace (Get-Content servers.txt)
    
This will read the contents of the servers.txt file processing each line as a server name. 
It will pass the list of servers to the command to process each server as if they were 
entered server1, server2, server3... 

#>
#requires -Version 3

#Function Get-Drivespace {
    [cmdletbinding()]
    param (
        [Parameter(
            Position=0, 
            ValueFromPipeline=$true,
            ValueFromPipelineByPropertyName=$true ) ]
            [String[]]$computername = $env:computername,

            [String]$file,

            [switch]$OSOnly,

            [Switch]$Gridview

        ) #param

begin{ 
    Write-Verbose 'Begin'
    [Int]   $i = 0               #Counter for routine
    [Array] $mia  =@()           # Servers failing connectivity test
    [Array] $NIX  =@()           # *NIX servers
    [Array] $svrs =@()           # Servers with disk information
    [Array] $errsvrs =@()        # servers that experience errors in gathering
    [Int]   $computerstested = 0 # Count of computers tested
    [float] $levelWarn  = 10.0;  # Warning-level in percent. 
    [float] $levelAlarm = 5.0;   # Alarm-level in percent. 

    if ($file) {
        Write-Verbose "`t Input from file selected"
        if (Test-Path $file){
            Write-Progress -Activity 'Reading in list of servers' -status 'Yawning'
            $computername = Get-Content $file

            }#if test-path
            else{
                Write-Error "$file is not found in path. Please check and rerun"
                break
                }#else if test-path
        }#if $file
    }#Begin

process {
    Write-Verbose "Process"
    $numbercomp = $computername.count
    
    Write-Verbose "`t number of computers $numbercomp"
     $i=1

    foreach ($computer in $computername){
        #Write-Verbose "`t `t $computer"
        Write-Progress -Activity "Getting drive information" -Status $computer -PercentComplete (($i/$computername.count)*100)
        $computerstested ++
        $i++

        If ($computer -Like "U*"){
            Write-Verbose "`t `t *NIX computer"
            $NIX +=$computer
            }#*NIX test
          Else {

            if (Test-Connection $computer -Count 1 -ErrorAction 0 -Quiet){
              <#
              Yes? Gather Drive information about the server
              #>
              Try {
                  $Drive= Get-WmiObject Win32_LogicalDisk -computer $computer -ErrorAction Stop  |Where-Object {($_.Drivetype -ne 2) -and ($_.Drivetype -ne 5) }|`
                      select SystemName,DeviceID, VolumeName, DriveType, FileSystem,`
                      @{Name="Size(GB)";Expression={"{0:N1}" -f($_.size/1gb)}},`
                      @{Name="FreeSpace(GB)";Expression={"{0:N1}" -f($_.freespace/1gb)}}, `
                      @{name="% Free";Expression={ "{0:N1}" -f (($_.FreeSpace / $_.Size)*100)}},`
            
                      @{Name="Alarm";Expression={if (($_.FreeSpace / $_.Size)*100 -le $levelAlarm)
                                                        {"Alarm !!!"}  
                                                 elseif (($_.FreeSpace / $_.Size)*100 -le $levelWarn) 
                                                        {"Warning !"} 
                                                   else
                                                        {$null}
                                                    }#Alarm IF
                                                }#Alarm
            
            
                  $svrs += $Drive
                }#try 
                Catch {
                    Write-Verbose "`t `t Error Computer $computer"
                    $errsvrs += $computer
                    }#Catch
                finally{} #Finally
            }#if test-connection
            else {
                    $MIA += $computer   
                 }#Else if test-connection
             }#Else if Nix test 
    }#Foreach
 

    }#Process


end {
    Write-Verbose "End"
    
    if ($OSOnly) {
        Write-Verbose "`t OSOnly Switch set"
        [Array]$OSDrive=@()
        foreach ($s in $svrs){
            if ($s.deviceid -eq 'C:'){
                $osdrive +=$s }#if
         }#foreach
         if ($Gridview){
	        Write-Verbose "`t Gridview Output Selected"
            $osdrive | out-gridview
            }#IF 
         Else {
            $osdrive | Sort  alarm, "% Free" |ft -AutoSize
            }#IF-Else
        }#if $osonly
        else{
            if ($Gridview){
				Write-Verbose "`t Gridview Output Selected"
                $svrs | out-gridview
                }#IF
             Else{
                $svrs | ft -auto
                }#if-Else
            }#else if $osonly

    <#Error Reports#>
    Write-host "$computerstested Computers tested"
    if ($mia -ne $null){
        #write-host "The following servers are offline" -ForegroundColor Red
        $n = $mia.count
        $m = "{0:N1}" -f (($mia.count / $computerstested)*100)
        Write-Host "$n servers are offline $m %"  -ForegroundColor Yellow
        foreach ($m in $MIA) {
		    Write-Host "`t $m is not on network " -ForegroundColor Yellow
            }#foreach
            
        }#if $MIA
    if ($errsvrs -ne $null){
        $n=$errsvrs.count
        $m="{0:N1}" -f (($errsvrs.count / $computerstested)*100)
        Write-Host "$n servers have errors $M %" -ForegroundColor Red
        foreach ($E in $errsvrs) {		
		    Write-Host "`t $E Has errors Please investigate" -ForegroundColor Red
            }#ForEach
        }#if $errsvrs

    if ($nix -ne $null){ 
        $n=$nix.count
        $m="{0:N1}" -f (($nix.count / $computerstested)*100)
        Write-Host "$n Nix Computers $M %" -ForegroundColor Magenta
        Write-host "`t $nix" -ForegroundColor Magenta
        }#$IF *NIX
}#end


#}#Function Get-Drivespace


<#Test code section#>
#Get-DriveSpace -file C:\powershell\elhr\elkr45.txt -verbose -OSOnly
#Get-DriveSpace -file C:\powershell\elhr\elkr45.txt -OSOnly
#Get-DriveSpace -file ..\servers.txt -OSOnly -Gridview
#Get-DriveSpace ut00004p, uv000137p, abtapt0902, abtapp1900 -verbose

<#
Versioning
        0.0	  mm/dd/yy		Wouldn't it be a good idea to take a simple WMI command and complicate things. You can do things like 
                            calculate the percentage of free space. 
                            show the space in Gb and not a bunch of numbers
                            start writing error routines (get the red out)
                            Make a nice report that can be added to server checkout
		0.1	  04/2014		Added the calculation for percent free
		0.2	  04/03/2014	Added test of input paramater for assigning sernames & list
							Created loop for input 
		0.3	  04/05/2014	Added test for computer up (need to create report)
        0.31  05/30/2014  	Created end report for servers not online.
        0.4   06/09/2014  	Add Alarm settings for low disk space
        0.41  07/09/2014  	Created disk report
        0.5   08/04/2014  	New check online test
        1.0   03/2015     	Rewrite to include enhanced parameter usage and structured code.  
              03/01/2015  	Switch for OS Only 
                            - Sort the alarms in the OSOnly view
        1.01  04/08/2015  	Procedure for handling input from file better. 
		1.02  04/10/2015  	Created gridview output
        1.03  05/29/2015    Check for *NIX computers
		
NEEDS 
	Better reporting of errors. display what the error is when the system fails. 
	look for better way to do gridview
	Better output options. HTML / File / gridview / csv
	Piping output ??
   
#>
