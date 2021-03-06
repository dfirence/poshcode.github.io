#  Reads all of the GPOs out of the domain, parses them, and then sends the output of settings to a GridView

#  Reduces the total lines in a string to 9, because out-gridview doesn't like more than 9 lines in an entry
Function Replace-ExtraLines
{
    Param($Entries)

    ForEach ($Entry in $Entries)
    {
        $Additional = $Entry.Additional
        [String[]]$Lines = @()

        If ((Measure-Object -Line -InputObject $Additional).Lines -gt 9)
        {
            $Count = (Measure-Object -Line -InputObject $Additional).Lines

            $Lines = $Additional.Split("`n")

            [String]$Additional = ''
            $LineNum = 1
            $LineNumRemoved = 0

            ForEach ($Line in $Lines)
            {
                If ($LineNum / ($count / ($count - 9)) - $LineNumRemoved -ge 1.0)
                {
                    If ($Additional -ne '')
                    {
                        $Additional += '; '
                    }
                    $Additional += $Line

                    $LineNumRemoved++
                }
                Else
                {
                    If ($Additional -ne '')
                    {
                        $Additional += "`n"
                    }
                    $Additional += $Line
                }

                $LineNum++
            }
            $Entry.Additional = $Additional
        }
    }
    Return $Entries
}

#  Performs some basic parsing of the ADMX settings that are registry settings
Function Get-XMLTreeSimpleValues 
{
    Param($XmlElement)

    [String]$Additional = ''
    [Bool]$HasChildren = $false
    
    ForEach ($property in $XmlElement.ChildNodes)
    {
        [String]$Desc = ''
        If ($property.GetType().Name -eq 'XmlElement')
        {
            $Desc = Get-XMLTreeSimpleValues $property
            $HasChildren = $true
        }
        ElseIf ($property.GetType().Name -eq 'String')
        {
            $Desc = $property.LocalName + ': ' + $property
        }
        ElseIf ($property.GetType().Name -eq 'XmlText')
        {
            $Desc = $property.value
        }
        Else
        {
            Write-Warning "$($property.LocalName) isn't what was expected $($property.GetType())"
        }
        $Desc = $Desc.Trim()
        If ($Desc -ne '')
        {
            If ($Additional -eq '')
            {
                $Additional = $Desc
            }
            ElseIf ($Additional -match ':$')
            {
                $Additional += " " + $Desc
            }
            ElseIf ($Desc -eq 'Enabled' -or $Desc -eq 'Disabled')
            {
                $Additional += ": " + $Desc
            }
            Else
            {
                $Additional += "`n" + $Desc
            }
        }
    }
    #$Additional = Replace-ExtraLines $Additional
    Return $Additional
}

#  Performs some slightly more complex parsing of the ADMX settings that are registry settings
Function Get-RegistryValues
{
    Param($XmlElement)

    <#  
    Valid values and sub-values appear to be:
        Name
        State
        Explain
        Supported
        Category
        Text
        Comment
        CheckBox
            Name
            State
        DropDownList
            Name
            State
            Value
        EditText
            Name
            State
            Value
        ListBox
            Name
            State
            Value
            Additive
            ExplicitValue
            ValuePrefix
        Numeric
            Name
            State
            Value
    #>

    [String]$Additional = ''
    #  Elements to skip in the "Registry" section
    [String[]]$ignoreList = @('Name', 'State', 'Explain', 'Supported', 'Category', 'Text', 'Comment')
    
    [String[]]$DescList = @()
    ForEach ($property in $XmlElement.ChildNodes)
    {
        [String]$Desc = ''
        [String]$LocalName = $property.LocalName
        If (!$ignoreList.Contains($LocalName))
        {
            If ($property.Name.Trim().Length -eq '0')
            {
                [String]$PropertyName = $LocalName + ': '
            }
            ElseIf ($property.Name.Trim() -match ':$')
            {
                [String]$PropertyName = $property.Name.Trim() + ' '
            }
            ElseIf ($property.Name.Trim() -match '\.$')
            {
                [String]$PropertyName = $property.Name.Trim().Substring(0,$property.Name.Trim().Length - 1) + ': '
            }
            Else
            {
                [String]$PropertyName = $property.Name.Trim() + ': '
            }

            If ($LocalName -eq 'CheckBox')
            {
                $Desc = $PropertyName + $property.State
            }
            ElseIf ($LocalName -eq 'DropDownList')
            {
                $Desc = $PropertyName + $property.Value.Name
            }
            ElseIf ($LocalName -eq 'EditText')
            {
                $Desc = $PropertyName + $property.Value
            }
            ElseIf ($LocalName -eq 'ListBox')
            {
                If ($property.ValuePrefix)
                {
                    [String]$ValuePrefix = '(ValuePrefix: ' + $property.ValuePrefix + ') '
                }
                Else
                {
                    [String]$ValuePrefix = ''
                }

                [String[]]$ValueData = @()
                ForEach ($ValueElement in $property.Value.Element)
                {
                    $ValueData += [String[]]($ValueElement.childnodes.'#text') -join ', '
                }
                #$Desc = $LocalName + ': ' + $PropertyName + 'Expli-' + $property.ExplicitValue + ': ' + 'Addi-' + $property.Additive + ': ' + $ValuePrefix + "`n" + ($ValueData -join "`n")
                $Desc = $PropertyName + $ValuePrefix + "`n" + ($ValueData -join "`n")
            }
            ElseIf ($LocalName -eq 'Numeric')
            {
                $Desc = $PropertyName + $property.Value
            }
            Else
            {
                Write-Warning "$($LocalName): $($property.Name) isn't what was expected $($property.GetType())"
            }
            $DescList += $Desc.Trim()
        }
    }
    #Return (Replace-ExtraLines ($DescList -join "`n"))
    Return ($DescList -join "`n")
}

#  Parses direct registry settings in GPOs
Function Get-XMLTreeRegistryValues
{
    Param($XmlElement)
    
    $updateType = @{'C' = 'Create'; 'R' = 'Replace'; 'U' = 'Update'; 'D' = 'Delete'}
    $hive = @{'HKEY_LOCAL_MACHINE' = 'HKLM'; 'HKEY_CLASSES_ROOT' = 'HKCR'; 'HKEY_CURRENT_USER' = 'HKCU'; 'HKEY_USERS' = 'HKU'; 'HKEY_CURRENT_CONFIG' = 'HKCC'}
    $returnArray = @()
    
    ForEach ($property in $XmlElement.ChildNodes)
    {
        [String]$Desc = ''
        [String]$State = 'Enabled'
        $tempArray = @()
        If ($property.LocalName -eq 'GPOSettingOrder' -or $property.LocalName -eq 'Filters' -or $property.LocalName -eq '#text')
        {
            $tempArray = Get-XMLTreeRegistryValues $property
        }
        ElseIf ($property.LocalName -eq 'Collection')
        {
            $tempArray = Get-XMLTreeRegistryValues $property
        }
        ElseIf ($property.LocalName -eq 'Registry')
        {
            If ($property.disabled -eq '1')
            {
                $State = 'Disabled'
            }
            If ($property.status)
            {
                $name = $property.status
            }
            Else
            {
                $name = $property.name
            }
            $Desc  = $updateType["$($property.Properties.action)"] + ' "'
            $Desc += $name + '" to "'
            $Desc += $property.Properties.value + '"' + "`n"
            $Desc += $hive["$($property.Properties.hive)"] + '\'
            $Desc += $property.Properties.key

            $tempArray += New-Object PSObject -Property @{
                                        State = $state
                                        Additional = $Desc
                                    }
        }
        Else
        {
            Write-Warning "$($property.LocalName) isn't what was expected $($property.GetType()) $($property.value) $($property.Name)"
        }
        If ($tempArray.Count -gt 0)
        {
            $returnArray += $tempArray
        }
    }
    Return $returnArray
}

#  Performs some complex parsing of the ADMX settings that are non-registry settings
Function Get-XMLTreeComplexValues
{
    Param(
        $XmlElement,
        [String]$Parent,
        [String]$Name
    )
    
    [PSObject[]]$returnArray = @()
    $Additional = ''
    
    ForEach ($property in $XmlElement.ChildNodes)
    {
        [String]$Desc = ''
        [PSObject[]]$tempArray = @()
        #  For this to work right, this makes the really bad assumption that the "name" element is first
        If ($property.LocalName -eq 'name' -or $property.LocalName -eq 'SystemAccessPolicyName')
        {
            $Name = $property.'#text'
            #  Not sure if it's meaningful to have an entry every time the name is set
            #$Desc = $Parent + '\' +  $property.LocalName + '\' +  $property.'#text'
        }
        ElseIf ($property.LocalName -eq 'Type')
        {
        }
        ElseIf ($property.GetType().Name -eq 'XmlElement')
        {
            $tempArray = Get-XMLTreeComplexValues $property ($Parent + '\'+ $property.LocalName) $Name
        }
        ElseIf ($property.GetType().Name -eq 'String')
        {
            $Desc = $Parent + '\' +  $property.LocalName + ': ' + $property
        }
        ElseIf ($property.GetType().Name -eq 'XmlText')
        {
            $Desc = $Parent + '\' +  $property.value
        }
        Else
        {
            Write-Warning "$($property.LocalName) isn't what was expected $($property.GetType())"
        }
        $Desc = $Desc.Trim()
        If($Desc -ne '')
        {
            $tempArray += New-Object PSObject -Property @{
                                PolicyName = $Name
                                Additional = $Desc
                            }
        }
        If ($tempArray.Count -gt 0)
        {
            $returnArray += $tempArray
        }
    }
    Return $returnArray
}

#  Parse firewall specific settings
Function Get-XMLFirewallSettings
{
    Param(
        $ChildNodes,
	    [String]$identifier,
	    [String]$GPOName,
        [String]$PolicyType,
        [int32]$LinkCount,
        [Int32]$PermissionCount
    )

    [PSObject[]]$returnArray = @()
    
    [PSObject[]]$registrySettings = @()
    [String]$policyName = 'Windows Firewall'
    ForEach ($policy in $ChildNodes)
    {
        [String]$Additional = ''
        If($policy.LocalName -ne 'InboundFirewallRules' -and $policy.LocalName -ne 'OutboundFirewallRules')
        {
            ForEach ($extValue in $policy.ChildNodes)
            {
                If($extValue -ne '' -and $extValue.LocalName -ne 'PolicyVersion')
                {
                    If($Additional.Length -ne 0)
                    {
                        $Additional += "`n"
                    }
                    $Additional += "$($extValue.LocalName): $($extValue.Value)"
                }
            }
        }
        Else
        {
            ForEach ($extValue in $policy.ChildNodes)
            {
                If($extValue -ne '' -and $extValue.ChildNodes.Count -gt 0 -and $extValue.ChildNodes[0].Value -ne '')
                {
                    If (!$ignoreListFirewall.Contains($extValue.ChildNodes[0].ParentNode.ToString()) -and $extValue.ChildNodes[0].Value -notlike '*@FirewallAPI.dll,-*')
                    {
                        If($Additional.Length -ne 0)
                        {
                            $Additional += "`n"
                        }
                        $Additional += "$($extValue.ChildNodes[0].ParentNode.ToString()): $($extValue.ChildNodes[0].Value)"
                    }
                }
            }
        }

        #$Additional = Replace-ExtraLines $Additional

        If ($Additional -ne '')
        {
            $returnArray += New-Object PSObject -Property @{
	                            Identifier = $identifier
	                            GPOName = $GPOName
                                T = $PolicyType
                                L = $LinkCount
                                PolicyName = "$($policyName): $($policy.LocalName)"
                                State = ''
                                Additional = $Additional
                                P = $PermissionCount
                            }
        }
    }

    Return $returnArray
}

#  Parse Advanced Audit settings
Function Get-XMLAdvancedAuditSettings
{
    Param(
        $ChildNodes,
	    [String]$identifier,
	    [String]$GPOName,
        [String]$PolicyType,
        [int32]$LinkCount,
        [Int32]$PermissionCount
    )

    [PSObject[]]$returnArray = @()
    [String]$policyName = 'Advanced Audit Configuration'
    [String]$Additional = ''
    [String]$TempAdditional = ''
    [String[]]$AuditEvents = @('None', 'Success', 'Failure', 'Success and Failure')

    ForEach ($policy in $ChildNodes)
    {
        $Additional = ''
        $TempAdditional = ''

        If ($policy.LocalName -eq 'AuditSetting')
        {
            $Additional = "$($policy.SubcategoryName): $($AuditEvents[$policy.SettingValue])"
        }
        ElseIf ($policy.LocalName -eq 'GlobalSaclSetting')
        {
            ForEach ($setting in $policy.ChildNodes)
            {
                If ($setting.LocalName -eq 'GlobalSaclType')
                {
                    $Additional += "$($setting.LocalName): $($setting.'#text')"
                }
                ElseIf ($setting.LocalName -eq 'SecurityDescriptor')
                {
                    ForEach ($SecurityDescriptor in $setting.ChildNodes)
                    {
                        If($SecurityDescriptor.LocalName -eq 'Auditing')
                        {
                            ForEach ($Audit in $SecurityDescriptor.ChildNodes)
                            {
                                $Additional += "`n$($Audit.LocalName): $($Audit.'#text')"
                            }
                        }
                        Else
                        {
                            $Additional += "`n$($SecurityDescriptor.LocalName): $($SecurityDescriptor.'#text')"
                        }
                    }
                }
                Else
                {
                    $Additional += "`n$($setting.LocalName): $($setting.'#text')"
                }
            }
        }
        Else
        {
            Write-Warning "Unknown audit setting type '$($policy.LocalName)' in $($GPOName)"
        }

        #$Additional = Replace-ExtraLines $Additional
        If ($Additional -ne '')
        {
            $returnArray += New-Object PSObject -Property @{
	                            Identifier = $identifier
	                            GPOName = $GPOName
                                T = $PolicyType
                                L = $LinkCount
                                PolicyName = "$($policyName)"
                                State = ''
                                Additional = $Additional
                                P = $PermissionCount
                            }
        }
    }

    Return $returnArray
}

#  Parse Security User Rights Assignment settings
Function Get-XMLUserRightsAssignment
{
    Param(
        $UserRightsAssignments
    )

    [PSObject[]]$returnArray = @()

    ForEach ($policy in $UserRightsAssignments)
    {
        [String]$policyName = $policy.Name
        [String]$state = $policy.State

        [String[]]$DescList = @()
        [String]$Desc = ''
        If ($policy.Member -ne $null)
        {
            If ($policy.Member.GetType().Name -eq 'XmlElement')
            {
                If ($policy.Member.SID -ne $null)
                {
                    $Desc = $policy.Member.SID.'#text'
                    If ($policy.Member.Name.'#text' -ne $null)
                    {
                        $Desc += " ($($policy.Member.Name.'#text'))"
                    }
                }
                Else
                {
                    $Desc = $policy.Member.Name.'#text'
                }
                $DescList += $Desc
            }
            Else
            {
                ForEach ($Mem in $policy.Member)
                {
                    If ($Mem.SID -ne $null)
                    {
                        $Desc = $Mem.SID.'#text'
                        If ($Mem.Name.'#text' -ne $null)
                        {
                            $Desc += " ($($Mem.Name.'#text'))"
                        }
                    }
                    Else
                    {
                        $Desc = $Mem.Name.'#text'
                    }
                    $DescList += $Desc
                }
            }
            $Desc = $DescList -join "`n"
        }

        $returnArray += New-Object PSObject -Property @{
                            PolicyName = $policy.Name
                            Additional = $Desc
                        }
    }

    Return $returnArray
}

#  Parse Security Options settings
Function Get-XMLSecurityOptions
{
    Param(
        $Policies
    )

    [PSObject[]]$returnArray = @()
    [String]$policyName = ''
    [String[]]$DescList = @()
    [String]$Desc = ''
    
    $StringValues = @('DisplayNumber', 'DisplayBoolean', 'DisplayString')
    ForEach ($policy in $Policies)
    {
        $DescList = @()

        If ($policy.Display.Name -ne $null)
        {
            $policyName = $policy.Display.Name
            ForEach ($attr in $policy.ChildNodes)
            {
                If ($attr.LocalName -eq 'KeyName' -or $attr.LocalName -eq 'SettingStrings' -or $attr.LocalName -eq 'SettingNumber' -or $attr.LocalName -eq 'SettingString')
                {
                    # Do nothing
                }
                ElseIf ($attr.LocalName -eq 'Display')
                {
                    ForEach ($child in $attr.ChildNodes)
                    {
                        If ($StringValues.Contains($child.LocalName))
                        {
                            If ($child.'#text' -ne '')
                            {
                                If ($Policy.Display.Units -ne '')
                                {
                                    $DescList += "$($Policy.Display.Units): $($child.'#text')"
                                }
                                Else
                                {
                                    $DescList += $child.'#text'
                                }
                            }
                        }
                        ElseIf ($child.LocalName -eq 'DisplayStrings')
                        {
                            #$DescList += 'Strings:'
                            ForEach ($str in $child)
                            {
                                $DescList += $str.Value
                            }
                        }
                        ElseIf ($child.LocalName -eq 'DisplayFields')
                        {
                            ForEach ($Field in $child.Field)
                            {
                                $DescList += "$($Field.Name): $($Field.Value)"
                            }
                        }
                        ElseIf ($child.LocalName -ne 'Name' -and $child.LocalName -ne 'Units')
                        {
                            Write-Warning "Unknown SecurityOption Display type $GPONum $($child.LocalName): $($child.'#text')"
                            $DescList += "$($child.LocalName): $($child.'#text')"
                        }
                    }
                }
                Else
                {
                    Write-Warning "Unknown SecurityOption type $GPONum $($attr.LocalName): $($attr)"
                    $DescList += "$($attr.LocalName): $($attr.'#text')"
                }
            }
        }
        ElseIf ($policy.SystemAccessPolicyName -ne $null)
        {
            [String]$policyName = $policy.SystemAccessPolicyName
                            
            ForEach ($child in $Policy.ChildNodes)
            {
                If ($child.LocalName -ne 'SystemAccessPolicyName')
                {
                    $DescList += $child.'#text'
                }
            }
        }
        Else
        {
            [String]$policyName = 'Security Option'
                            
            ForEach ($child in $Policy.ChildNodes)
            {
                $DescList += $child.'#text'
            }
        }

        $Desc = $DescList -join "`n"

        $returnArray += New-Object PSObject -Property @{
                            PolicyName = $policyName
                            Additional = $Desc
                        }
    }

    Return $returnArray
}

#  Parse Security Options settings
Function Get-XMLSecurityRegistry
{
    Param(
        $Policies
    )

    [PSObject[]]$returnArray = @()
    [String]$policyName = 'SecurityRegistry'
    [String[]]$DescList = @()
    
    ForEach ($policy in $Policies)
    {
        $DescList = @()

        ForEach ($attr in $policy.ChildNodes)
        {
            If ($attr.LocalName -eq 'Path')
            {
                $DescList += $attr.'#text'
            }
            ElseIf ($attr.LocalName -eq 'SecurityDescriptor')
            {
                ForEach ($subAttr in $attr.ChildNodes)
                {
                    If ($subAttr.LocalName -eq 'SDDL')
                    {
                        #  No one wants to see this, right?
                    }
                    ElseIf ($subAttr.LocalName -eq 'Permissions')
                    {
                        $DescList += "InheritsFromParent: $($subAttr.InheritsFromParent)"
                        If ($subAttr.InheritsFromParent -eq 'true')
                        {
                            $DescList += "Explicit Permissions: $(($subAttr.TrusteePermissions | Where-Object {$_.Inherited -eq 'false'} | Measure-Object).Count)"
                        }
                    }
                    Else
                    {
                        $DescList += "$($subAttr.LocalName): $($subAttr.'#text')"
                    }
                }
            }
            Else
            {
                $DescList += "$($attr.LocalName): $($attr.'#text')"
            }
        }

        $Desc = $DescList -join "`n"

        $returnArray += New-Object PSObject -Property @{
                            PolicyName = $policyName
                            Additional = $Desc
                        }
    }

    Return $returnArray
}

#  Parse Security Options settings
Function Get-XMLSecurityFile
{
    Param(
        $Policies
    )

    [PSObject[]]$returnArray = @()
    [String]$policyName = 'SecurityFile'
    [String[]]$DescList = @()
    
    ForEach ($policy in $Policies)
    {
        $DescList = @()

        ForEach ($attr in $policy.ChildNodes)
        {
            If ($attr.LocalName -eq 'Path')
            {
                $DescList += $attr.'#text'
            }
            ElseIf ($attr.LocalName -eq 'SecurityDescriptor')
            {
                ForEach ($subAttr in $attr.ChildNodes)
                {
                    If ($subAttr.LocalName -eq 'SDDL')
                    {
                        #  No one wants to see this, right?
                    }
                    ElseIf ($subAttr.LocalName -eq 'Permissions')
                    {
                        $DescList += "InheritsFromParent: $($subAttr.InheritsFromParent)"
                        If ($subAttr.InheritsFromParent -eq 'true')
                        {
                            $DescList += "Explicit Permissions: $(($subAttr.TrusteePermissions | Where-Object {$_.Inherited -eq 'false'} | Measure-Object).Count)"
                        }
                    }
                    Else
                    {
                        $DescList += "$($subAttr.LocalName): $($subAttr.'#text')"
                    }
                }
            }
            Else
            {
                $DescList += "$($attr.LocalName): $($attr.'#text')"
            }
        }

        $Desc = $DescList -join "`n"

        $returnArray += New-Object PSObject -Property @{
                            PolicyName = $policyName
                            Additional = $Desc
                        }
    }

    Return $returnArray
}

#  Parse Security Options settings
Function Get-XMLSecuritySystemServices
{
    Param(
        $Policies
    )

    [PSObject[]]$returnArray = @()
    [String]$policyName = 'SecuritySystemServices'
    [String[]]$DescList = @()
    
    ForEach ($policy in $Policies)
    {
        $DescList = @()

        ForEach ($attr in $policy.ChildNodes)
        {
            If ($attr.LocalName -eq 'Name')
            {
                $DescList += $attr.'#text'
            }
            ElseIf ($attr.LocalName -eq 'SecurityDescriptor')
            {
                ForEach ($subAttr in $attr.ChildNodes)
                {
                    If ($subAttr.LocalName -eq 'SDDL' -or $subAttr.LocalName -eq 'Auditing')
                    {
                        #  No one wants to see this, right?
                    }
                    ElseIf ($subAttr.LocalName -eq 'Permissions')
                    {
                        $DescList += "InheritsFromParent: $($subAttr.InheritsFromParent)"
                        If ($subAttr.InheritsFromParent -eq 'true')
                        {
                            $DescList += "Explicit Permissions: $(($subAttr.TrusteePermissions | Where-Object {$_.Inherited -eq 'false'} | Measure-Object).Count)"
                        }
                    }
                    Else
                    {
                        $DescList += "$($subAttr.LocalName): $($subAttr.'#text')"
                    }
                }
            }
            Else
            {
                $DescList += "$($attr.LocalName): $($attr.'#text')"
            }
        }

        $Desc = $DescList -join "`n"

        $returnArray += New-Object PSObject -Property @{
                            PolicyName = $policyName
                            Additional = $Desc
                        }
    }

    Return $returnArray
}

#  Parse Security Options settings
Function Get-XMLSecurityRestrictedGroups
{
    Param(
        $Policies
    )

    [PSObject[]]$returnArray = @()
    [String]$policyName = 'SecurityRestrictedGroups'
    [String[]]$DescList = @()
    [String]$Desc = ''
    [String]$Switch = ''
    
    ForEach ($policy in $Policies)
    {
        $DescList = @()
        $Desc = ''

        ForEach ($attr in $policy.ChildNodes)
        {
            If ($attr.LocalName -eq 'GroupName')
            {
                If ($attr.SID -ne $null)
                {
                    $Desc = $attr.SID.'#text'
                    If ($attr.Name.'#text' -ne $null)
                    {
                        $Desc += " ($($attr.Name.'#text'))"
                    }
                }
                Else
                {
                    $Desc = $attr.Name.'#text'
                }
                $DescList += $Desc
            }
            ElseIf ($attr.LocalName -eq 'Member' -or $attr.LocalName -eq 'Memberof')
            {
                If ($Switch -ne $attr.LocalName)
                {
                    $Switch = $attr.LocalName
                    $DescList += "$($attr.LocalName):"
                }
                If ($attr.SID -ne $null)
                {
                    $Desc = $attr.SID.'#text'
                    If ($attr.Name.'#text' -ne $null)
                    {
                        $Desc += " ($($attr.Name.'#text'))"
                    }
                }
                Else
                {
                    $Desc = $attr.Name.'#text'
                }
                $DescList += $Desc
            }
            Else
            {
                $DescList += "$($attr.LocalName): $($attr.'#text')"
            }
        }

        $Desc = $DescList -join "`n"

        $returnArray += New-Object PSObject -Property @{
                            PolicyName = $policyName
                            Additional = $Desc
                        }
    }

    Return $returnArray
}

#  Parse Security Options settings
Function Get-XMLSecurityEventLog
{
    Param(
        $Policies
    )

    [PSObject[]]$returnArray = @()
    [String]$policyName = 'SecurityEventLog'
    [String[]]$DescList = @()
    [String]$Desc = ''
    [String]$Switch = ''
    [String[]]$RetentionPeriod = @('Overwrite events as needed', 'Overwrite events by days', 'Do not overwrite events')
    
    ForEach ($policy in $Policies)
    {
        
        If ($Switch -ne $policy.Log)
        {
            If ($DescList.Count -ne 0)
            {
                $Desc = $DescList -join "`n"
                $returnArray += New-Object PSObject -Property @{
                                    PolicyName = $policyName
                                    Additional = $Desc
                                }
                $DescList = @()
            }
            $Switch = $policy.Log
            $DescList += "$($policy.Log) Log"
        }
        
        If ($policy.Name -eq 'RestrictGuestAccess')
        {
            $DescList += "$($policy.Name): $($policy.SettingBoolean)"
        }
        ElseIf ($policy.Name -eq 'AuditLogRetentionPeriod')
        {
            $DescList += "$($policy.Name): $($RetentionPeriod[$policy.SettingNumber])"
        }
        Else
        {
            $DescList += "$($policy.Name): $($policy.SettingNumber)"
        }
    }

    If ($DescList.Count -ne 0)
    {
        $Desc = $DescList -join "`n"
        $returnArray += New-Object PSObject -Property @{
                            PolicyName = $policyName
                            Additional = $Desc
                        }
        $DescList = @()
    }

    Return $returnArray
}

#  Parse Security Options settings
Function Get-XMLWLanSvcNetworks
{
    Param(
        $Policies
    )
    [PSObject[]]$returnArray = @()
    [String]$policyName = 'WLanSvcNetworks'
    [String[]]$DescList = @()
    [String]$Desc = ''
    [String]$Switch = ''
    
    ForEach ($policy in $Policies)
    {
        $DescList = @()
        $Desc = ''

        ForEach ($attr in $policy.ChildNodes)
        {
            If ($attr.LocalName -eq 'networkFilter' -or $attr.LocalName -eq 'profileList')
            {
                #$DescList += "$($attr.LocalName)"
                ForEach ($attr2 in $attr.ChildNodes)
                {
                    If ($attr2.LocalName -eq 'allowList' -or $attr2.LocalName -eq 'blockList')
                    {
                        ForEach ($attr3 in $attr2.ChildNodes)
                        {
                            $DescList += "$($attr2.LocalName)-networkName: $($attr3.networkName); networkType: $($attr3.networkType)"
                        }
                    }
                    ElseIf ($attr2.LocalName -eq 'WLANProfile')
                    {
                        $DescList += "WLANProfile: $($attr2.name); Type: $($attr2.connectionType)"
                        $DescList += "SSID: $($attr2.SSIDConfig.SSID.name); Broadcast: $([Bool]($attr2.SSIDConfig.nonBroadcast) -eq $false)"
                        $DescList += "authentication: $($attr2.MSM.security.authEncryption.Authentication); encryption: $($attr2.MSM.security.authEncryption.encryption); 802.1x: $($attr2.MSM.security.authEncryption.useOneX)"
                        If ($attr2.MSM.security.authEncryption.useOneX -eq 'true')
                        {
                            If ($attr2.MSM.security.OneX.EAPConfig.EapHostConfig.Config.Eap.EapType.Eap.EapType.UseWinLogonCredentials)
                            {
                                $DescList += "authMode: $($attr2.MSM.security.OneX.authMode); UseWinLogonCredentials: $($attr2.MSM.security.OneX.EAPConfig.EapHostConfig.Config.Eap.EapType.Eap.EapType.UseWinLogonCredentials)"
                            }
                            Else
                            {
                                $DescList += "authMode: $($attr2.MSM.security.OneX.authMode)"
                            }
                        }

                        #  I want to skip enough information in these settings that it's easier to just cherry pick
                        <#
                        ForEach ($attr2b in $attr2.ChildNodes)
                        {
                            If ($attr2b.LocalName -eq 'MSM')
                            {
                                ForEach ($attr3 in $attr2b.security.ChildNodes)
                                {
                                    If ($attr3.LocalName -eq 'authEncryption')
                                    {
                                        $DescList += "authentication: $($attr3.Authentication)"
                                        $DescList += "encryption: $($attr3.encryption)"
                                        $DescList += "802.1x: $($attr3.useOneX)"
                                    }
                                    If ($attr3.LocalName -eq 'OneX')
                                    {
                                        $DescList += "authMode: $($attr3.authMode)"
                                        $DescList += "UseWinLogonCredentials: $($attr3.EAPConfig.EapHostConfig.Config.Eap.EapType.Eap.EapType.UseWinLogonCredentials)"
                                        #  Most of the settings under here are best looked at directly in the GPO

                                    }
                                    Else
                                    {
                                        #  I think it's a little excessive to include this information
                                        #$DescList += " $($attr3.LocalName): $($attr3.'#text')"
                                    }
                                }
                            }
                            ElseIf ($attr2b.LocalName -eq 'SSIDConfig')
                            {
                                $DescList += "SSID: $($attr2b.SSID.name)"
                                #$DescList += "Broadcast: $([Bool]($attr2b.nonBroadcast) -eq $false)"
                            }
                            ElseIf ($attr2b.LocalName -eq 'name')
                            {
                                $DescList += "WLANProfile: $($attr2b.'#text')"
                            }
                            ElseIf ($attr2b.LocalName -eq 'connectionType')
                            {
                                $DescList += "connectionType: $($attr2b.'#text')"
                            }
                        }
                        #>
                    }
                    Else
                    {
                        #$DescList += " $($attr2.LocalName): $($attr2.'#text')"
                    }
                }
            }
            ElseIf ($attr.LocalName -eq 'name')
            {
                $DescList += $attr.'#text'
            }
            ElseIf ($attr.LocalName -eq 'globalFlags')
            {
                #  These are more clutter than useful.  Best to look directly at the policies
                #$DescList += "$($attr.LocalName): $($attr.'#text')"
            }
            Else
            {
                $DescList += "$($attr.LocalName): $($attr.'#text')"
            }
        }

        $Desc = $DescList -join "`n"

        $returnArray += New-Object PSObject -Property @{
                            PolicyName = $policyName
                            Additional = $Desc
                        }
    }

    Return $returnArray
}

#  Parse Security Options settings
Function Get-XMLLanSvcNetworks
{
    Param(
        $Policies
    )
    [PSObject[]]$returnArray = @()
    [String]$policyName = 'LanSvcNetworks'
    [String[]]$DescList = @()
    [String]$Desc = ''
    [String]$Switch = ''
    
    ForEach ($policy in $Policies)
    {
        $DescList = @()
        $Desc = ''
        
        $DescList += "$($policy.name)"
        If ($policy.description)
        {
            $DescList += "$($policy.description)"
        }
        $DescList += "enableAutoConfig: $($policy.globalFlags.enableAutoConfig); enableExplicitCreds: $($policy.globalFlags.enableExplicitCreds.'#text')"
        $DescList += "OneXEnabled: $($policy.profileList.LANProfile.MSM.security.OneXEnabled); OneXEnforced: $($policy.profileList.LANProfile.MSM.security.OneXEnforced)"
        $DescList += "authMode: $($policy.profileList.LANProfile.MSM.security.OneX.authMode); maxAuthFailures: $($policy.profileList.LANProfile.MSM.security.OneX.maxAuthFailures)"


        $Desc = $DescList -join "`n"

        $returnArray += New-Object PSObject -Property @{
                            PolicyName = $policyName
                            Additional = $Desc
                        }
    }

    Return $returnArray
}

#  Parse Security Options settings
Function Get-XMLPublicKey
{
    Param(
        $Policies
    )
    [PSObject[]]$returnArray = @()
    [String]$policyName = 'PublicKey'
    [String[]]$DescList = @()
    [String]$Desc = ''
    [String]$Switch = ''
    
    ForEach ($policy in $Policies)
    {
        $DescList = @()
        $Desc = ''
        
        If ($policy.LocalName -eq 'AutoEnrollmentSettings')
        {
            $DescList += "EnrollCertificatesAutomatically: $($policy.EnrollCertificatesAutomatically)"
            $DescList += "ExpiryNotification: $($policy.ExpiryNotification)"
            $DescList += "NotifyPercent: $($policy.NotifyPercent.Value)"
            $DescList += "RenewUpdateRevoke: $($policy.Options.RenewUpdateRevoke)"
            $DescList += "UpdateTemplates: $($policy.Options.UpdateTemplates)"
        }
        ElseIf ($policy.LocalName -eq 'RootCertificateSettings' -or $policy.LocalName -eq 'EFSSettings')
        {
            #  Everything in here appears to be set automatically as a consequence of importing a trusted root CA certificate
            #  I need to check on the possibility that this could be set somewhere else
        }
        ElseIf ($policy.LocalName -eq 'RootCertificate' -or $policy.LocalName -eq 'TrustedPublishersCertificate' -or $policy.LocalName -eq 'EnterpriseTrustCertificate' -or
                $policy.LocalName -eq 'IntermediateCertificationAuthorityCertificate' -or $policy.LocalName -eq 'EFSRecoveryAgent')
        {
            $DescList += "IssuedTo: $($policy.IssuedTo)"
            $DescList += "IssuedBy: $($policy.IssuedBy)"
            $DescList += "ExpirationDate: $($policy.ExpirationDate)"
            ForEach ($byte in (New-Object System.Security.Cryptography.SHA256Managed).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($policy.Data)))
            {
                $Desc += $byte.ToString('x2')
            }
            $DescList += "CertFileSha256: $($Desc)"
            If ($policy.CertificatePurpose)
            {
                $DescList += "CertificatePurpose: $($policy.CertificatePurpose.Purpose.ToString())"
            }
        }
        Else
        {
            ForEach ($attr in $policy.ChildNodes)
            {
                $DescList += "$($attr.LocalName): $($attr.'#text')"
            }
        }

        $Desc = $DescList -join "`n"
        If ($Desc -ne '')
        {
            $returnArray += New-Object PSObject -Property @{
                                PolicyName = "$($policyName)-$($policy.LocalName)"
                                Additional = $Desc
                            }
        }
    }

    Return $returnArray
}

#  Parse Internet Explorer Maintenance settings
Function Get-XMLInternetExplorerMaintenance
{
    Param(
        $Policies
    )

    [PSObject[]]$returnArray = @()
    [String]$policyName = 'InternetExplorerMaint'
    [String]$subName = ''
    [String[]]$DescList = @()
    
    ForEach ($policy in $Policies.ChildNodes)
    {
        $DescList = @()
        $Desc = ''
        $subName = ''
        
        If ($policy.LocalName -eq 'EscOffLocalSites' -or $policy.LocalName -eq 'EscOffTrustedSites' -or $policy.LocalName -eq 'EscOffRestrictedSites' -or $policy.LocalName -eq 'EscOffSecurityZoneAndPrivacy')
        {
            #  Process later
        }
        Else
        {
            If ($policy.ChildNodes.Count -gt 1)
            {
                $subName = "-$($policy.LocalName)"
                ForEach ($attr in $policy.ChildNodes)
                {
                    If ($attr.ChildNodes.Count -gt 1)
                    {
                        ForEach ($subattr in $attr.ChildNodes)
                        {
                            $DescList += "$($attr.LocalName) $($subattr.LocalName): $($subattr.'#text')$($subattr.Value)"
                        }
                    }
                    Else
                    {
                        $DescList += "$($attr.LocalName): $($attr.'#text')"
                    }
                }
            }
            Else
            {
                $DescList += "$($policy.LocalName): $($policy.'#text')$($policy.Value)"
            }
        }

        If ($DescList.Count -gt 0)
        {
            $Desc = $DescList -join "`n"

            $returnArray += New-Object PSObject -Property @{
                                PolicyName = "$($policyName)$($subName)"
                                Additional = $Desc
                            }
        }
    }

    
    If ($Policies.EscOffSecurityZoneAndPrivacy)
    {
        ForEach ($attr in $Policies.EscOffSecurityZoneAndPrivacy.ChildNodes)
        {
            $subName = ''
            $DescList = @()
            $Desc = ''

            If ($attr.LocalName -eq 'Privacy')
            {
                $DescList += "PrivacyLevel: $($attr.PrivacyLevel)"
            }
            ElseIf ($attr.LocalName -eq 'ZoneSettings')
            {
                $subName = "Zone$($attr.Name)"
                $DescList += "SecurityLevel: $($attr.SecurityLevel)"
                $DescList += "RequireVerification: $($attr.RequireVerification)"
                If ($attr.SecurityLevel -eq 'Custom')
                {
                    ForEach ($subAttr in $attr.CustomSetting)
                    {
                        $DescList += "$($subAttr.Name): $($subAttr.Value)"
                    }
                }
            }
            ElseIf ($attr.LocalName -eq 'LocalZoneSettings')
            {
                $subName = "$($attr.LocalName)"
                ForEach ($subAttr in $attr.ChildNodes)
                {
                    $DescList += "$($subAttr.LocalName): $($subAttr.'#text')"
                }
            }
            Else
            {
                Write-Warning "Unknown value in EscOffSecurityZoneAndPrivacy $($attr.LocalName): $($attr.'#text')$($attr.Value)"
                $DescList += "$($attr.LocalName): $($attr.'#text')"
            }

            $Desc = $DescList -join "`n"

            $returnArray += New-Object PSObject -Property @{
                                PolicyName = "$($policyName)$($subName)"
                                Additional = $Desc
                            }
        }
    }
    
    If ($Policies.EscOffLocalSites)
    {
        $returnArray += New-Object PSObject -Property @{
                            PolicyName = "$($policyName)-IntranetSites"
                            Additional = ($Policies.EscOffTrustedSites).Value -join "`n"
                        }
    }
    If ($Policies.EscOffTrustedSites)
    {
        $returnArray += New-Object PSObject -Property @{
                            PolicyName = "$($policyName)-TrustedSites"
                            Additional = ($Policies.EscOffTrustedSites).Value -join "`n"
                        }
    }
    If ($Policies.EscOffRestrictedSites)
    {
        $returnArray += New-Object PSObject -Property @{
                            PolicyName = "$($policyName)-RestrictedSites"
                            Additional = ($Policies.EscOffTrustedSites).Value -join "`n"
                        }
    }

    Return $returnArray
}

#  Parse Scripts settings
Function Get-XMLScripts
{
    Param(
        $Policies
    )

    [PSObject[]]$returnArray = @()
    [String]$policyName = 'Scripts'
    [String]$subName = ''
    [String[]]$DescList = @()
    
    If (($Policies.GetType()).Name -eq 'XmlElement')
    {
        $DescList += $Policies.Command
        If ($Policies.Parameters)
        {
            $DescList += "Parameters: $($Policies.Parameters)"
        }
        If ($Policies.Order -ne '0')
        {
            $DescList += "Order: $($Policies.Order)"
        }
        If ($Policies.RunOrder -ne 'PSNotConfigured')
        {
            $DescList += "RunOrder: $($Policies.RunOrder)"
        }

        $Desc = $DescList -join "`n"

        $returnArray += New-Object PSObject -Property @{
                            PolicyName = "$($policyName)-$($Policies.Type)"
                            Additional = $Desc
                        }
    }
    Else
    {
        ForEach ($Policy in $Policies)
        {
            $DescList = @()
            $DescList += $Policy.Command
            If ($Policy.Parameters)
            {
                $DescList += "Parameters: $($Policy.Parameters)"
            }
            If ($Policy.Order -ne '0')
            {
                $DescList += "Order: $($Policy.Order)"
            }
            If ($Policy.RunOrder -ne 'PSNotConfigured')
            {
                $DescList += "RunOrder: $($Policy.RunOrder)"
            }

            $Desc = $DescList -join "`n"

            $returnArray += New-Object PSObject -Property @{
                                PolicyName = "$($policyName)-$($Policy.Type)"
                                Additional = $Desc
                            }
        }
    }

    Return $returnArray
}

#  Parse Services settings
Function Get-XMLServices
{
    Param(
        $Policies
    )

    [PSObject[]]$returnArray = @()
    [String]$policyName = 'NTServices'
    [String]$subName = ''
    [String[]]$DescList = @()

    ForEach ($Policy in $Policies)
    {
        $DescList = @()
        $DescList += $Policy.Properties.serviceName
        ForEach ($attr in $Policy.ChildNodes)
        {
            If ($attr.LocalName -eq 'GPOSettingOrder')
            {
                #  Skip
            }
            ElseIf ($attr.LocalName -eq 'Properties')
            {
                ForEach ($subattr in $attr.Attributes)
                {
                    If ($subattr.LocalName -eq 'serviceName' -or ($subattr.LocalName -eq 'startupType' -and $subattr.'#text' -eq 'NOCHANGE'))
                    {
                        #  skip
                    }
                    Else
                    {
                        $DescList += "$($subattr.LocalName): $($subattr.'#text')"
                    }
                }
            }
            ElseIf ($attr.LocalName -eq 'Filters')
            {
                If ($attr.IsEmpty -eq $false)
                {
                    #  This is hopefully good enough for doing a targetting filter
                    If ($attr.InnerXml -match '(^.+?\s)(.+?)(\sxmlns.*$)')
                    {
                        $DescList += "$($attr.LocalName): $($Matches[2])"
                    }
                }
            }
            Else
            {
                $DescList += "$($attr.LocalName): $($attr.'#text')"
            }
        }

        $Desc = $DescList -join "`n"

        $returnArray += New-Object PSObject -Property @{
                            PolicyName = "$($policyName)"
                            Additional = $Desc
                        }
    }

    Return $returnArray
}


Function Parse-XMLGPOSettings
{
    Param(
        $Reports
    )

    #  XML Elements to skip in the "Windows Firewall" section
    [String[]]$ignoreListFirewall = @('Dir')
    #  Used to reduce the size of the computer/user type of GPO field in the Out-GridView view
    $PolicyTypes = @(@('Computer', 'C'), @('User', 'U'))
    #  Final list of policies.  Will be an array of custom objects
    [PSObject[]]$PolicyList = @()
    [Int32]$GPONum = 0

    #  Iterate through each of the GPOs
    ForEach ($gpo in $Reports.GPOS.GPO)
    {
        #  Remove the curly braces off the GPO's GUID
        [String]$identifier = $gpo.Identifier.Identifier.'#text'.Replace('{','').Replace('}','')
        [String]$GPOName = $gpo.Name
        [Int32]$LinkCount = ($gpo.LinksTo | Where-Object {$_.Enabled -eq 'true'} | Measure-Object).Count
        [Int32]$PermissionCount = 0
        
        If ($gpo.Computer.VersionDirectory -ne $gpo.Computer.VersionSysvol)
        {
            Write-Warning "$($GPONum) '$($GPOName)' version mismatch on Computer side. $($gpo.Computer.VersionDirectory) (AD), $($gpo.Computer.VersionSysvol) (SYSVOL)"
        }

        If ($gpo.User.VersionDirectory -ne $gpo.User.VersionSysvol)
        {
            Write-Warning "$($GPONum) '$($GPOName)' version mismatch on User side. $($gpo.User.VersionDirectory) (AD), $($gpo.User.VersionSysvol) (SYSVOL)"
        }
        
        ForEach ($Permission in $gpo.SecurityDescriptor.Permissions.ChildNodes)
        {
            If ($Permission.LocalName -eq 'TrusteePermissions' -and $Permission.Type.InnerText -eq 'Allow' -and $Permission.Standard.InnerText -like "*Apply Group Policy*")
            {
                $PermissionCount++
            }
        }

        #  Process Computer then User side settings
        ForEach ($PolicyType in $PolicyTypes)
        {
            #  Each individual setting appears to be in its own ExtensionData element
            ForEach ($extension in $gpo.($Policytype[0]).ExtensionData)
            {
                #  GPO settings seem to fall into three categories
                #  1. A registry setting set via some known ADMX template (Registry)
                #  2. A custom registry setting not using an ADMX template (Windows Registry)
                #  3. Non-registry settings parsed by some internal Windows mechanism
                If ([String]($extension.Name) -eq 'Registry')
                {
                    ForEach ($policy in $extension.Extension.Policy)
                    {
                        [String]$policyName = $policy.Name
                        [String]$state = $policy.State
                        [String]$Additional = ''
                        
                        $Additional = Get-RegistryValues $Policy

                        $PolicyList += New-Object PSObject -Property @{
	                                        Identifier = $identifier
	                                        GPOName = $GPOName
                                            T = $PolicyType[1]
                                            L = $LinkCount
                                            PolicyName = $policyName
                                            State = $state
                                            Additional = $Additional
                                            P = $PermissionCount
                                        }
                    }
                }
                ElseIf ([String]($extension.Name) -eq 'Windows Registry')
                {
                    [PSObject[]]$registrySettings = @()
                    [String]$policyName = 'RegistrySettings'
                    $registrySettings = Get-XMLTreeRegistryValues $extension.Extension.RegistrySettings
                    ForEach ($registrySetting in $registrySettings)
                    {
                        Add-Member -InputObject $registrySetting -MemberType NoteProperty -Name 'Identifier' -Value $identifier
                        Add-Member -InputObject $registrySetting -MemberType NoteProperty -Name 'GPOName' -Value $GPOName
                        Add-Member -InputObject $registrySetting -MemberType NoteProperty -Name 'T' -Value $PolicyType[1]
                        Add-Member -InputObject $registrySetting -MemberType NoteProperty -Name 'L' -Value $LinkCount
                        Add-Member -InputObject $registrySetting -MemberType NoteProperty -Name 'PolicyName' -Value $policyName
                        Add-Member -InputObject $registrySetting -MemberType NoteProperty -Name 'P' -Value $PermissionCount
                    }
                    If ($registrySettings.Count -ne 0)
                    {
                        $PolicyList += $registrySettings
                    }
                }
                ElseIf ([String]($extension.Name) -eq 'Windows Firewall')
                {
                    ForEach ($tempEntry in (Get-XMLFirewallSettings $extension.Extension.ChildNodes $identifier $GPOName $PolicyType[1] $LinkCount $PermissionCount))
                    {
                        $PolicyList += $tempEntry
                    }
                }
                ElseIf ([String]($extension.Name) -eq 'Advanced Audit Configuration')
                {
                    ForEach ($tempEntry in (Get-XMLAdvancedAuditSettings $extension.Extension.ChildNodes $identifier $GPOName $PolicyType[1] $LinkCount $PermissionCount))
                    {
                        $PolicyList += $tempEntry
                    }
                }
                ElseIf ([String]($extension.Name) -eq 'WLanSvc Networks')
                {
                    $tempEntries = @()
                    $tempEntries += Get-XMLWLanSvcNetworks $extension.Extension.WLanSvcSetting.ChildNodes
                    ForEach ($tempEntry in $tempEntries)
                    {
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'Identifier' -Value $identifier
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'GPOName' -Value $GPOName
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'T' -Value $PolicyType[1]
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'L' -Value $LinkCount
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'P' -Value $PermissionCount
                    }
                    If ($tempEntries.Count -ne 0)
                    {
                        $PolicyList += $tempEntries
                    }
                }
                ElseIf ([String]($extension.Name) -eq 'LanSvc Networks')
                {
                    $tempEntries = @()
                    $tempEntries += Get-XMLLanSvcNetworks $extension.Extension.Dot3SvcSetting.ChildNodes
                    ForEach ($tempEntry in $tempEntries)
                    {
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'Identifier' -Value $identifier
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'GPOName' -Value $GPOName
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'T' -Value $PolicyType[1]
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'L' -Value $LinkCount
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'P' -Value $PermissionCount
                    }
                    If ($tempEntries.Count -ne 0)
                    {
                        $PolicyList += $tempEntries
                    }
                }
                ElseIf ([String]($extension.Name) -eq 'Public Key')
                {
                    $tempEntries = @()
                    $tempEntries += Get-XMLPublicKey $extension.Extension.ChildNodes
                    ForEach ($tempEntry in $tempEntries)
                    {
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'Identifier' -Value $identifier
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'GPOName' -Value $GPOName
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'T' -Value $PolicyType[1]
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'L' -Value $LinkCount
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'P' -Value $PermissionCount
                    }
                    If ($tempEntries.Count -ne 0)
                    {
                        $PolicyList += $tempEntries
                    }
                }
                ElseIf ([String]($extension.Name) -eq 'Internet Explorer Maintenance')
                {
                    $tempEntries = @()
                    $tempEntries += Get-XMLInternetExplorerMaintenance $extension.Extension
                    ForEach ($tempEntry in $tempEntries)
                    {
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'Identifier' -Value $identifier
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'GPOName' -Value $GPOName
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'T' -Value $PolicyType[1]
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'L' -Value $LinkCount
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'P' -Value $PermissionCount
                    }
                    If ($tempEntries.Count -ne 0)
                    {
                        $PolicyList += $tempEntries
                    }
                }
                ElseIf ([String]($extension.Name) -eq 'Scripts')
                {
                    $tempEntries = @()
                    $tempEntries += Get-XMLScripts $extension.Extension.Script
                    ForEach ($tempEntry in $tempEntries)
                    {
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'Identifier' -Value $identifier
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'GPOName' -Value $GPOName
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'T' -Value $PolicyType[1]
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'L' -Value $LinkCount
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'P' -Value $PermissionCount
                    }
                    If ($tempEntries.Count -ne 0)
                    {
                        $PolicyList += $tempEntries
                    }
                }
                ElseIf ([String]($extension.Name) -eq 'Services')
                {
                    $tempEntries = @()
                    If (($extension.Extension.NTServices.NTService.GetType()).Name -eq 'Object[]')
                    {
                        $tempEntries += Get-XMLServices $extension.Extension.NTServices.NTService
                    }
                    Else
                    {
                        $tempEntries += Get-XMLServices @($extension.Extension.NTServices.NTService)
                    }
                    
                    ForEach ($tempEntry in $tempEntries)
                    {
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'Identifier' -Value $identifier
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'GPOName' -Value $GPOName
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'T' -Value $PolicyType[1]
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'L' -Value $LinkCount
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'P' -Value $PermissionCount
                    }
                    If ($tempEntries.Count -ne 0)
                    {
                        $PolicyList += $tempEntries
                    }
                }
                ElseIf ([String]($extension.Name) -eq 'Security')
                {
                    $tempEntries = @()
                    $SecurityChildren = @()
                    $SecurityChildren = ($extension.ChildNodes).ChildNodes | Where-Object {$_.LocalName -ne '#text'} | Group-Object LocalName
                    ForEach ($SecurityChild in $SecurityChildren)
                    {
                        $tempEntriesInner = @()
                        If ($SecurityChild.Name -eq 'UserRightsAssignment')
                        {
                            $tempEntries += Get-XMLUserRightsAssignment $SecurityChild.Group
                        }
                        ElseIf ($SecurityChild.Name -eq 'SecurityOptions')
                        {
                            $tempEntries += Get-XMLSecurityOptions $SecurityChild.Group
                        }
                        ElseIf ($SecurityChild.Name -eq 'Audit')
                        {
                            $tempEntries += Get-XMLTreeComplexValues $SecurityChild.Group '' 'Security Audit'
                        }
                        ElseIf ($SecurityChild.Name -eq 'SystemServices')
                        {
                            $tempEntries += Get-XMLSecuritySystemServices $SecurityChild.Group
                        }
                        ElseIf ($SecurityChild.Name -eq 'Account')
                        {
                            $tempEntries += Get-XMLTreeComplexValues $SecurityChild.Group '' 'Security Account'
                        }
                        ElseIf ($SecurityChild.Name -eq 'RestrictedGroups')
                        {
                            $tempEntries += Get-XMLSecurityRestrictedGroups $SecurityChild.Group
                        }
                        ElseIf ($SecurityChild.Name -eq 'Registry')
                        {
                            $tempEntries += Get-XMLSecurityRegistry $SecurityChild.Group
                        }
                        ElseIf ($SecurityChild.Name -eq 'EventLog')
                        {
                            $tempEntries += Get-XMLSecurityEventLog $SecurityChild.Group
                        }
                        ElseIf ($SecurityChild.Name -eq 'File')
                        {
                            $tempEntries += Get-XMLSecurityFile $SecurityChild.Group
                        }
                        Else
                        {
                            Write-Warning "Unknown Security setting type '$($SecurityChild.Name)' in $($GPONum) $($GPOName) in $($Policytype[0]) side"
                            $tempEntries += Get-XMLTreeComplexValues $SecurityChild.Group '' 'Security'
                        }
                    }
                    ForEach ($tempEntry in $tempEntries)
                    {
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'Identifier' -Value $identifier
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'GPOName' -Value $GPOName
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'T' -Value $PolicyType[1]
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'L' -Value $LinkCount
                        Add-Member -InputObject $tempEntry -MemberType NoteProperty -Name 'P' -Value $PermissionCount
                    }
                    If ($tempEntries.Count -ne 0)
            
