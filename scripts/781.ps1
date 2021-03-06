## Tab-Completion
#################
## Please dot souce this script file.
## In first loading, it may take a several minutes, in order to generate ProgIDs and TypeNames list.
## What this can do is:
##
## [datetime]::n<tab>
## [datetime]::now.d<tab>
## $a = New-Object "Int32[,]" 2,3; $b = "PowerShell","PowerShell"
## $c = [ref]$a; $d = [ref]$b,$c
## $d[0].V<tab>[0][0].Get<tab>
## $d[1].V<tab>[0,0].tos<tab>
## $function:a<tab>
## $env:a<tab>
## [System.Type].a<tab>
## [datetime].Assembly.a<tab>
## ).a<tab> # shows System.Type properties and methods...

## #native command name expansion
## fsu<tab>

## #command option name expansion (for fsutil ipconfig net powershell only)
## fsutil <tab>
## ipconfig <tab>
## net <tab>
## powershell <tab>

## #TypeNames expansion
## [Dec<tab>
## [Microsoft.PowerShell.Com<tab>
## New-Object -TypeName IO.Dir<tab>
## New-Object System.Management.Auto<tab>

## #ProgIDs expansion
## New-Object -Com shel<tab>

## #Enum option expansion
## Set-ExecutionPolicy <tab>
## Set-ExecutionPolicy All<tab>
## Set-ExcusionPolisy -ex <tab>
## Get-TraceSource@Inte<tab>
## iex -Err <tab> -wa Sil<tab>

## #WmiClasses expansion
## Get-WmiObject -class Win32_<tab>
## gwmi __Instance<tab>

## #Encoding expansion
## [Out-File | Export-CSV | Select-String | Export-Clixml] -enc <tab>
## [Add-Content | Get-Content | Set-Content} -Encoding Big<tab>

## #PSProvider name expansion
## [Get-Location | Get-PSDrive | Get-PSProvider | New-PSDrive | Remove-PSDrive] [-PSProvider] <tab>
## Get-PSProvider <tab>
## pwd -psp al<tab>

## #PSDrive name expansion
## [Get-PSDrive | New-PSDrive | Remove-PSDrive] [-Name] <tab>
## Get-PSDrive <tab>
## pwd -psd <tab>

## #PSSnapin name expansion
## [Add-PSSnapin | Get-PSSnapin | Remove-PSSnapin ] [-Name] <tab>
## Get-Command -PSSnapin <tab>
## Remove-PSSnapin <tab>
## Get-PSSnapin M<tab>

## #Eventlog name and expansion
## Get-Eventlog -Log <tab>
## Get-Eventlog w<tab>

## #Eventlog's entrytype expansion
## Get-EventLog -EntryType <tab>
## Get-EventLog -EntryType Er<tab>
## Get-EventLog -Ent <tab>

## #Service name expansion
## [Get-Service | Restart-Service | Resume-Service | Start-Service | Stop-Service | Suspend-Service] [-Name] <tab>
## New-Service -DependsOn <tab>
## New-Service -Dep e<tab>
## Get-Service -n <tab>
## Get-Service <tab>,a<tab>,p<tab>
## gsv <tab>

## #Service display name expansion
## [Get-Service | Restart-Service | Resume-Service | Start-Service | Stop-Service | Suspend-Service] [-DisplayName] <tab>
## Get-Service -Dis <tab>
## gsv -Dis <tab>,w<tab>,b<tab>

## #Cmdlet and Topic name expansion
## Get-Help [-Name] about_<tab>
## Get-Help <tab>

## #Category name expansion
## Get-Help -Category c<tab>,<tab>

## #Command name expansion
## Get-Command [-Name] <tab>
## Get-Command -Name <tab>
## gcm a<tab>,<tab>

## #Scope expansion
## [Clear-Variable | Export-Alias | Get-Alias | Get-PSDrive | Get-Variable | Import-Alias
## New-Alias | New-PSDrive | New-Variable | Remove-Variable | Set-Alias | Set-Variable] -Scope <tab>
## Clear-Variable -Scope G<tab>
## Set-Alias  -s <tab>

## #Process name expansion
## [Get-Process | Stop-Process] [-Name] <tab>
## Stop-Process -Name <tab>
## Stop-Process -N pow<tab>
## Get-Process <tab>
## ps power<tab>

## #Trace sources expansion
## [Trace-Command | Get-TraceSource | Set-TraceSource] [-Name] <tab>,a<tab>,p<tab>

## #Trace -ListenerOption expansion
## [Set-TraceSource | Trace-Command] -ListenerOption <tab>
## Set-TraceSource -Lis <tab>,n<tab>

## #Trace -Option expansion
## [Set-TraceSource | Trace-Command] -Option <tab>
## Set-TraceSource -op <tab>,con<tab>

## #ItemType expansion
## New-Item -Item <tab>
## ni -ItemType d<tab>

## #ErrorAction and WarningAction option expansion
## CMDLET [-ErrorAction | -WarningAction] <tab>
## CMDLET -Error s<tab>
## CMDLET -ea con<tab>
## CMDLET -wa <tab>

## #Continuous expansion with comma when parameter can treat multiple option
## # if there are spaces, occur display bug in the line
## # if strings contains '$' or '-', not work
## Get-Command -CommandType <tab>,<tab><tab>,cm<tab>
## pwd -psp <tab>,f<tab>,va<tab>
## Get-EventLog -EntryType <tab>,i<tab>,s<tab>

## #Enum expansion in method call expression
## # this needs one or more spaces after left parenthesis or comma
## $str = "day   night"
## $str.Split( " ",<space>rem<tab>
## >>> $str.Split( " ", "RemoveEmptyEntries" ) <Enter> ERROR
## $str.Split( " ", "RemoveEmptyEntries" -as<space><tab>
## >>> $str.Split( " ", "RemoveEmptyEntries" -as [System.StringSplitOptions] ) <Enter> Success
## $type = [System.Type]
## $type.GetMembers(<space>Def<tab>
## [IO.Directory]::GetFiles( "C:\", "*",<space>All<tab>
## # this can do continuous enum expansion with comma and no spaces
## $type.GetMembers( "IgnoreCase<comma>Dec<tab><comma>In<tab>"
## [IO.Directory]::GetAccessControl( "C:\",<space>au<tab><comma>ac<tab><comma>G<tab>

## #Better '$_.' expansion when cmdlet output objects or method return objects
## ls |group { $_.Cr<tab>.Tost<tab>"y")} | tee -var foo| ? { $_.G<tab>.c<tab> -gt 5 } | % { md $_.N<tab> ; copy $_.G<tab> $_.N<tab>  }
## [IO.DriveInfo]::GetDrives() | ? { $_.A<tab> -gt 1GB }
## $Host.UI.RawUI.GetBufferContents($rect) | % { $str += $_.c<tab> }
## gcm Add-Content |select -exp Par<tab>|select -exp <tab> |
## select -ExpandProperty Par<tab>| | ? { $_.Par<tab>.N<tab> -eq "string" }
## $data = Get-Process
## $data[2,4,5]  | % { $_.<tab>
## #when Get-PipeLineObject failed, '$_.' shows methods and properties name of FileInfo and String and Type

## #Property name expansion
## [ Format-List | Format-Custom | Format-Table | Format-Wide | Compare-Object |
##  ConvertTo-Html | Measure-Object | Select-Object | Group-Object | Sort-Object ] [-Property] <tab>
## Select-Object -ExcludeProperty <tab>
## Select-Object -ExpandProperty <tab>
## gcm Get-Acl|select -exp Par<tab>
## ps |group na<tab>
## ls | ft A<tab>,M<tab>,L<tab>

## #Hashtable key expansion in the variable name and '.<tab>'
## Get-Process | Get-Unique | % { $hash += @{$_.ProcessName=$_} }
## $hash.pow<tab>.pro<tab>

## #Parameter expansion for function, filter and script
## man -f<tab>
## 'param([System.StringSplitOptions]$foo,[System.Management.Automation.ActionPreference]$bar,[System.Management.Automation.CommandTypes]$baz) {}' > foobar.ps1
## .\foobar.ps1 -<tab> -b<tab>

## #Enum expansion for function, filter and scripts
## # this can do continuous enum expansion with comma and no spaces
## .\foobar.ps1 -foo rem<tab> -bar <tab><comma>c<tab><comma>sc<tab> -ea silent<tab> -wa con<tab>

## #Enum expansion for assignment expression
## #needs space(s) after '=' and comma
## #strongly-typed with -as operator and space(s)
## $ErrorActionPreference =<space><tab>
## $cmdtypes = New-Object System.Management.Automation.CommandTypes[] 3
## $cmdtypes =<space><tab><comma><space>func<tab><comma><space>cmd<tab> -as<space><tab>


### Generate ProgIDs list...
if ($_ProgID -eq $null) {
    $_HKCR = [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey("CLSID\")
    [Object[]] $_ProgID = $null
    foreach ( $_subkey in $_HKCR.GetSubKeyNames() )
    {
        foreach ( $_i in [Microsoft.Win32.Registry]::ClassesRoot.OpenSubKey("CLSID\$_subkey\ProgID") )
        {
            if ($_i -ne $null)
            {
                $_ProgID += $_i.GetValue("")
            }
        }
    }
    '$_ProgID was updated...' | Out-Host
    $_ProgID = $_ProgID|sort -Unique

    Set-Content -Value $_ProgID -Path $PSHOME\ProgIDs.txt
    Add-Content -Path $PSHOME\profile.ps1 -Value ';$_ProgID = Get-Content -Path C:\WINDOWS\system32\windowspowershell\v1.0\ProgIDs.txt;'
}

### Generate TypeNames list...

if ( $_TypeNames -eq $null ) {
    [Object[]] $_TypeNames = $null
    foreach ( $_asm in [AppDomain]::CurrentDomain.GetAssemblies() )
    {
        foreach ( $_type in $_asm.GetTypes() )
        {
            $_TypeNames += $_type.FullName
        }
    }
    '$_TypeNames was updated...' | Out-Host
    $_TypeNames = $_TypeNames | sort -Unique

    Set-Content -Value $_TypeNames -Path $PSHOME\TypeNames.txt
    Add-Content -Path $PSHOME\profile.ps1 -Value ';$_TypeNames = Get-Content -Path $PSHOME\TypeNames.txt;'
}

if ( $_TypeNames_System -eq $null ) {
    [Object[]] $_TypeNames_System = $null
    foreach ( $_type in $_TypeNames -like "System.*" )
    {
        $_TypeNames_System += $_type.Substring(7)
    }
    '$_TypeNames_System was updated...' | Out-Host
    Set-Content -Value $_TypeNames_System -Path $PSHOME\TypeNames_System.txt
    Add-Content -Path $PSHOME\profile.ps1 -Value ';$_TypeNames_System = Get-Content -Path $PSHOME\TypeNames_System.txt;'
}

### Generate WMIClasses list...
if ( $_WMIClasses -eq $null ) {
    [Object[]] $_WMIClasses = $null
    foreach ( $_class in gwmi -List )
    {
        $_WMIClasses += $_class.Name
    }
    $_WMIClasses = $_WMIClasses | sort -Unique
    '$_WMIClasses was updated...' | Out-Host
    Set-Content -Value $_WMIClasses -Path $PSHOME\WMIClasses.txt
    Add-Content -Path $PSHOME\profile.ps1 -Value ';$_WMIClasses = Get-Content -Path $PSHOME\WMIClasses.txt;'
}
$global:_snapin = $null

# Load Get-PipeLineObject function for $_ and property name expansion.
$_scriptpath = gi $MyInvocation.MyCommand.Path
iex (". " + (Join-Path $_scriptpath.DirectoryName "Get-PipeLineObject.ps1"))

function TabExpansion {
            # This is the default function to use for tab expansion. It handles simple
            # member expansion on variables, variable name expansion and parameter completion
            # on commands. It doesn't understand strings so strings containing ; | ( or { may
            # cause expansion to fail.

            param($line, $lastWord)

            & {
                # Helper function to write out the matching set of members. It depends
                # on dynamic scoping to get $_base, _$expression and $_pat
                function Write-Members ($sep='.')
                {

                    # evaluate the expression to get the object to examine...
                    Invoke-Expression ('$_val=' + $_expression)

                    if ( $_expression -match '^\$global:_dummy' )
                    {
                        $temp = $_expression -replace '^\$global:_dummy(.*)','$1'
                        $_expression = '$_' + $temp
                    }


                    $_method = [Management.Automation.PSMemberTypes] `
                        'Method,CodeMethod,ScriptMethod,ParameterizedProperty'

                    if ($sep -eq '.')
                    {
                        $members = 
                            (
                                [Object[]](Get-Member -InputObject $_val.PSextended $_pat) + 
                                [Object[]](Get-Member -InputObject $_val.PSadapted $_pat) + 
                                [Object[]](Get-Member -InputObject $_val.PSbase $_pat)
                            )
                        if ( $_val -is [Hashtable] )
                        {
                            [Microsoft.PowerShell.Commands.MemberDefinition[]]$_keys = $null
                            foreach ( $_name in $_val.Keys )
                            {
                                $_keys += `
                                New-Object Microsoft.PowerShell.Commands.MemberDefinition `
                                [int],$_name,"Property",0
                            }

                            $members += [Object[]]$_keys | ? { $_.Name -like $_pat }
                        }

                        foreach ($_m in $members | sort membertype,name -Unique)
                            {
                                if ($_m.MemberType -band $_method)
                                {
                                    # Return a method...
                                    $_base + $_expression + $sep + $_m.name + '('
                                }
                                else {
                                    # Return a property...
                                    $_base + $_expression + $sep + $_m.name
                                }
                            }
                        }

                    else
                    {
                    foreach ($_m in Get-Member -Static -InputObject $_val $_pat |
                        Sort-Object membertype,name)
                       {
                           if ($_m.MemberType -band $_method)
                           {
                               # Return a method...
                               $_base + $_expression + $sep + $_m.name + '('
                           }
                           else {
                               # Return a property...
                               $_base + $_expression + $sep + $_m.name
                           }
                        }
                    }
                }

                switch -regex ($lastWord)
                {

                    # Handle property and method expansion at '$_'
                    '(^.*)(\$_\.)(\w*)$' {
                        $_base = $matches[1]
                        $_expression = '$global:_dummy'
                        $_pat = $matches[3] + '*'
                        $global:_dummy = $null
                        Get-PipeLineObject
                        if ( $global:_dummy -eq $null )
                        {

                            if ( $global:_exp -match '^\$.*\(.*$' )
                            {
                                $type = ( iex $_exp.Split("(")[0] ).OverloadDefinitions[0].Split(" ")[0] -replace '\[[^\[\]]*\]$' -as [type]

                                if ( $_expression -match '^\$global:_dummy' )
                                {
                                    $temp = $_expression -replace '^\$global:_dummy(.*)','$1'
                                    $_expression = '$_' + $temp
                                }

                                foreach ( $_m in $type.GetMembers() | sort membertype,name | group name | ? { $_.Name -like $_pat } | % { $_.Group[0] } )
                                {
                                   if ($_m.MemberType -eq "Method")
                                   {
                                       $_base + $_expression + '.' + $_m.name + '('
                                   }
                                   else {
                                       $_base + $_expression + '.' + $_m.name
                                   }
                                }
                                break;
                            }
                            elseif ( $global:_exp -match '^\[.*\:\:.*\(.*$' )
                            {
                                $tname, $mname = $_exp.Split(":(", "RemoveEmptyEntries"-as [System.StringSplitOptions])[0,1]
                                $type = @(iex ($tname + '.GetMember("' + $mname + '")'))[0].ReturnType.FullName -replace '\[[^\[\]]*\]$' -as [type]

                                if ( $_expression -match '^\$global:_dummy' )
                                {
                                    $temp = $_expression -replace '^\$global:_dummy(.*)','$1'
                                    $_expression = '$_' + $temp
                                }

                                foreach ( $_m in $type.GetMembers() | sort membertype,name | group name | ? { $_.Name -like $_pat } | % { $_.Group[0] } )
                                {
                                   if ($_m.MemberType -eq "Method")
                                   {
                                       $_base + $_expression + '.' + $_m.name + '('
                                   }
                                   else {
                                       $_base + $_expression + '.' + $_m.name
                                   }
                                }
                                break;
                            }
                            elseif ( $global:_exp -match '^(\$\w+(\[[0-9,\.]+\])*(\.\w+(\[[0-9,\.]+\])*)*)$' )
                            {
                                $global:_dummy = @(iex $Matches[1])[0]
                            }
                            else
                            {
                                $global:_dummy =  $global:_mix
                            }
                        }

                        Write-Members
                        break;
                    }

                    # Handle property and method expansion rooted at variables...
                    # e.g. $a.b.<tab>
                    '(^.*)(\$(\w|\.)+)\.(\w*)$' {
                        $_base = $matches[1]
                        $_expression = $matches[2]
                        [void] ( iex "$_expression.IsDataLanguageOnly" ) # for [ScriptBlock]
                        $_pat = $matches[4] + '*'
                        if ( $_expression -match '^\$_\.' )
                        {
                            $_expression = $_expression -replace '^\$_(.*)',('$global:_dummy' + '$1')
                        }
                        Write-Members
                        break;
                    }

                    # Handle simple property and method expansion on static members...
                    # e.g. [datetime]::n<tab>
                    '(^.*)(\[(\w|\.)+\])\:\:(\w*)$' {
                        $_base = $matches[1]
                        $_expression = $matches[2]
                        $_pat = $matches[4] + '*'
                        Write-Members '::'
                        break;
                    }

                    # Handle complex property and method expansion on static members
                    # where there are intermediate properties...
                    # e.g. [datetime]::now.d<tab>
                    '(^.*)(\[(\w|\.)+\]\:\:(\w+\.)+)(\w*)$' {
                        $_base = $matches[1]  # everything before the expression
                        $_expression = $matches[2].TrimEnd('.') # expression less trailing '.'
                        $_pat = $matches[5] + '*'  # the member to look for...
                        Write-Members
                        break;
                    }

                    # Handle variable name expansion...
                    '(^.*\$)(\w+)$' {
                        $_prefix = $matches[1]
                        $_varName = $matches[2]
                        foreach ($_v in Get-ChildItem ('variable:' + $_varName + '*'))
                        {
                            $_prefix + $_v.name
                        }
                        break;
                    }

                    # Handle env&function drives variable name expansion...
                    '(^.*\$)(.*\:)(\w+)$' {
                        $_prefix = $matches[1]
                        $_drive = $matches[2]
                        $_varName = $matches[3]
                        if ($_drive -eq "env:" -or $_drive -eq "function:")
                        {
                            foreach ($_v in Get-ChildItem ($_drive + $_varName + '*'))
                            {
                                $_prefix + $_drive + $_v.name
                            }
                        }
                        break;
                    }

                    # Handle array's element property and method expansion
                    # where there are intermediate properties...
                    # e.g. foo[0].n.b<tab>
                    '(^.*)(\$((\w+\.)|(\w+(\[(\w|,)+\])+\.))+)(\w*)$'
                    {
                        $_base = $matches[1]
                        $_expression = $matches[2].TrimEnd('.')
                        $_pat = $Matches[8] + '*'
                        [void] ( iex "$_expression.IsDataLanguageOnly" ) # for [ScriptBlock]
                        if ( $_expression -match '^\$_\.' )
                        {
                            $_expression = $_expression -replace '^\$_(.*)',('$global:_dummy' + '$1')
                        }
                        Write-Members
                        break;
                    }

                    # Handle property and method expansion rooted at type object...
                    # e.g. [System.Type].a<tab>
                    '(^\[(\w|\.)+\])\.(\w*)$'
                    {
                        if ( $(iex $Matches[1]) -isnot [System.Type] ) { break; }
                        $_expression = $Matches[1]
                        $_pat = $Matches[$matches.Count-1] + '*'
                        Write-Members
                        break;
                    }

                    # Handle complex property and method expansion on type object members
                    # where there are intermediate properties...
                    # e.g. [datetime].Assembly.a<tab>
                    '^(\[(\w|\.)+\]\.(\w+\.)+)(\w*)$' {
                        $_expression = $matches[1].TrimEnd('.') # expression less trailing '.'
                        $_pat = $matches[4] + '*'  # the member to look for...
                        if ( $(iex $_expression) -eq $null ) { break; }
                        Write-Members
                        break;
                    }

                    # Handle property and method expansion rooted at close parenthes...
                    # e.g. (123).a<tab>
                    '^(.*)\)((\w|\.)*)\.(\w*)$' {
                        $_base = $Matches[1] + ")"
                        if ( $matches[3] -eq $null) { $_expression = '[System.Type]' }
                        else { $_expression = '[System.Type]' + $Matches[2] }
                        $_pat = $matches[4] + '*'
                        iex "$_expression | Get-Member $_pat | sort MemberType,Name" |
                        % {
                            if ( $_.MemberType -like "*Method*" -or $_.MemberType -like "*Parameterized*" ) { $parenthes = "(" }
                            if ( $Matches[2] -eq "" ) { $_base + "." + $_.Name + $parenthes }
                            else { $_base + $Matches[2] + "." + $_.Name + $parenthes }
                          }
                        break;
                    }

                    # Handle .NET type name expansion ...
                    # e.g. [Microsoft.PowerShell.Com<tab>
                    '^\[((\w+\.?)+)$' {
                        $_opt = $matches[1] + '*'
                        foreach ( $_exp in $_TypeNames_System -like $_opt )
                        {
                            '[' + $_exp
                        }
                        foreach ( $_exp in $_TypeNames -like $_opt )
                        {
                            '[' + $_exp
                        }
                        break;
                    }

                    # Do completion on parameters...
                    '^-([\w0-9]*)' {
                        $_pat = $matches[1] + '*'

                        # extract the command name from the string
                        # first split the string into statements and pipeline elements
                        # This doesn't handle strings however.
                        $_cmdlet = [regex]::Split($line, '[|;=]')[-1]

                        #  Extract the trailing unclosed block e.g. ls | foreach { cp
                        if ($_cmdlet -match '\{([^\{\}]*)$')
                        {
                            $_cmdlet = $matches[1]
                        }

                        # Extract the longest unclosed parenthetical expression...
                        if ($_cmdlet -match '\(([^()]*)$')
                        {
                            $_cmdlet = $matches[1]
                        }

                        # take the first space separated token of the remaining string
                        # as the command to look up. Trim any leading or trailing spaces
                        # so you don't get leading empty elements.
                        $_cmdlet = $_cmdlet.Trim().Split()[0]

                        # now get the info object for it...
                        $_cmdlet = @(Get-Command -type 'cmdlet,alias,function,filter,ExternalScript' $_cmdlet)[0]

                        # loop resolving aliases...
                        while ($_cmdlet.CommandType -eq 'alias')
                        {
                            $_cmdlet = @(Get-Command -type 'cmdlet,alias,function,filter,ExternalScript' $_cmdlet.Definition)[0]
                        }

                        if ( $_cmdlet.CommandType -eq "Cmdlet" )
                        {
                            # expand the parameter sets and emit the matching elements
                            foreach ($_n in $_cmdlet.ParameterSets |
                                Select-Object -expand parameters | Sort-Object -Unique name)
                            {
                                $_n = $_n.name
                                if ($_n -like $_pat) { '-' + $_n }
                            }
                            break;
                        }

                        if ( "ExternalScript", "Function", "Filter" -contains $_cmdlet.CommandType )
                        {
                            if ( $_cmdlet.CommandType -eq "ExternalScript" )
                            {
                                $_fsr = New-Object IO.StreamReader $_cmdlet.Definition
                                $_def = "Function _Dummy { $($_fsr.ReadToEnd()) }"
                                $_fsr.Close()
                                iex $_def
                                $_cmdlet = "_Dummy"
                            }

                            if ( ((gi "Function:$_cmdlet").Definition -replace '\n').Split("{")[0] -match 'param\((.*\))\s*[;\.&a-zA-Z]*\s*$' )
                            {
                                ( ( ( $Matches[1].Split('$', "RemoveEmptyEntries" -as [System.StringSplitOptions]) -replace `
                                '^(\w+)(.*)','$1' ) -notmatch '^\s+$' ) -notmatch '^\s*\[.*\]\s*$' ) -like $_pat | sort | % { '-' + $_ }
                            }
                            break;
                        }

                    }


                    # try to find a matching command...
                    default {

                        $lastex =  [regex]::Split($line, '[|;]')[-1]
                        if ( $lastex -match '^\s*(\$\w+(\[[0-9,]+\])*(\.\w+(\[[0-9,]+\])*)*)\s*=\s+(("\w+"\s*,\s+)*)"\w+"\s*-as\s+$' )
                        {
                            if ( $Matches[6] -ne $nul )
                            {
                            $brackets = "[]"
                            }
                            '['+ $global:_enum + $brackets + ']'
                            break;
                        }


                        if ( $lastex -match '^\s*(\$\w+(\[[0-9,]+\])*(\.\w+(\[[0-9,]+\])*)*)\s*=\s+(("\w+"\s*,\s+)*)\s*(\w*)$' )
                        {
                            $_pat = $Matches[7] + '*'

                            $_type = @(iex $Matches[1])[0].GetType()
                            if ( $_type.IsEnum )
                            {
                                $global:_enum = $_type.FullName
                                [Enum]::GetValues($_type) -like $_pat -replace '^(.*)$','"$1"'
                                break;
                            }
                        }

                        $lastex =  [regex]::Split($line, '[|;=]')[-1]
                        if ($lastex  -match '[[$].*\w+\(.*-as\s*$')
                        {
                            '['+ $global:_enum + ']'
                        }
                        elseif ( $lastex -match '([[$].*(\w+))\((.*)$' )
                        #elseif ( $lastex -match '([[$].*(\w+))\(([^)]*)$' )
                        {
                            $_method = $Matches[1]

                            if ( $Matches[3] -match "(.*)((`"|')(\w+,)+(\w*))$" )
                            {
                                $continuous = $true
                                $_opt =  $Matches[5] + '*'
                                $_base =  $Matches[2].TrimStart('"') -replace '(.*,)\w+$','$1'
                                $position = $Matches[1].Split(",").Length
                            }
                            else
                            {
                                $continuous = $false
                                $_opt = ($Matches[3].Split(',')[-1] -replace '^\s*','') + "*"
                                $position = $Matches[3].Split(",").Length
                            }

                            if ( ($_mdefs = iex ($_method + ".OverloadDefinitions")) -eq $null )
                            {
                                $tname, $mname = $_method.Split(":", "RemoveEmptyEntries" -as [System.StringSplitOptions])
                                $_mdefs = iex ($tname + '.GetMember("' + $mname + '") | % { $_.ToString() }')
                            }

                            foreach ( $def in $_mdefs )
                            {
                                [void] ($def -match '\((.*)\)')
                                foreach ( $param in [regex]::Split($Matches[1], ', ')[$position-1] )
                                {
                                    if ($param -eq $null -or $param -eq "")
                                    {
                                        continue;
                                    }
                                    $type = $param.split()[0]

                                    if ( $type -like '*`[*' -or $type -eq "Params" -or $type -eq "" )
                                    {
                                        continue;
                                    }
                                    $fullname  = @($_typenames -like "*$type*")
                                    foreach ( $name in $fullname )
                                    {
                                        if ( $continuous -eq $true -and ( $name  -as [System.Type] ).IsEnum )
                                        {
                                            $output = [Enum]::GetValues($name) -like $_opt -replace '^(.*)$',($_base + '$1')
                                            $output | sort
                                        }
                                        elseif ( ( $name  -as [System.Type] ).IsEnum ) 
                                        {
                                            $global:_enum = $name
                                            $output = [Enum]::GetValues($name) -like $_opt -replace '^(.*)$','"$1"'
                                            $output | sort
                                        }
                                    }
                                }
                            }
                            if ( $output -ne $null )
                            {
                                break;
                            }
                        }


                        if ( $line[-1] -eq " " )
                        {
                            $_cmdlet = $line.TrimEnd(" ").Split(" |(;={")[-1]

                            # now get the info object for it...
                            $_cmdlet = @(Get-Command -type 'cmdlet,alias' $_cmdlet)[0]

                            # loop resolving aliases...
                            while ($_cmdlet.CommandType -eq 'alias')
                            {
                                $_cmdlet = @(Get-Command -type 'cmdlet,alias' $_cmdlet.Definition)[0]
                            }

                            if ( "Set-ExecutionPolicy" -eq $_cmdlet.Name )
                            {
                                "Unrestricted", "RemoteSigned", "AllSigned", "Restricted", "Default" | sort
                                break;
                            }

                            if ( "Trace-Command","Get-TraceSource","Set-TraceSource" -contains $_cmdlet.Name )
                            {
                               Get-TraceSource | % { $_.Name } | sort -Unique
                               break;
                            }

                            if ( "New-Object" -eq $_cmdlet.Name )
                            {
                                 $_TypeNames_System
                                 $_TypeNames
                                 break;
                            }

                            if ( $_cmdlet.Noun -like "*WMI*" )
                            {
                                $_WMIClasses
                                break;
                            }

                            if ( "Get-Process" -eq $_cmdlet.Name )
                            {
                                 Get-Process | % { $_.Name } | sort
                                 break;
                            }

                            if ( "Add-PSSnapin", "Get-PSSnapin", "Remove-PSSnapin" -contains $_cmdlet.Name )
                            {
                                if ( $global:_snapin -ne $null )
                                {
                                    $global:_snapin
                                    break;
                                }
                                else
                                {
                                    $global:_snapin = $(Get-PSSnapIn -Registered;Get-PSSnapIn)| sort Name -Unique;
                                    $global:_snapin
                                    break;
                                }
                            }

                            if ( "Get-PSDrive", "New-PSDrive", "Remove-PSDrive" `
                                 -contains $_cmdlet.Name -and "Name" )
                            {
                                Get-PSDrive | sort
                                break;
                            }

                            if ( "Get-Eventlog" -eq $_cmdlet.Name )
                            {
                                 Get-EventLog -List | % { $_base + ($_.Log -replace '\s','` ') }
                                 break;
                            }

                            if ( "Get-Help" -eq $_cmdlet.Name )
                            {
                                Get-Help -Category all | % { $_.Name } | sort -Unique
                                     break;
                            }

                            if ( "Get-Service", "Restart-Service", "Resume-Service",
                                 "Start-Service", "Stop-Service", "Suspend-Service" `
                                 -contains $_cmdlet.Name )
                            {
                                Get-Service | sort Name  | % { $_base + ($_.Name -replace '\s','` ') }
                                break;
                            }

                            if ( "Get-Command" -eq $_cmdlet.Name )
                            {
                                 Get-Command -CommandType All | % { $_base + ($_.Name -replace '\s','` ') }
                                 break;
                            }

                            if ( "Format-List", "Format-Custom", "Format-Table", "Format-Wide", "Compare-Object",
                                 "ConvertTo-Html", "Measure-Object", "Select-Object", "Group-Object", "Sort-Object" `
                                  -contains $_cmdlet.Name )
                            {
                                 Get-PipeLineObject
                                 $_dummy | Get-Member -MemberType Properties,ParameterizedProperty | sort membertype | % { $_base + ($_.Name -replace '\s','` ') }
                                 break;
                            }

                        }

                        if ( $line[-1] -eq " " )
                        {
                            # extract the command name from the string
                            # first split the string into statements and pipeline elements
                            # This doesn't handle strings however.
                            $_cmdlet = [regex]::Split($line, '[|;=]')[-1]

                            #  Extract the trailing unclosed block e.g. ls | foreach { cp
                            if ($_cmdlet -match '\{([^\{\}]*)$')
                            {
                                $_cmdlet = $matches[1]
                            }

                            # Extract the longest unclosed parenthetical expression...
                            if ($_cmdlet -match '\(([^()]*)$')
                            {
                                $_cmdlet = $matches[1]
                            }

                            # take the first space separated token of the remaining string
                            # as the command to look up. Trim any leading or trailing spaces
                            # so you don't get leading empty elements.
                            $_cmdlet = $_cmdlet.Trim().Split()[0]

                            # now get the info object for it...
                            $_cmdlet = @(Get-Command -type 'Application' $_cmdlet)[0]

                            if ( $_cmdlet.Name -eq "powershell.exe" )
                            {
                                "-PSConsoleFile", "-Version", "-NoLogo", "-NoExit", "-Sta", "-NoProfile", "-NonInteractive",
                                "-InputFormat", "-OutputFormat", "-EncodedCommand", "-File", "-Command" | sort
                                break;
                            }
                            if ( $_cmdlet.Name -eq "fsutil.exe" )
                            {
                                "behavior query", "behavior set", "dirty query", "dirty set", 
                                "file findbysid", "file queryallocranges", "file setshortname", "file setvaliddata", "file setzerodata", "file createnew", 
                                "fsinfo drives", "fsinfo drivetype", "fsinfo volumeinfo", "fsinfo ntfsinfo", "fsinfo statistics", 
                                "hardlink create", "objectid query", "objectid set", "objectid delete", "objectid create",
                                "quota disable", "quota track", "quota enforce", "quota violations", "quota modify", "quota query",
                                "reparsepoint query", "reparsepoint delete", "sparse setflag", "sparse queryflag", "sparse queryrange", "sparse setrange",
                                "usn createjournal", "usn deletejournal", "usn enumdata", "usn queryjournal", "usn readdata", "volume dismount", "volume diskfree" | sort
                                break;
                            }
                            if ( $_cmdlet.Name -eq "net.exe" )
                            {
                                "ACCOUNTS ", " COMPUTER ", " CONFIG ", " CONTINUE ", " FILE ", " GROUP ", " HELP ", 
                                "HELPMSG ", " LOCALGROUP ", " NAME ", " PAUSE ", " PRINT ", " SEND ", " SESSION ", 
                                "SHARE ", " START ", " STATISTICS ", " STOP ", " TIME ", " USE ", " USER ", " VIEW" | sort
                                break;
                            }
                            if ( $_cmdlet.Name -eq "ipconfig.exe" )
                            {
                                "/?", "/all", "/renew", "/release", "/flushdns", "/displaydns",
                                "/registerdns", "/showclassid", "/setclassid"
                                break;
                            }
                        }

                        if ( $line -match '\w+\s+(\w+(\.|[^\s\.])*)$' )
                        {
                            #$_opt = $Matches[1] + '*'
                            $_cmdlet = $line.TrimEnd(" ").Split(" |(;={")[-2]

                            $_opt = $Matches[1].Split(" ,")[-1] + '*'
                            $_base = $Matches[1].Substring(0,$Matches[1].Length-$Matches[1].Split(" ,")[-1].length)


                            # now get the info object for it...
                            $_cmdlet = @(Get-Command -type 'cmdlet,alias' $_cmdlet)[0]

                            # loop resolving aliases...
                            while ($_cmdlet.CommandType -eq 'alias')
                            {
                                $_cmdlet = @(Get-Command -type 'cmdlet,alias' $_cmdlet.Definition)[0]
                            }

                            if ( "Set-ExecutionPolicy" -eq $_cmdlet.Name )
                            {
                                "Unrestricted", "RemoteSigned", "AllSigned", "Restricted", "Default" -like $_opt | sort
                                break;
                            }

                            if ( "Trace-Command","Get-TraceSource","Set-TraceSource" -contains $_cmdlet.Name )
                            {
                               Get-TraceSource -Name $_opt | % { $_.Name } | sort -Unique | % { $_base + ($_ -replace '\s','` ') }
                               break;
                            }

                            if ( "New-Object" -eq $_cmdlet.Name )
                            {
                                 $_TypeNames_System -like $_opt
                                 $_TypeNames -like $_opt
                                 break;
                            }

                            if ( $_cmdlet.Name -like "*WMI*" )
                            {
                                $_WMIClasses -like $_opt
                                break;
                            }

                            if ( "Get-Process" -eq $_cmdlet.Name )
                            {
                                 Get-Process $_opt | % { $_.Name } | sort | % { $_base + ($_ -replace '\s','` ') }
                                 break;
                            }

                            if ( "Add-PSSnapin", "Get-PSSnapin", "Remove-PSSnapin" -contains $_cmdlet.Name )
                            {
                                if ( $global:_snapin -ne $null )
                                {
                                    $global:_snapin -like $_opt | % { $_base + ($_ -replace '\s','` ') }
                                    break;
                                }
                                else
                                {
                                    $global:_snapin = $(Get-PSSnapIn -Registered;Get-PSSnapIn)| sort Name -Unique;
                                    $global:_snapin -like $_opt | % { $_base + ($_ -replace '\s','` ') }
                                    break;
                                }
                            }

                            if ( "Get-PSDrive", "New-PSDrive", "Remove-PSDrive" `
                                 -contains $_cmdlet.Name -and "Name" )
                            {
                                Get-PSDrive -Name $_opt | sort | % { $_base + ($_ -replace '\s','` ') }
                                break;
                            }

                            if ( "Get-PSProvider" -eq $_cmdlet.Name )
                            {
                                Get-PSProvider -PSProvider $_opt | % { $_.Name } | sort | % { $_base + ($_ -replace '\s','` ') }
                                break;
                            }


                            if ( "Get-Eventlog" -eq $_cmdlet.Name )
                            {
                                 Get-EventLog -List | ? { $_.Log -like $_opt } | % { $_base + ($_.Log -replace '\s','` ') }
                                 break;
                            }

                            if ( "Get-Help" -eq $_cmdlet.Name )
                            {
                                Get-Help -Category all -Name $_opt | % { $_.Name } | sort -Unique
                                     break;
                            }

                            if ( "Get-Service", "Restart-Service", "Resume-Service",
                                 "Start-Service", "Stop-Service", "Suspend-Service" `
                                 -contains $_cmdlet.Name )
                            {
                                Get-Service -Name $_opt | sort Name  | % { $_base + ($_.Name -replace '\s','` ') }
                                break;
                            }

                            if ( "Get-Command" -eq $_cmdlet.Name )
                            {
                                 Get-Command -CommandType All -Name $_opt | % { $_base + ($_.Name -replace '\s','` ') }
                                 break;
                            }

                            if ( "Format-List", "Format-Custom", "Format-Table", "Format-Wide", "Compare-Object",
                                 "ConvertTo-Html", "Measure-Object", "Select-Object", "Group-Object", "Sort-Object" `
                                  -contains $_cmdlet.Name )
                            {
                                 Get-PipeLineObject
                                 $_dummy | Get-Member -Name $_opt -MemberType Properties,ParameterizedProperty | sort membertype | % { $_base + ($_.Name -replace '\s','` ') }
                                 break;
                            }
                        }

                        if ( $line -match '(-(\w+))\s+([^-]*$)' )
                        {

                            $_param = $matches[2] + '*'
                            $_opt = $Matches[3].Split(" ,")[-1] + '*'
                            $_base = $Matches[3].Substring(0,$Matches[3].Length-$Matches[3].Split(" ,")[-1].length)

                            # extract the command name from the string
                            # first split the string into statements and pipeline elements
                            # This doesn't handle strings however.
                            $_cmdlet = [regex]::Split($line, '[|;=]')[-1]

                            #  Extract the trailing unclosed block e.g. ls | foreach { cp
                            if ($_cmdlet -match '\{([^\{\}]*)$')
                            {
                                $_cmdlet = $matches[1]
                            }

                            # Extract the longest unclosed parenthetical expression...
                            if ($_cmdlet -match '\(([^()]*)$')
                            {
                                $_cmdlet = $matches[1]
                            }

                            # take the first space separated token of the remaining string
                            # as the command to look up. Trim any leading or trailing spaces
                            # so you don't get leading empty elements.
                            $_cmdlet = $_cmdlet.Trim().Split()[0]

                            # now get the info object for it...
                            $_cmdlet = @(Get-Command -type 'cmdlet,alias,ExternalScript,Filter,Function' $_cmdlet)[0]

                            # loop resolving aliases...
                            while ($_cmdlet.CommandType -eq 'alias')
                            {
                                $_cmdlet = @(Get-Command -type 'cmdlet,alias,ExternalScript,Filter,Function' $_cmdlet.Definition)[0]
                            }

                            if ( $_param.TrimEnd("*") -eq "ea" -or $_param.TrimEnd("*") -eq "wa" )
                            {
                               "SilentlyContinue", "Stop", "Continue", "Inquire" |
                               ? { $_ -like $_opt } | sort -Unique
                               break;
                            }

                            if ( "Out-File","Export-CSV","Select-String","Export-Clixml" -contains $_cmdlet.Name `
                                 -and "Encoding" -like $_param)
                            {
                                "Unicode",  "UTF7", "UTF8", "ASCII", "UTF32", "BigEndianUnicode", "Default", "OEM" |
                                ? { $_ -like $_opt } | sort -Unique
                                break;
                            }

                            if ( "Trace-Command","Get-TraceSource","Set-TraceSource" -contains $_cmdlet.Name `
                                -and "Name" -like $_param)
                            {
                               Get-TraceSource -Name $_opt | % { $_.Name } | sort -Unique | % { $_base + ($_ -replace '\s','` ') }
                               break;
                            }

                            if ( "New-Object" -like $_cmdlet.Name )
                            {
                                if ( "ComObject" -like $_param )
                                {
                                    $_ProgID -like $_opt  | % { $_ -replace '\s','` ' }
                                    break;
                                }

                                if ( "TypeName" -like $_param )
                                {
                                    $_TypeNames_System -like $_opt
                                    $_TypeNames -like $_opt
                                    break;
                                }
                            }

                            if ( "New-Item" -eq $_cmdlet.Name )
                            {
                                if ( "ItemType" -like $_param )
                                {
                                    "directory", "file" -like $_opt
                                    break;
                                }
                            }

                            if ( "Get-Location", "Get-PSDrive", "Get-PSProvider", "New-PSDrive", "Remove-PSDrive" `
                                 -contains $_cmdlet.Name `
                                 -and "PSProvider" -like $_param )
                            {
                                Get-PSProvider -PSProvider $_opt | % { $_.Name } | sort  | % { $_base + ($_ -replace '\s','` ') }
                                break;
                            }

                            if ( "Get-Location" -eq $_cmdlet.Name -and "PSDrive" -like $_param )
                            {
                                Get-PSDrive -Name $_opt | sort | % { $_base + ($_ -replace '\s','` ') }
                                break;
                            }

                            if ( "Get-PSDrive", "New-PSDrive", "Remove-PSDrive" `
                                 -contains $_cmdlet.Name -and "Name" -like $_param )
                            {
                                Get-PSDrive -Name $_opt | sort | % { $_base + ($_ -replace '\s','` ') }
                                break;
                            }

                            if ( "Get-Command" -eq $_cmdlet.Name -and  "PSSnapin" -like $_param)
                            {
                                if ( $global:_snapin -ne $null )
                                {
                                    $global:_snapin -like $_opt  | % { $_base + $_ }
                                    break;
                                }
                                else
                                {
                                    $global:_snapin = $(Get-PSSnapIn -Registered;Get-PSSnapIn)| sort Name -Unique;
                                    $global:_snapin -like $_opt  | % { $_base + ($_ -replace '\s','` ') }
                                    break;
                                }
                            }

                            if ( "Add-PSSnapin", "Get-PSSnapin", "Remove-PSSnapin" `
                                 -contains $_cmdlet.Name -and "Name" -like $_param )
                            {
                                if ( $global:_snapin -ne $null )
                                {
                                    $global:_snapin -like $_opt | % { $_base + ($_ -replace '\s','` ') }
                                    break;
                                }
                                else
                                {
                                    $global:_snapin = $(Get-PSSnapIn -Registered;Get-PSSnapIn)| sort Name -Unique;
                                    $global:_snapin -like $_opt | % { $_base + $_ }
                                    break;
                                }
                            }

                            if ( "Clear-Variable", "Export-Alias", "Get-Alias", "Get-PSDrive", "Get-Variable", "Import-Alias",
                                 " New-Alias", "New-PSDrive", "New-Variable", "Remove-Variable", "Set-Alias", "Set-Variable" `
                                 -contains $_cmdlet.Name -and "Scope" -like $_param )
                            {
                                "Global", "Local", "Script" -like $_opt
                                break;
                            }

                            if ( "Get-Process", "Stop-Process", "Wait-Process" -contains $_cmdlet.Name -and "Name" -like $_param )
                            {
                                 Get-Process $_opt | % { $_.Name } | sort | % { $_base + ($_ -replace '\s','` ') }
                                 break;
                            }

                            if ( "Get-Eventlog" -eq $_cmdlet.Name -and "LogName" -like $_param )
                            {
                                 Get-EventLog -List | ? { $_.Log -like $_opt } | % { $_base + ($_.Log -replace '\s','` ') }
                                 break;
                            }

                            if ( "Get-Help" -eq $_cmdlet.Name )
                            {
                                 if ( "Name" -like $_param )
                                 {
                                     Get-Help -Category all -Name $_opt | % { $_.Name } | sort -Unique
                                     break;
                                 }
                                 if ( "Category" -like $_param )
                                 {
                                     "Alias", "Cmdlet", "Provider", "General", "FAQ",
                                     "Glossary", "HelpFile", "All" -like $_opt | sort | % { $_base + $_ }
                                     break;
                                 }
                            }

                            if ( "Get-Service", "Restart-Service", "Resume-Service",
                                 "Start-Service", "Stop-Service", "Suspend-Service" `
                                 -contains $_cmdlet.Name )
                            {
                                 if ( "Name" -like $_param )
                                 {
                                     Get-Service -Name $_opt | sort Name  | % { $_base + ($_.Name -replace '\s','` ') }
                                     break;
                                 }
                                 if ( "DisplayName" -like $_param )
                                 {
                                     Get-Service -Name $_opt | sort DisplayName | % { $_base + ($_.DisplayName -replace '\s','` ') }
                                     break;
                                 }
                            }

                            if ( "New-Service" -eq $_cmdlet.Name -and "dependsOn" -like $_param )
                            {
                                 Get-Service -Name $_opt | sort Name | % { $_base + ($_.Name -replace '\s','` ') }
                                 break;
                            }

                            if ( "Get-EventLog" -eq $_cmdlet.Name -and "EntryType" -like $_param )
                            {
                                 "Error", "Information", "FailureAudit", "SuccessAudit", "Warning" -like $_opt | sort | % { $_base + $_ }
                                 break;
                            }

                            if ( "Get-Command" -eq $_cmdlet.Name -and "Name" -like $_param )
                            {
                                 Get-Command -CommandType All -Name $_opt | % { $_base + ($_.Name -replace '\s','` ') }
                                 break;
                            }

                            if ( $_cmdlet.Noun -like "*WMI*" )
                            {
                                if ( "Class" -like $_param )
                                {
                                    $_WMIClasses -like $_opt
                                    break;
                                }
                            }

                            if ( "Format-List", "Format-Custom", "Format-Table", "Format-Wide", "Compare-Object",
                                 "ConvertTo-Html", "Measure-Object", "Select-Object", "Group-Object", "Sort-Object" `
                                  -contains $_cmdlet.Name -and "Property" -like $_param )
                            {
                                 Get-PipeLineObject
                                 $_dummy | Get-Member -Name $_opt -MemberType Properties,ParameterizedProperty | sort membertype | % { $_base + ($_.Name -replace '\s','` ') }
                                 break;
                            }

                            if ( "Select-Object" -eq $_cmdlet.Name )
                            {
                                if ( "ExcludeProperty" -like $_param )
                                {
                                 Get-PipeLineObject
                                 $_dummy | Get-Member -Name $_opt -MemberType Properties,ParameterizedProperty | sort membertype | % { $_base + ($_.Name -replace '\s','` ') }
                                 break;
                                }

                                if ( "ExpandProperty" -like $_param )
                                {
                                 Get-PipeLineObject
                                 $_dummy | Get-Member -Name $_opt -MemberType Properties,ParameterizedProperty | sort membertype | % { $_.Name }
                                 break;
                                }
                            }

                        if ( "ExternalScript", "Function", "Filter" -contains $_cmdlet.CommandType )
                        {
                            if ( $_cmdlet.CommandType -eq "ExternalScript" )
                            {
                                $_fsr = New-Object IO.StreamReader $_cmdlet.Definition
                                $_def = "Function _Dummy { $($_fsr.ReadToEnd()) }"
                                $_fsr.Close()
                                iex $_def
                                $_cmdlet = "_Dummy"
                            }

                            if ( ((gi "Function:$_cmdlet").Definition -replace '\n').Split("{")[0] -match 'param\((.*\))\s*[;\.&a-zA-Z]*\s*$' )
                            {
                                $Matches[1].Split(',', "RemoveEmptyEntries" -as [System.StringSplitOptions]) -like "*$_param" |
                                % { $_.Split("$ )`r`n", "RemoveEmptyEntries" -as [System.StringSplitOptions])[0] -replace '^\[(.*)\]$','$1' -as "System.Type" } |
                                ? { $_.IsEnum } | % { [Enum]::GetNames($_) -like $_opt | sort } | % { $_base + $_ }
                            }
                            break;
                        }

                            select -InputObject $_cmdlet -ExpandProperty ParameterSets | select -ExpandProperty Parameters |
                            ? { $_.Name -like $_param } | ? { $_.ParameterType.IsEnum } |
                            % { [Enum]::GetNames($_.ParameterType) } | ? { $_ -like $_opt } | sort -Unique | % { $_base + $_ }

                        }


                               if ( $line[-1] -match "\s" ) { break; }
	
                               if ( $lastWord -ne $null -and $lastWord.IndexOfAny('/\') -eq -1 ) {
                                  $command = $lastWord.Substring( ($lastWord -replace '([^\|\(;={]*)$').Length )
                                  $_base = $lastWord.Substring( 0, ($lastWord -replace '([^\|\(;={]*)$').Length )
                                  $pattern = $command + "*"
                                  gcm -Name $pattern -CommandType All | % { $_base + $_.Name } | sort -Unique
                               }
                    }
                }
            }
        
}
