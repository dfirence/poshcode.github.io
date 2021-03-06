<#
.Synopsis
    Cleanup after SMVI
.PARAMETER Max
    Maximum number of concurrent snapshot delete tasks.  Default: 5
.PARAMETER Recurse
    Recursively process snapshots untill they are all gone.
.Example
    .\Remove-SMVISnapshots.ps1 -Max 10
    
    removes the 10 newest smvi leftovers, and returns the prompt
.Example
    .\Remove-SMVISnapshots.ps1 -Max 3 -Recurse 
    
    will chew through all SMVI snapshots three at a time.
.notes
    #Requires -verson 2 
    Author: Glenn Sizemore
#>
[CmdletBinding(SupportsShouldProcess=$True,SupportsTransactions=$False,ConfirmImpact="low",DefaultParameterSetName="")]
Param(
    [parameter()]
    [int]
    $Max=2,
    
    [parameter()]
    [switch]
    $Recurse,
    
    [parameter()]
    [switch]
    $RunAsync
)
begin{
    Function Get-Snapinfo {
        <#
        .Synopsis
            Get the snapshot info out of a Virtual Machine Managed Entity.  Most useful for
            reporting!
        .PARAMETER VM
            VirtualMachine object to scan to extract snapshots from
        .PARAMETER VirtualMachineSnapshotTree
            used to recursively crawl a VM for snapshots... just use -VM
        .PARAMETER Filter
            Specify the name of the snapshots you want to retrieve, will perform a regex match.
        .Example
            Get-View -ViewType virtualmachine | Get-Snapinfo
        .Example
            Get-View -ViewType virtualmachine | Get-Snapinfo -Filter "^SMVI"
        .notes
            #Requires -verson 2 
            Author: Glenn Sizemore
            get-admin.com/blog/?p=879
        #>
        [cmdletBinding(SupportsShouldProcess=$false,DefaultParameterSetName="VM")]
        Param(
            [parameter(Mandatory=$true,ValueFromPipeline=$true, ParameterSetName="VM")]
            [VMware.Vim.VirtualMachine[]]
            $VM,
            
            [parameter(Mandatory=$true,ValueFromPipeline=$true, ParameterSetName="Snaptree")]
            [VMware.Vim.VirtualMachineSnapshotTree[]]
            $VirtualMachineSnapshotTree,
            
            [parameter(ParameterSetName="VM")] 
            [parameter(ParameterSetName="Snaptree")]
            [string]
            $Filter
        )
        Process {
            switch ($PScmdlet.ParameterSetName) 
            {
                "Snaptree"
                {
                    Foreach ($Snapshot in $VirtualMachineSnapshotTree) {
                        Foreach ($ChildSnap in $Snapshot.ChildSnapshotList) {
                            if ($ChildSnap) {
                                Get-Snapinfo -VirtualMachineSnapshotTree $ChildSnap -Filter $Filter
                            }
                        }
                        If ($Snapshot.Name -match $Filter ) {
                            write-output $Snapshot | Select Name, CreateTime, Vm, Snapshot
                        }
                    }
                }
                "VM"
                {
                    Foreach ($v in $VM) {
                        Get-Snapinfo -VirtualMachineSnapshotTree $v.Snapshot.RootSnapshotList -Filter $Filter
                    }
                }
            }
        }
    }
    $Snapshots = Get-View -ViewType virtualmachine `
            -Property snapshot `
            -Filter @{"Snapshot"="VMware.Vim.VirtualMachineSnapshotInfo"} `
            -verbose:$False |
                Get-Snapinfo -Filter "^smvi_" |
                Sort-Object @{Expression="VM";Descending=$false},@{Expression="CreateTime";Descending=$true}
    $Start = Get-date
}
Process
{
    while ($snapshots.count -gt 0)
    {
        $VirtualMachineSnapshots = $Snapshots | 
            Group-Object -Property VM | 
            Foreach-Object { 
                # Select one snapshot for each VM we do this to ensure we
                # don't try to delete more than one snapshot per VM, Per pass
                $_.Group | Select-Object -first 1 
            } | Select-Object -first $max
        
        $tasks = @()
        # Remove snapshots 
        Foreach ($VirtualMachineSnapshot in $VirtualMachineSnapshots ) {
            If ($pscmdlet.ShouldProcess($VirtualMachineSnapshot.VM,"removing snapshot $($VirtualMachineSnapshot.Name)")) {
                $snap = Get-View $VirtualMachineSnapshot.snapshot -verbose:$False
                
                # RemoveSnapshot_Task will return the task moref
                $taskMoRef = $snap.RemoveSnapshot_Task($false)
                
                #  Convert that moref into a Task object
                $Tasks += Get-VIObjectByVIView -MORef $taskMoRef -verbose:$False
            }
        }
        
        if ($RunAsync) {
            #return the taskimpl, and then break out
            Foreach ($t in $Tasks) {
                write-output $t
            }
            break
        }
        sleep 2
        #Pause for snap delets
        Wait-Task -Task $tasks -Verbose:$false
        
        # if not recurse break out!
        if (!$recurse -or $PSCmdlet.MyInvocation.BoundParameters.whatif.IsPresent){
            $snapshots = $null
        } 
        Else {
            $Snapshots = Get-View -ViewType virtualmachine `
                -Property snapshot `
                -Filter @{"Snapshot"="VMware.Vim.VirtualMachineSnapshotInfo"} `
                -verbose:$False |
                    Get-Snapinfo -Filter "^smvi_" |
                    Sort-Object @{Expression="VM";Descending=$false},@{Expression="CreateTime";Descending=$true}
        }
        
        
        
    }
}
End {write-output (New-TimeSpan -start $start)}

