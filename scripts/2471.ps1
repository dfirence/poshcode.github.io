function Edit-Variable {
    #.Parameter name
    #    The name (or path) to the variable to edit.
    #.Parameter Environment
    #    Optional switch to force evaluating the name as an environment variable. You don't need this if you specify the path as env:Path instead of just "Path"
    #.Example
    #     Edit-Variable -env path
    #.Example
    #     Edit-Variable profile
    #.Example
    #     Edit-Variable env:\path
    #.Example
    #     Edit-Variable variable:profile

    param(
        [Parameter(Position=0,ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [string]$name
    ,
        [switch]$Environment
    )
    process {
        $path = Resolve-Path $name -ErrorAction SilentlyContinue
        if($Environment) {
            ## Force Env: if they said -Env
            if(!$path -or $Path.Provider.Name -ne "Environment") {
                $path = Resolve-Path "Env:$name"
            }
        } else {
            if($Path -and $Path.Provider.Name -eq "Environment") {
                $Environment = $true
            } elseif(!$path -or $Path.Provider.Name -ne "Variable") {
                $path = Resolve-Path "Variable:$name" -ErrorAction SilentlyContinue
            }
        }
        
        $temp = [IO.Path]::GetTempFileName()
        if($path) {
            if(!$Environment) {
                $value = (Get-Variable $path.ProviderPath).Value
                $string = $value -is [String]
                if(!$string) {
                    Write-Warning "Variable $name is not a string variable, editing as CliXml"
                    Export-Clixml $temp -InputObject $Value 
                } else {
                    Set-Content $temp $Value
                }
            } else {
                Get-Content $path | Set-Content $temp
            }
        } else {
            $Environment = $false
            New-Variable $Name
            $path = Resolve-Path Variable:$name -ErrorAction SilentlyContinue
        }
        if(!$path) {
            Write-Error "Cannot find variable '$name' because it does not exist."
        } else {
            # Let the user edit it in notepad, and see if they save it
            $pre = Get-ChildItem $temp
            (Start-Process notepad $temp -passthru).WaitForExit()
            $post = Get-ChildItem $temp
            if($post.LastWriteTime -gt $pre.LastWriteTime) {
                if(!$Environment) {
                    if(!$string) {
                        Import-CliXml $temp | Set-Variable $path.ProviderPath
                    } else {
                        Get-Content $temp | Set-Variable $path.ProviderPath
                    }
                } else {
                    Get-Content $temp | Set-Content $path
                }
            }
        }
        Remove-Item $temp -ErrorAction SilentlyContinue
    }
}

Set-Alias vared Edit-Variable
