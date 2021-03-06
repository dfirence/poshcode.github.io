#Example 
#New-XVM -ComputerName HYPERVSVR02 -Name "TLG-INET2" -SwitchName "External(192.168.1.0/24)" -VhdType Differencing -ParentVhdPath 'D:\vhds\Windows #Server 2012 RC Base.vhdx'

Function New-XVM
{
    [cmdletbinding()]
    Param
    (
        [Parameter(Mandatory=$false,Position=1)]
        [string]$ComputerName=$env:COMPUTERNAME,        
        [Parameter(Mandatory=$true,Position=2)]
        [string]$Name,
        [Parameter(Mandatory=$true,Position=3)]
        [string]$SwitchName,
        [Parameter(Mandatory=$true,Position=4)]
        [ValidateSet("NoVHD","ExistingVHD","NewVHD","Differencing")]
        [string]$VhdType,
        [Parameter(Mandatory=$false,Position=5)]
        [hashtable]$Configuration
    )
    DynamicParam
    {
        Switch ($VhdType) {
            "ExistingVHD" {
                $attributes = New-Object System.Management.Automation.ParameterAttribute
                $attributes.ParameterSetName = "ByParam"
                $attributes.Mandatory = $true
                $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
                $attributeCollection.Add($attributes)
                $vhdPath = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("VhdPath", [String], $attributeCollection)
                $paramDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
                $paramDictionary.Add("VhdPath",$vhdPath)
                return $paramDictionary
            }
            "NewVHD" {
                $attributes = New-Object System.Management.Automation.ParameterAttribute
                $attributes.ParameterSetName = "ByParam"
                $attributes.Mandatory = $false
                $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
                $attributeCollection.Add($attributes)
                $diskType = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("DiskType", [String], $attributeCollection)
                $paramDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
                $paramDictionary.Add("DiskType",$diskType)
                $attributes = New-Object System.Management.Automation.ParameterAttribute
                $attributes.ParameterSetName = "ByParam"
                $attributes.Mandatory = $false
                $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
                $attributeCollection.Add($attributes)
                $diskSize = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("DiskSize", [uint64], $attributeCollection)
                $paramDictionary.Add("DiskSize",$diskSize)
                return $paramDictionary
            }
            "Differencing" {
                $attributes = New-Object System.Management.Automation.ParameterAttribute
                $attributes.ParameterSetName = "ByParam"
                $attributes.Mandatory = $true
                $attributeCollection = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
                $attributeCollection.Add($attributes)
                $parentVhdPath = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("ParentVhdPath", [String], $attributeCollection)
                $paramDictionary = New-Object -Type System.Management.Automation.RuntimeDefinedParameterDictionary
                $paramDictionary.Add("ParentVhdPath",$parentVhdPath)
                return $paramDictionary
            }
        }
    }
    Begin
    {
        Try
        {
            $vmHost = Get-VMHost -ComputerName $ComputerName -ErrorAction:Stop
        }
        Catch
        {
            $PSCmdlet.ThrowTerminatingError($Error[0])
        }
        $defaultVirtualHardDiskPath = $vmHost.VirtualHardDiskPath
    }
    Process
    {
        $validConfigNames = "MemoryStartupBytes","BootDevice"
        $configParams = @()
        Switch ($VhdType) {
            "NoVHD" {
                $newVhdPath = $null
            }
            "ExistingVHD" {
                $newVhdPath = $vhdPath.Value
            }
            "NewVhd" {
                if (-not $diskType.IsSet) {$diskType.Value = "Dynamic"}
                if (-not $diskSize.IsSet) {$diskSize.Value = 127GB}
                $newVhdPath = Join-Path -Path $defaultVirtualHardDiskPath -ChildPath "$Name.vhdx"
                Switch ($diskType.Value) {
                    "Fixed" {
                        $vhdFile = New-VHD -ComputerName $ComputerName -Fixed -SizeBytes $diskSize.Value -Path $newVhdPath -ErrorAction Stop
                    }
                    "Dynamic" {
                        $vhdFile = New-VHD -ComputerName $ComputerName -Dynamic -SizeBytes $diskSize.Value -Path $newVhdPath -ErrorAction Stop
                    }
                }
            }
            "Differencing" {
                $newVhdPath = Join-Path -Path $defaultVirtualHardDiskPath -ChildPath "$Name.vhdx"
                $vhdFile = New-VHD -ComputerName $ComputerName -Differencing -ParentPath $parentVhdPath.Value -Path $newVhdPath -ErrorAction Stop
            }
        }
        if ($vhdFile -ne $null) {
            $command = "New-VM -ComputerName $ComputerName -Name '$Name' -SwitchName '$SwitchName' -VHDPath '$($vhdFile.Path)'"
        } else {
            $command = "New-VM -ComputerName $ComputerName -Name '$Name' -SwitchName '$SwitchName' -NoVHD"
        }
        if ($Configuration -ne $null) {
            foreach ($configName in $Configuration.Keys.GetEnumerator()) {
                if ($validConfigNames -contains $configName) {
                    $configParams += "-$configName" + " " + $Configuration[$configName]
                }
            }
            $configParams = $configParams -join " "
        }
        if ($configParams.Count -eq 0) {
            $command += " -ErrorAction Stop"
        } else {
            $command += " $configParams -ErrorAction Stop"        
        }
        Try
        {
            Invoke-Expression -Command $command
        }
        Catch
        {
            $PSCmdlet.WriteError($Error[0])
            Remove-Item -Path $vhdFile.Path
        }
    }
    End {}
}
