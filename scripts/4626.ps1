#Requires -version 3
 
function Start-TransportLogSearch
{
        <#
        .Synopsis
        Searches one or more Exchange transport logs and sends the output to XML.
       
        .DESCRIPTION
        Creates a PowerShell job for each Exchange transport server to be searched and
        that job searches based onteh parameters defined in the search.  
       
        The output is exported as XML to the path defined.  By default only 4 jobs
        run at a time.  As jobs complete additional jobs are submitted.
               
        .PARAMETER ComputerName
        One or more computer names (Exchange transort servers) to search.
               
        .PARAMETER Start
        The start time of the search
               
        .PARAMETER End
        The end time of the search
               
        .PARAMETER Sender
        Return results where the sender matches this address
               
        .PARAMETER Recipient
        Return results for e-mail addressed to the recipient provided.
               
        .PARAMETER EventId
        The eventId of the tracking event to match.
               
        .PARAMETER Threshold
        How many transport jobs to spawn at one time.
       
        .PARAMETER Path
        Where to create the resulting XML files.  The default is the current working directory.
               
        .EXAMPLE
        Start-TransportLogSearch -ComputerName server01a,server01b,server01c -Start (get-date "08/01/2013 00:00") -end (get-date 08/02/2013 "00:00") -EventId RECEIVE -Sender 'bill@microsoft.com'
       
        This starts 3 PowerShell jobs that run in parallel that searches for all mail with the
        eventId of RECEIVE that was submitted by Mr. Gates 08/01/2013 through 08/02/2013.
               
        .EXAMPLE
        $start     = (get-date).addDays(-3)
        $end       = (get-date)
        $recipient = 'john_smith@contoso.com'
        $path      = 'c:\Temp\ExchangeLogs'
        Get-TransportServer | Start-TransportLogSearch -start $start -end $end -recipient $recipient -Path $path
       
        This starts a transport log search against all transport servers in the Exchange organization for mail addressed to
        john_smith@contoso.com that has been submitted over the past 3 days.  Each job that is spawned will generate an XML
        file that will be deposited in c:\Temp\ExchangeLogs that can be processed later.
        #>
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                                ValueFromPipeline=$true,       
                Position=0)]
        [Alias('Identity')]
        [String[]]$ComputerName,
 
        [Parameter(Mandatory=$false,
                                ValueFromPipelineByPropertyName=$false,
                                Position=1)]
        [datetime]$Start = $(get-date).addHours(-1),
 
        [Parameter(Mandatory=$false,
                                ValueFromPipelineByPropertyName=$false,
                                Position=2)]
        [datetime]$End = $(Get-Date),
 
        [Parameter(Mandatory=$false,
                                ValueFromPipelineByPropertyName=$false,
                                Position=3)]
        [String]$Sender = $null,
 
        [Parameter(Mandatory=$false,
                                ValueFromPipelineByPropertyName=$false,
                                Position=4)]
        [String]$Recipient = $Null,
 
        [Parameter(Mandatory=$false,
                                ValueFromPipelineByPropertyName=$false,
                                Position=5)]
                        [ValidateSet("BADMAIL","DEFER","DELIVER","DSN","EXPAND","FAIL","PROCESS","RECEIVE","RESOLVE","SEND","TRANSFER")]
        [String]$EventId = 'RECEIVE',
 
        [Parameter(Mandatory=$false,
                                ValueFromPipelineByPropertyName=$false,
                                Position=6)]
        [int]$Threshold = 4,
 
        [Parameter(Mandatory=$false,
                                ValueFromPipelineByPropertyName=$false,
                                Position=6)]
        [String]$Path = (Get-Location).Path
    )
 
    Begin
    {
        #Code to run within the job.
        $openScriptBlock = {
            param($serverName,$start,$End,$Sender,$Recipient,$EventId)
                       
                        Function Connect-ExchangeServer
                        {
                                [CmdletBinding()]
                                [OutputType([PSObject])]
                                Param
                                (
                                #Computer name to connect to.
                                [Parameter(Mandatory=$true,
                                        ValueFromPipelineByPropertyName=$false,
                                        Position=0)]
                                        [Alias('Identity')]
                                $ComputerName,
                               
                                #Computer name to connect to.
                                [Parameter(Mandatory=$false,
                                        ValueFromPipelineByPropertyName=$false,
                                        Position=1)]
                                [String[]]$Commands    
                                )
 
                            $sessionParam = @{
                                ConfigurationName = 'Microsoft.Exchange'
                                ConnectionUri     = "http://$ComputerName/PowerShell/"
                                Authentication    = 'Kerberos'
                                ErrorAction       = 'STOP'
                                }      
 
                                Try
                                {
                                        $psSession = New-PSSession @sessionParam               
                                }
                                # Catch specific types of exceptions thrown by one of those commands
                                Catch
                                {
                                        Write-Warning -Message ("[{0}]There was an error creating the PSSession: {1}" -f $ComputerName,$_.exception.message)
                                        return
                                }      
 
 
                                $sessionImport = @{
                                        Session             = $psSession
                                        AllowClobber        = $true
                                        ErrorAction         = 'STOP'
                                        }      
                               
                                if ($Commands)
                                {
                                        $Commands += 'Set-ADServerSettings'
                                        $sessionImport.Add('CommandName',$Commands)
                                }
 
                                Try
                                {
                                        Import-Module (Import-PSSession @sessionImport) -Global -DisableNameChecking
                                }
                                # Catch specific types of exceptions thrown by one of those commands
                                Catch
                                {
                                        Write-Warning -Message ("[{0}]Could not complete import: {1}" -f $ComputerName,$_.exception.message)
                                        return
                                }
 
                        } #END Connect-ExchangeServer
 
 
            Connect-ExchangeServer -ComputerName $serverName -commands Get-MessageTrackingLog                  
                       
            #Parameters to pass to Get-MessageTrackingLog
            $splat = @{
                Server     = $serverName
                Start      = $start
                End        = $end
                EventId    = $EventId
                ResultSize = 'Unlimited'
                }
           
            #If a sender is specified, add that as a parameter.                  
            if($Sender)
            {
                $splat.Add('Sender',$Sender)
            }
 
            #Same thing as a recipient.
            if($Recipient)
            {
                $splat.Add('Recipient',$Recipient)
            }
 
            #Get the data.
            Get-MessageTrackingLog @splat
            }
 
        #Keep track of batches
        $batch = 0
 
        #BatchTime
        [string]$batchTime = get-date -Format hhmmss
    } #END BEGIN
 
    Process
    {
        #Go through each computer\identity and query the logs.
        foreach ($computer in $ComputerName)
        {
            #Check to see if there are any running jobs.  If so wait until the count of
            #running jobes is below the threshold before continuing.
            while ( $(Get-Job -State Running).count -ge $Threshold )
            {
                Write-Verbose -Message "There are $threshold jobs running.  Sleeping."
                Start-Sleep -Seconds 5
            }
 
            #Check to see if there are any completed jobs.  If so export them and clean up.
            if( $(Get-Job -State Completed) )
            {
                foreach ($job in $(Get-Job -State Completed))
                {
                    #Build the file name for the XML file that we'll generate.
                    $timeStamp = Get-Date -Format hhmmss
                    $jobName = $job.Name
                    $XMLPath = Join-Path $path "Batch-$timeStamp-$jobName.xml"
 
                    try
                    {
                        #Get the results of the job and store them as an XML file.
                        Receive-Job -Wait -AutoRemoveJob -id $job.Id -ErrorAction Stop | Export-Clixml -Path $XMLPath -Force -ErrorAction Stop
                    }
                    catch
                    {
                        Write-Warning -Message $("{0} : {1}" -f $computer,$_.exception.message)
                        continue
                    }
 
                    #Keeps memory usage optimal.
                    Write-Verbose -Message "Taking out the garbage"
                    [GC]::Collect()
                }
            }
 
            #Start a new job.
            Write-Verbose -Message $("Processing: {0}" -f $computer)
            Start-Job -Name $computer -ScriptBlock $openScriptBlock -ArgumentList $computer,$Start,$End,$Sender,$Recipient,$EventId | Out-Null
        } #END foreach computer
 
    } #END PROCESS
    End
    {
        #Wait until all running jobs are done and then continue.
        Write-Verbose "Waiting for jobs to finish"
        Get-Job | Wait-Job | out-null
 
        Write-Verbose -Message "Cleaning up remaining jobs."
        foreach ($job in $(Get-Job -State Completed))
        {
            $timeStamp = Get-Date -Format hhmmss
            $jobName = $job.Name
            $XMLPath = Join-Path $path "Batch-$timeStamp-$jobName.xml"
           
            try
            {
                Receive-Job -Wait -AutoRemoveJob -id $job.Id -ErrorAction Stop | Export-Clixml -Path $XMLPath -Force -ErrorAction Stop
            }
            catch
            {
                Write-Warning -Message $("{0} : {1}" -f $computer,$_.exception.message)
                continue
            }
            Write-Verbose -Message "Taking out the garbage"
            [GC]::Collect()
        }
        Write-Verbose -Message "XML files written to $path"
    }
} #END Start-TransportLogSearch
