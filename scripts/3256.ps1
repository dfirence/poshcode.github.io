# DefaultParameters Module
# 1.3 - fixed denable/disable, added get and remove, and improved import and set
# 1.2 - added help and commands to enable/disable the defaults
# 1.0 - initial release

function Export-DefaultParameter {
#.Synopsis
#  Exports the current default parameter values
[CmdletBinding()]
param(
   # The path to export default parameter values to (defaults to "DefaultParameterValues.clixml" in your profile directory)
   [String]$Path = $(Join-Path (Split-Path $Profile.CurrentUserAllHosts -Parent) DefaultParameterValues.clixml)
)
   Export-CliXml -InputObject $Global:PSDefaultParameterValues -Path $Path
}

function Import-DefaultParameter {
#.Synopsis
#  Imports new default parameter values
[CmdletBinding()]
param(
   # The path to import default parameter values from (defaults to "DefaultParameterValues.clixml" in your profile directory)
   [String]$Path = $(Join-Path (Split-Path $Profile.CurrentUserAllHosts -Parent) DefaultParameterValues.clixml),
   # If set, overwrite current values (otherwise, keep current values)
   [Switch]$Force
)
   $TempParameterValues = $Global:PSDefaultParameterValues
   if(Test-Path $Path) {
      [System.Management.Automation.DefaultParameterDictionary]$NewValues = 
            Import-CliXml  -Path ${ProfileDir}\DefaultParameterValues.clixml
      
      $repeats = @()
      foreach($key in $NewValues.Keys) {
         # don't import the disabled state, that's just silly
         if($key -eq "disabled") { continue }
         if($Global:PSDefaultParameterValues.ContainsKey($key)) {
            $command,$parameter = $key -split ":"
            if($Force) {
               $repeats += [PSCustomObject]@{Command=$Command;Parameter=$Parameter;NewDefault=$NewValues.$key;OldDefault=$Global:PSDefaultParameterValues.$Key}
               $Global:PSDefaultParameterValues.$Key = $NewValues.$key
            } else {
               $repeats += [PSCustomObject]@{Command=$Command;Parameter=$Parameter;CurrentDefault=$Global:PSDefaultParameterValues.$Key;SkippedValue=$NewValues.$key}
            }
         } else {
            $Global:PSDefaultParameterValues.$Key = $NewValues.$key
         }
      }
      if($repeats.Count) {
         $Width = &{
            $Local:ErrorActionPreference = "SilentlyContinue"
            $Width = $Host.UI.RawUI.BufferSize.Width - 2
            if($Width) { $Width } else { 80 }
         }
         if($Force) {
            Write-Warning ("Some defaults overwritten:`n{0}" -f ($repeats | Out-String -Width $Width))
         } else {
            Write-Warning ("Some defaults already defined, use -Force to overwrite:`n{0}" -f ($repeats | Out-String -Width $Width))
         }
      }
      # Make sure that everything is enabled
      $Global:PSDefaultParameterValues["Disabled"] = $false
   } else {
      Write-Warning "Default Parameter file not found: '$Path'"
   }
}

function Set-DefaultParameter {
#.Synopsis
#  Sets a default parameter value for a command
#.Description
#  Safely sets the default parameter value for a command, making sure that you've correctly typed the command and parameter combination
[CmdletBinding(DefaultParameterSetName="Colonated", SupportsShouldProcess=$true, ConfirmImpact="Low")]
param(
   # The command that you want to change the default value of a parameter for
   [parameter(Position=0,Mandatory=$true,ParameterSetName="Colonated")]
   [parameter(Position=0,Mandatory=$true,ParameterSetName="SeparateInputs")]
   $Command,
   # The name of the parameter that you want to change the default value for
   [parameter(Position=1,Mandatory=$true,ParameterSetName="SeparateInputs")]
   $Parameter,
   # The new default parameter value
   [parameter(Position=1,Mandatory=$true,ParameterSetName="Colonated")]
   [parameter(Position=2,Mandatory=$true,ParameterSetName="SeparateInputs")]
   $Value   
)

   if($PSCmdlet.ParameterSetName -eq "Colonated") {
      $command,$parameter = $command -split ":"
   }
   if($parameter.StartsWith("-")) {
      $parameter = $parameter.TrimStart("-")
   }
 
   ## Resolve the parameter to be sure
   $cmd = Get-Command $command | Select -First 1
   $parameters = $cmd.Parameters.Values
   $param = @($parameters | Where-Object { $_.Name -match $parameter -or $_.Aliases -match $parameter} | Select -Expand Name -Unique)
   if(!$param) {
      $param = @($parameters | Where-Object { $_.Name -match "${parameter}*"} | Select -First 1 -Expand Name)
      if(!$param) {
         $param = @($parameters | Where-Object { $_.Aliases -match "${parameter}*"} | Select -First 1 -Expand Name)
      }
   }
   if($param.Count -eq 1) {
      if($cmd.CommandType -eq "Alias") {
         $Command = $cmd.DisplayName
      } else {
         $Command = $cmd.Name
      }
      Write-Verbose "Setting Parameter $parameter on ${Command} to default: $($param[0])"
      
      $Key = "${Command}:$($param[0])"
      if( $Global:PSDefaultParameterValues.ContainsKey($Key) ) {
         $WI = "Overwrote the default parameter value for '$Key' with $Value"
         $CF = "Overwrite the existing default parameter value for '$Key'? ($($Global:PSDefaultParameterValues.$Key))"
      } else {
         $WI = "Added a default parameter value for '$Key' = $Value"
         $CF = "Add a default parameter value for '$Key'? ($($Global:PSDefaultParameterValues.$Key))"
      }
      if($PSCmdlet.ShouldProcess( $WI, $CI, "Setting Default Parameter Values" )) {
         $Global:PSDefaultParameterValues.$Key = $Value
      }
   } else {
      Write-Warning "Parameter $parameter not found on ${Command}"
   }
}

function Get-DefaultParameter {
#.Synopsis
#  Gets the default parameter value for a command, if it's been set
#.Description
#  Gets the default parameter value for a command from $PSDefaultParameterValues
[CmdletBinding(DefaultParameterSetName="Colonated")]
param(
   # The command that you want to change the default value of a parameter for (allows wildcards)
   [parameter(Position=0,Mandatory=$false)]
   [string]$Command = "*",
   # The name of the parameter that you want to change the default value for (allows wildcards)
   [parameter(Position=1,Mandatory=$true,ParameterSetName="SeparateInputs")]
   [string]$Parameter
)

   if($PSCmdlet.ParameterSetName -eq "Colonated") {
      $command,$parameter = $command -split ":"
   }
   if($parameter.StartsWith("-")) {
      $parameter = $parameter.TrimStart("-")
   }
 
   $repeats = @()
   foreach($key in $Global:PSDefaultParameterValues.Keys) {
      # Handle the disabled state:
      if($key -eq "disabled" -and $Global:PSDefaultParameterValues["Disabled"]) { 
         Write-Warning "Default Parameter Values are DISABLED and will not be used:"
         continue
      }
      if($key -like "${Command}:${Parameter}*") {
         $Cmd,$Param = $key -split ":"
         $repeats += [PSCustomObject]@{Command=$Cmd;Parameter=$Param;CurrentDefault=$Global:PSDefaultParameterValues.$Key}
      } else {
         Write-Verbose "'$key' is -not -like '${Command}:${Parameter}*'"
      }
   }
   $repeats
}


function Remove-DefaultParameter {
#.Synopsis
#  Removed the default parameter value for a command, if it's been set
#.Description
#  Removes the default parameter value for a command from $PSDefaultParameterValues
[CmdletBinding(DefaultParameterSetName="Colonated", SupportsShouldProcess=$true, ConfirmImpact="Low")]
param(
   # The command that you want to change the default value of a parameter for (allows wildcards)
   [parameter(Position=0,Mandatory=$false)]
   [string]$Command = "*",
   # The name of the parameter that you want to change the default value for (allows wildcards)
   [parameter(Position=1,Mandatory=$true,ParameterSetName="SeparateInputs")]
   [string]$Parameter
)

   if($PSCmdlet.ParameterSetName -eq "Colonated") {
      $command,$parameter = $command -split ":"
   }
   if($parameter.StartsWith("-")) {
      $parameter = $parameter.TrimStart("-")
   }
 
   $keys
   foreach($key in $Global:PSDefaultParameterValues.Keys | Where { $_ -like "${Command}:${Parameter}*" }) {
      # Handle the disabled state:
      if($key -ne "disabled") {
         if($PSCmdlet.ShouldProcess( "Removed the default parameter value for '$Key'",
                                     "Remove the default parameter value for '$Key'?",
                                     "Removing Default Parameter Values" )) {
            $Global:PSDefaultParameterValues.Remove($key)
         }
      }
   }
}

function Disable-DefaultParameter {
#.Synopsis
#  Turns OFF default parameters
#.Description
#  By setting $PSDefaultParameterValues["Disabled"] to $true, we make sure that NONE of our default parameter values will be used
[CmdletBinding()]
param()
   $Global:PSDefaultParameterValues["Disabled"]=$true
}

function Enable-DefaultParameter {
#.Synopsis
#  Turns ON default parameters
#.Description
#  By setting $PSDefaultParameterValues["Disabled"] to $false, we make sure that all of our default parameter values will be used
[CmdletBinding()]
param()
   $Global:PSDefaultParameterValues["Disabled"]=$false
}
Set-Alias Add-DefaultParameter Set-DefaultParameter -ErrorAction SilentlyContinue
Import-DefaultParameter
