#-------------------------------------------------------------------------    
# Script that will: 
# 1. Create a workspace. Workspacce Name: _Root
# 2. Get the latest code from repository
#-------------------------------------------------------------------------   
Param(
    [switch]
    $CSRWEB,
    [switch]
    $CSRWS,
    [switch]
    $CSRServices,
    [string]
    $LogPath
    [String]
    $Outdir = "C:\Application\CSR"
)
Begin 
{

    $MSBUILD="c:\WINDOWS\Microsoft.NET\Framework\v3.5\MsBuild"
    $WEBPROJECTOUTPUTDIR="$OUTDIR\CSRWeb"
    $script:Log=@()
    
    #-------------------------------------------------------------------------    
    Function SetTFS
    {
        $SCRIPT:tfsServer = "172.29.4.179"
        $script:userName = [system.environment]::UserName; 
        $script:computerName = [system.environment]::machinename
        $script:workspaceName = $computerName + "_" + $userName +"_WS"   #Use 'WS' as an acronym for "WorkSpace"
        $script:CSRDIR = "C:\Brassring2\Application\"; 
        $script:WEBPROJECTOUTPUTDIR="$Outdir\CSRWeb"
        $script:WEBPROJECTOUTPUTDIR1="$Outdir\CSRWS"
        $script:WEBPROJECTOUTPUTDIR2="$Outdir\CSRServices"
        $script:REFPATH="referenceToAllAssembiesUsedInTheProjectSeperatedbySemiColon"
        $script:MSBUILD="c:\WINDOWS\Microsoft.NET\Framework\v3.5\MsBuild"
        $script:failed = $false

        # Set up the TF Alias


        # Find where VS is installed. 
        $key = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\VisualStudio\9.0
        $dir = [string] (Get-ItemProperty $key.InstallDir)
        $script:tf = "$dir\tf.exe"
    } # End SetTFS

    #-------------------------------------------------------------------------    
    Function CreateWorkspace
    {
        Begin 
        {
            Write-Debug "Starting CreateWorkspace"
            
            Function DeleteWorkspace
            {
                # Delete the workspace if it exists. 
                Write-Verbose "Deleting workspace (if exists): $workspaceName" 
                $log +=  "Deleting workspace (if exists): $workspaceName" 
                
                &$TF workspace /delete  $workspaceName  /noprompt | out-null

                Write-Verbose "Done deleting workspace."
                $log += "Done deleting workspace."
            } #END DeleteWorkspace
        }
        Process 
        {
            DeleteWorkspace
        
            # Create the folder
            if (! (Test-Path $CSRDIR)) 
            {
                Write-Verbose "Creating folder: $CSRDIR"
                $log += "Creating folder: $CSRDIR"
                new-item -itemtype directory -path $CSRDIR -force | out-null
                Write-Verbose "Completed Creating folder: $CSRDIR" 
                $log += "Completed Creating folder: $CSRDIR" 
            }
            # Move to folder
            cd $CSRDIR

            # Create the workspace 
            Write-Verbose "Creating workspace: $workspaceName"
            $log +=  "Creating workspace: $workspaceName"

            &$TF workspace /new /computer:$computerName /server:$TFsServer /noprompt $workspaceName

            Write-Verbose "Done Creating workspace: $workspaceName" 
            $log += "Done Creating workspace: $workspaceName" 

            # Get the latest
            Write-Verbose "Getting the latest code from: $TFsServer. This could take awhile..."
            $log += "Getting the latest code from: $TFsServer. This could take awhile..."
            &$TF get $/CSR/CSR /recursive

            Write-Verbose "Done getting latest."
            $log += "Done getting latest."

            Write-Verbose "Tree initialization is complete."
            $log +=  "Tree initialization is complete."
        }
        End 
        {
            Write-Debug "CreateWorkspace Complete"
        } 
    } #END CreateWorkspace
   
   
    #-------------------------------------------------------------------------
    # Get Next Label
    #
    # Labels are BL{major}.{minor}
    # major = 1 - ???
    # minor = 001 - 999
    #-------------------------------------------------------------------------
    Function GetNextLabel()
    {
        Begin 
        {
            Write-Debug "Starting GetNextLabel"
        }
        Process
        {
            $major = 1
            $minor = 1
           
            $list = (&$TF labels /format:brief |? { $_ -notmatch "-.+" -and $_ -notmatch "Label.+Owner.+Date"})
            
            if ($list -ne $null) {
               
                # Split label into major minor
                $major,[int]$minor= (($list | Select-Object -last 1).split()).split(".")
            
                # Increment minor label
                $minor++
                
                # Remove BL from string, and cast to int
                [int]$major = $major.substring(2)
                
                # If minor gt 999 increment major and reset minor
                if ($minor -gt 999) {
                    $major++
                    $minor = 1
                }
            }
            
            # return label
            $label = "BL{0}.{1:000}" -f $major, $minor
            
            write-output $label
        }
        End
        {
            Write-Debug "GetNextLabel Completed"
        }
    }
    
    #-------------------------------------------------------------------------
    Function MSBuild($outputdir, $webproject, $project, $ref)
    {
        Begin 
        {
            Write-Debug "Starting MSBuild"
            Write-Debug "outputdir: $outputdir webproject: $webproject project: $project ref: $ref"
        }
        Process
        {
            # I think this can be cleaned up with where-object, but it's too important to play with
            $failed = $false
            &$MSBUILD /p:Configuration=Release  /p:OutDir=$Outputdir /p:WebProjectOutputDir=$webproject $project |% {
                    if ($_ -match "Build FAILED") { $failed = $true } ; $_ 
                }
            if ($failed) { throw (new-object NullReferenceException) }    
            
            $failed = $false
            &$MSBUILD /p:Configuration=Release /t:ResolveReferences /p:OutDir=$Outputdir\bin\ /p:ReferencePath=$ref $project  |% {
                    if ($_ -match "Build FAILED") { $failed = $true } ; $_ 
                }
            if ($failed) { throw (new-object NullReferenceException) }    
        }
        End
        {
            Write-Debug "MSBuild Completed"
        }
    }

    #-------------------------------------------------------------------------
    # Create the Label
    #-------------------------------------------------------------------------
    Function ApplyLabel()
    {
        Write-verbose "Create the Label" 
        $log +=  "Create the Label" 

        $label = GetNextLabel
            
        &$TF label  $label  $/CSR/CSR /recursive

        &$TF get /version:L$($label)

        Write-verbose "Applied label $label" 
        $log += "Applied label $label" 

        return $Label    
    } # END ApplyLabel
} # End Begin
Process 
{
    trap [Exception] 
    {
        write-verbose "Build Failed" 
        $log += "Build Failed" 
        exit 1;
    }
    . SetTFS
    . CreateWorkspace
    . ApplyLabel
    
    IF (!$CSRWS -AND !$CSRWEB -AND !$CSRServices)
    {
        Write-Debug "No Options Found Setting ALL"
        $CSRWS = $TRUE
        $CSRWEB = $TRUE
        $CSRServices = $TRUE
    }
    
    Switch ("") 
    {
        {$CSRWEB}
            {
                Write-Verbose "Building CSRWEB" 
                $log += "Building CSRWEB" 
                
                . MsBuild "$Outdir\CSRWeb\" $WEBPROJECTOUTPUTDIR "$CSRDIR\CSR\CSR\CSRWeb\CSRWeb\CSRWeb.csproj" $REFPATH
                
                # copy-item C:\TFSMAIN\CSR\bin\Microsoft.ApplicationBlocks.Data.dll $CSRDIR\CSRWeb\bin\ -credential 
                # copy-item C:\TFSMAIN\CSR\bin\Microsoft.Practices.EnterpriseLibrary.Caching.dll $CSRDIR\CSRWeb\bin\ -credential 
                # copy-item C:\TFSMAIN\CSR\bin\Microsoft.Practices.ObjectBuilder.dll $CSRDIR\CSRWeb\bin\ -credential 

                rm  $Outdir\CSRWeb\*.config -recurse
                rm  $Outdir\CSRWeb\*.pdb -recurse
                rm  $Outdir\CSRWeb\*.dll -recurse
                rm  $Outdir\CSRWeb\*.xml -recurse
                rm  $Outdir\CSRWeb\bin\*.pdb -recurse
                rm  $Outdir\CSRWeb\bin\*.config -recurse
                rm  $Outdir\CSRWeb\bin\*.xml -recurse
                
                Write-verbose "Build CSRWEB Successful"  
                $log += "Build CSRWEB Successful"  
            }
        {$CSRWS}
            {
                Write-verbose "Building CSRWS" 
                $log +="Building CSRWS" 
        
                . MsBuild "$Outdir\CSRWS\" $WEBPROJECTOUTPUTDIR1 "$CSRDIR\CSR\CSR\CSRWS\CSRWS\CSRWS.csproj" $REFPATH
                
                # copy-item C:\TFSMAIN\CSR\bin\Microsoft.ApplicationBlocks.Data.dll $CSRDIR\CSRWeb\bin\ -credential 
                # copy-item C:\TFSMAIN\CSR\bin\Microsoft.Practices.EnterpriseLibrary.Caching.dll $CSRDIR\CSRWeb\bin\ -credential 
                # copy-item C:\TFSMAIN\CSR\bin\Microsoft.Practices.ObjectBuilder.dll $CSRDIR\CSRWeb\bin\ -credential 

                rm  $Outdir\CSRWS\*.config -recurse
                rm  $Outdir\CSRWS\*.pdb -recurse
                rm  $Outdir\CSRWS\*.dll -recurse
                rm  $Outdir\CSRWS\*.xml -recurse
                rm  $Outdir\CSRWS\bin\*.pdb -recurse
                rm  $Outdir\CSRWS\bin\*.config -recurse
                rm  $Outdir\CSRWS\bin\*.xml -recurse
               
                Write-verbose "Build CSRWS Successful" 
                $log += "Build CSRWS Successful" 
            }
        {$CSRServices}
            {
                Write-verbose "Building CSR Services"
                $Log += "Building CSR Services"
            
                . MsBuild "$Outdir\CSRSERVICES\" $WEBPROJECTOUTPUTDIR2 "$CSRDIR\CSR\CSR\CSRSERVICES\CSRSERVICES\CSRSERVICES.csproj" $REFPATH
                
                # copy-item C:\TFSMAIN\CSR\bin\Microsoft.ApplicationBlocks.Data.dll $CSRDIR\CSRWeb\bin\ -credential 
                # copy-item C:\TFSMAIN\CSR\bin\Microsoft.Practices.EnterpriseLibrary.Caching.dll $CSRDIR\CSRWeb\bin\ -credential 
                # copy-item C:\TFSMAIN\CSR\bin\Microsoft.Practices.ObjectBuilder.dll $CSRDIR\CSRWeb\bin\ -credential 

                rm  $Outdir\CSRSERVICES\*.config -recurse
                rm  $Outdir\CSRSERVICES\*.pdb -recurse
                rm  $Outdir\CSRSERVICES\*.dll -recurse
                rm  $Outdir\CSRSERVICES\*.xml -recurse
                rm  $Outdir\CSRSERVICES\bin\*.pdb -recurse
                rm  $Outdir\CSRSERVICES\bin\*.config -recurse
                rm  $Outdir\CSRSERVICES\bin\*.xml -recurse
                
                Write-verbose "Build CSR Services Successful"
                $Log += "Build CSR Services Successful"
            }
    } # End Switch
} #End Process
End 
{
    IF ($LogPath) 
    {
        $log | Out-file -FilePath $LogPath -Encoding ascii -Append
    }
} #END End
