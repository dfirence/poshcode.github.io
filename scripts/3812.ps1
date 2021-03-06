<#
.Synopsis
   Update Sysinternals Suite.
.DESCRIPTION
   Use PowerShell v3's Invoke-WebRequest do download the latest Sysinternals Tools from: http://live.sysinternals.com. Supports -AsJob
.EXAMPLE
   Update-SysinternalsSuite -Path C:\tools\sysinterals
   This Example downloads all sysinternals tools to C:\tools\sysinternals.
.EXAMPLE
   Update-SysinternalsSuite -Path C:\tools\sysinterals -AsJob
   This Example downloads all sysinternals tools to C:\tools\sysinternals, it creates a background job to keep your command line usable!
#>
function Update-SysinternalsSuite
{
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                  SupportsShouldProcess=$true, 
                  ConfirmImpact='Medium')]
    Param
    (
        # Path specifies where to save the tools
        [Parameter(Mandatory=$true, 
                   Position=0,
                   ParameterSetName='Parameter Set 1')]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        $Path,

        # AsJob, start a job
        [Parameter(Mandatory=$false)]
        [switch] 
        $AsJob
    )

    Begin
    {
        # check if folder exists, if not create folder
        if (Test-Path $Path) {
            Write-Verbose "Path exists, updating $Path"
        } else {
            Write-Verbose "Path does not exist, creating folder $path"
            try {
                New-Item -Path $Path -ItemType Directory -ErrorAction Stop
            } catch {
                Write-Error "Could not create Folder"
            }
        }

        # Define Scriptblock
        $myscriptblock = {
            param ($path)
            Invoke-WebRequest -Uri live.sysinternals.com | Select-Object -ExpandProperty Links | 
                ForEach-Object {
                if ($_.href -like '*.exe' -or $_.href -like '*.chm' -or $_.href -like '*.hlp' -or $_.href -like '*.sys' -or $_.href -like '*.txt' -or $_.href -like '*.cnt'){
                    $str = "http://live.sysinternals.com"+$($_.href)
                    Invoke-WebRequest -Uri $str -OutFile $path$($_.href)
                }
                else {
                    Write-Output "Skipped: $($_.href)"
                }
            }
        } # end Scriptblock
        
    }
    Process
    {

        if ($AsJob) {
            Write-Verbose "AsJob is $AsJob - Creating a background job"
            # using -ArgumentList (,$Array) to pass an array to the ScriptBlock
            Start-Job -ScriptBlock $myscriptblock -ArgumentList ($path)
        } else {
            Write-Verbose "AsJob is $AsJob - Running script normally"
            # using -ArgumentList (,$Array) to pass an array to the ScriptBlock
            Invoke-Command -ScriptBlock $myscriptblock -ArgumentList ($path)
        }
    }
    End
    {
    }
}
