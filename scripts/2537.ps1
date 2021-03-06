Function Get-SQLFileSize { 
<#   
.SYNOPSIS   
    Retrieves the file size of a MDF or LDF file for a SQL Server 
.DESCRIPTION 
    Retrieves the file size of a MDF or LDF file for a SQL Server 
.PARAMETER Computer 
    Computer hosting a SQL Server 
.NOTES   
    Name: Get-SQLFileSize 
    Author: Boe Prox 
    DateCreated: 17Feb2011         
.EXAMPLE   
Get-SQLFileSize -Computer Server1 
 
Description 
----------- 
This command will return both the MDF and LDF file size for each database on Server1 
.EXAMPLE   
Get-SQLFileSize -Computer Server1 -LDF 
 
Description 
----------- 
This command will return LDF file size for each database on Server1 
Description 
----------- 
This command will return both the MDF and LDF file size for each database on Server1 
.EXAMPLE   
Get-SQLFileSize -Computer Server1 -MDF 
 
Description 
----------- 
This command will return MDF file size for each database on Server1 
 
#>  
[cmdletbinding( 
    DefaultParameterSetName = 'Default', 
    ConfirmImpact = 'low' 
)] 
    Param( 
        [Parameter( 
            Mandatory = $True, 
            Position = 0, 
            ParameterSetName = '', 
            ValueFromPipeline = $True)] 
            [string[]]$Computer, 
        [Parameter( 
            Mandatory = $False, 
            Position = 1, 
            ParameterSetName = '', 
            ValueFromPipeline = $False)] 
            [switch]$Mdf, 
        [Parameter( 
            Mandatory = $False, 
            Position = 2, 
            ParameterSetName = '', 
            ValueFromPipeline = $False)] 
            [switch]$Ldf                         
        ) 
Begin { 
    If (!($PSBoundParameters.ContainsKey('Mdf')) -AND !($PSBoundParameters.ContainsKey('Ldf'))) { 
        Write-Verbose "MDF or LDF not selected, scanning for both file types" 
        $FileFlag = $True
        $Flag = $False 
        } 
    #Create holder for data 
    Write-Verbose "Creating holder for data" 
    $report = @()
    } 
Process {     
    ForEach ($comp in $Computer) { 
        #Check for server connection 
        Write-Verbose "Testing server connection" 
        If (Test-Connection -count 1 -comp $comp -quiet) { 
            If ($PSBoundParameters.ContainsKey('Mdf') -OR $FileFlag) { 
                Write-Verbose "Looking for MDF file sizes"  
                    Try { 
                        Write-Verbose "Attempting to retrieve counters from server" 
                        $DBDataFile = Get-Counter -Counter '\SQLServer:Databases(*)\Data File(s) Size (KB)' -MaxSamples 1 -comp $comp -ea stop 
                        $DBDataFile.CounterSamples | % { 
                            If ($_.InstanceName -ne "_total") { 
                                $temp = "" | Select Computer, Database, FileType, Size_MB 
                                $temp.Computer = $comp 
                                $temp.Database = $_.InstanceName 
                                $temp.FileType = 'MDF' 
                                $temp.Size_MB = $_.CookedValue/1000 
                                $report += $temp 
                                } 
                            } 
                        } 
                    Catch { 
                        $Flag = $True 
                        }
                    If ($Flag) {                 
                        Try { 
                            Write-Verbose "Attempting to retrieve counters from server" 
                            $DBDataFile = Get-Counter -Counter '\MSSQL$MICROSOFT##SSEE:Databases(*)\Data File(s) Size (KB)' -MaxSamples 1 -comp $comp -ea stop 
                            $DBDataFile.CounterSamples | % { 
                                If ($_.InstanceName -ne "_total") { 
                                    $temp = "" | Select Computer, Database, FileType, Size_MB 
                                    $temp.Computer = $comp 
                                    $temp.Database = $_.InstanceName 
                                    $temp.FileType = 'MDF' 
                                    $temp.Size_MB = $_.CookedValue/1000 
                                    $report += $temp 
                                    } 
                                }             
                            } 
                        Catch { 
                            Write-Warning "$($Comp): Unable to locate Database Counters or Database does not exist on this server"
                            Break
                            }
                        }
                    Else {
                        Write-Warning "$($Comp): Unable to locate Database Counters or Database does not exist on this server"
                        Break
                        } 
                } 
            If ($PSBoundParameters.ContainsKey('Ldf') -OR $FileFlag) {  
                Write-Verbose "Looking for LDF file sizes"                
                    Try { 
                        Write-Verbose "Attempting to retrieve counters from server" 
                        $DBDataFile = Get-Counter -Counter '\SQLServer:Databases(*)\Log File(s) Size (KB)' -MaxSamples 1 -comp $comp -ea stop 
                        $DBDataFile.CounterSamples | % { 
                            If ($_.InstanceName -ne "_total") { 
                                $temp = "" | Select Computer, Database, FileType, Size_MB 
                                $temp.Computer = $comp 
                                $temp.Database = $_.InstanceName 
                                $temp.FileType = 'LDF' 
                                $temp.Size_MB = $_.CookedValue/1000 
                                $report += $temp 
                                } 
                            } 
                        } 
                    Catch { 
                        $Flag = $True  
                        }
                    If ($flag) {                 
                        Try { 
                            Write-Verbose "Attempting to retrieve counters from server" 
                            $DBDataFile = Get-Counter -Counter '\MSSQL$MICROSOFT##SSEE:Databases(*)\Log File(s) Size (KB)' -MaxSamples 1 -comp $comp -ea stop 
                            $DBDataFile.CounterSamples | % { 
                                If ($_.InstanceName -ne "_total") { 
                                    $temp = "" | Select Computer, Database, FileType, Size_MB 
                                    $temp.Computer = $comp 
                                    $temp.Database = $_.InstanceName 
                                    $temp.FileType = 'LDF' 
                                    $temp.Size_MB = $_.CookedValue/1000 
                                    $report += $temp 
                                    } 
                                }             
                            } 
                        Catch { 
                            Write-Warning "$($Comp): Unable to locate Database Counters or Database does not exist on this server"
                            Break
                            }
                        }
                    Else {
                        Write-Warning "$($Comp): Unable to locate Transaction Log Counters or Database does not exist on this server"
                        Break
                        } 
                    } 
            } 
        Else { 
            Write-Warning "$($Comp) not found!" 
            }                
        }         
    } 
End { 
    Write-Verbose "Displaying output" 
    $report 
    }                 
}
