Function Start-UsingLongDirectories
        {
        <#
        .DESCRIPTION
            Allows the use of long paths by mapping PSDrives if the Path is greater than 240 characters
 
            Cycles through ALL child directories of the Path and returns all directories in the shortend format where applicable
 
        .PARAMETER Path
            The root path to obtain all child directories from and shorten if required
        #>
        [cmdletbinding()]
        Param(
        [parameter(Mandatory=$true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [ValidateScript({<# Path should exist as a folder #>Test-Path -Path $_ -PathType Container})]
            $path
        )
            try
            {
                Write-Verbose -Message "Obtaining the list of directories below $path"
                $directories = [System.IO.Directory]::GetDirectories($path,"*",[System.IO.SearchOption]::AllDirectories)
            }
            catch
            {
                Write-Error -Message "An error occured obtaining the list of directories below $path.  Error: $_" -ErrorAction Stop
            }
 
            Foreach($dir in $directories)
            {
                $count = 0
                While($dir.Length -gt 240)
                {
                    $dir = Split-Path -Path $dir -Parent
                    $PsDriveName = "Temp-$(Split-Path -Path $dir -Leaf)"
                    try
                    {
                        Write-Verbose -Message "Mapping a PSDrive ($PsDriveName) to shorten the path length."
                        New-PSDrive -Name "$PsDriveName" -PSProvider FileSystem -Root $dir -Scope Global -Description "TempDrive-CreatedBy:Start-UsingLongDirectories" | Out-Null
                    }
                    catch
                    {
                        Write-Error -Message "An error occured when mapping a PSDrive ($PsDriveName) to shorten the path length.  Error: $_" -ErrorAction Stop
                    }
                    $dir = "$($PsDriveName):\"
                }
                Write-Output $dir
            }
 
        }
 
        function Stop-UsingLongDirectories
        {
        <#
        .DESCRIPTION
            Removes all PSDrives that match the root of the full path
 
        .PARAMETER FullPath
            The FullPath that should be checked against the available PSDrives and removed if applicable    
        #>
        [cmdletbinding()]
        PARAM(
        [array]$FullPath
        )
 
            Foreach($path in $FullPath)
            {
                Try
                {
                    Write-Verbose -Message "Removing PS Drives that match the root of each path in FullPath"
                    Get-PSDrive |
                     Where {(Split-Path $path -Qualifier) -match $_.Name} |
                      ForEach-Object -Process {Remove-PSDrive -Name $_.Name -Force}
                }
                Catch
                {
                    Write-Error -Message "An error occured when removing PS Drives that match the root of each path in FullPath.  Error: $_" -ErrorAction Inquire
                }
            }
 
        }
