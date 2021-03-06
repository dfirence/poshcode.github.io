#Requires -version 2.0
##This is just script-file nesting stuff, so that you can call the SCRIPT, and after it defines the global function, it will call it.
param ( 
   [Parameter(Position=1,ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
   [string[]]$Name
,
   [Parameter(Position=2,ValueFromPipelineByPropertyName=$true,Mandatory=$false)]
   $ModuleName
,
   [switch]$ShowCommon
, 
   [switch]$Full
,
   [switch]$Passthru
)


function global:Get-Parameter {
#.Synopsis 
# Enumerates the parameters of one or more commands
#.Description
# Lists all the parameters of a command, by ParameterSet, including their aliases, type, etc.
#
# By default, formats the output to tables grouped by command and parameter set
#.Example
#  Get-Command Select-Xml | Get-Parameter
#.Example
#  Get-Parameter Select-Xml

param ( 
   [Parameter(Position=1,ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
   [string[]]$Name
,
   [Parameter(Position=2,ValueFromPipelineByPropertyName=$true,Mandatory=$false)]
   $ModuleName
,
   [switch]$ShowCommon
, 
   [switch]$Full
,
   [switch]$Passthru
)
   if($Passthru) {
      $PSBoundParameters.Remove("Passthru")
      Get-ParameterRaw @PSBoundParameters
   } elseif(!$Full) {
      $props = "Name", "Type", "ParameterSet", "Mandatory", "Provider"
      Get-ParameterRaw @PSBoundParameters | Format-Table $props -GroupBy @{n="Command";e={"{0}`n   Set:     {1}" -f $_.Command,$_.ParameterSet}}
   } else {
      $props = "Name", "Aliases", "Type", "ParameterSet", "Mandatory", "Provider", "Pipeline", "PipelineByName", "Position"

      Get-ParameterRaw @PSBoundParameters | Format-Table $props -GroupBy @{n="Command";e={"{0}`n   Set:     {1}" -f $_.Command,$_.ParameterSet}}
   }
}

## This is Hal's original script (modified a lot)
Function global:Get-ParameterRaw {
param ( 
   [Parameter(Position=1,ValueFromPipelineByPropertyName=$true,Mandatory=$true)]
   [string[]]$Name
,
   [Parameter(Position=2,ValueFromPipelineByPropertyName=$true,Mandatory=$false)]
   $ModuleName
,
   [switch]$ShowCommon
, 
   [switch]$Full
)
BEGIN {
   $PropertySet = @( "Name", 
                     "Aliases", 
                     @{n="Type";e={$_.ParameterType.Name}}, 
                     "ParameterSet",
                     @{n="Command";e={"{0}/{1}" -f $(if($command.ModuleName){$command.ModuleName}else{$Command.CommandType.ToString()+":"}),$command.Name}},
                     @{n="Mandatory";e={$_.IsMandatory}}, 
                     @{n="Provider";e={$_.DynamicProvider}},
                     @{n="Pipeline";e={$_.ValueFromPipeline}},                     
                     @{n="PipelineByName";e={$_.ValueFromPipelineByPropertyName}},
                     "Position"
                  )
   if(!$Full) {
      $PropertySet = $PropertySet[0,2,3,4,5,6]
   }
   function Join-Object {
   Param(
      [Parameter(Position=0)]
      $First
   ,
      [Parameter(ValueFromPipeline=$true,Position=1)]
      $Second
   )
      begin {
         [string[]] $p1 = $First | gm -type Properties | select -expand Name
      }
      process {
         $Output = $First | Select $p1
         foreach($p in $Second | gm -type Properties | Where { $p1 -notcontains $_.Name } | select -expand Name) {
            Add-Member -in $Output -type NoteProperty -name $p -value $Second."$p"
         }
         $Output
      }
   }
}
PROCESS{
   foreach($cmd in $Name) {
      if($ModuleName)   { $cmd = "$ModuleName\$cmd" }
      $commands = @(Get-Command $cmd)

      foreach($command in $commands) {
         # resolve aliases (an alias can point to another alias)
         while ($command.CommandType -eq "Alias") {
            $command = @(Get-Command ($command.definition))[0]
         }
         if (-not $command) { continue }

         $Parameters = @{}

         foreach($provider in Get-PSProvider) {
            $drive = "{0}\{1}::\" -f $provider.ModuleName, $provider.Name
            ## Write-Verbose ("Get-Command $command -Args $drive")
            
            $MoreParameters = Get-Command $command -Args $drive | Select -Expand Parameters
            $Dynamic = $MoreParameters | Select -Expand Values | Where { $_.IsDynamic }
            foreach($k in $Parameters.Keys){ $null = $MoreParameters.Remove($k) }
            $Parameters += $MoreParameters
            
            # Write-Verbose "Drive: $Drive | Parameters: $($Parameters.Count)"
            if($dynamic) {
               foreach($d in $dynamic) {
                  if(Get-Member -input $Parameters.($d.Name) -Name DynamicProvider) {
                     Write-Debug ("ADD:" + $d.Name + " " + $provider.Name)
                     $Parameters.($d.Name).DynamicProvider += $provider.Name
                  } else {
                     Write-Debug ("CREATE:" + $d.Name + " " + $provider.Name)
                     $Parameters.($d.Name) = $Parameters.($d.Name) | Add-Member NoteProperty DynamicProvider @($provider.Name) -Passthru
                  }
               }
            }
         }
         
         
         #Write-Output $Parameters
        
         foreach ($paramset in @($command.ParameterSets | Select -Expand "Name")){
            foreach($parameter in $Parameters.Keys) {
               if(!$ShowCommon -and ($Parameters.$Parameter.aliases -match "vb|db|ea|wa|ev|wv|ov|ob|wi|cf")) { continue }
               # Write-Verbose "Parameter: $Parameter"
               if($Parameters.$Parameter.ParameterSets.ContainsKey($paramset) -or $Parameters.$Parameter.ParameterSets.ContainsKey("__AllParameterSets")) {                  
                  if($Parameters.$Parameter.ParameterSets.ContainsKey($paramset)) { 
                     $output = Join-Object $Parameters.$Parameter $Parameters.$Parameter.ParameterSets.$paramSet 
                  } else {
                     $output = Join-Object $Parameters.$Parameter $Parameters.$Parameter.ParameterSets.__AllParameterSets
                  }
                  if($Full -and $output.Position -lt 0) {$output.Position = $null}
                  $setName = $(if($paramset -eq "__AllParameterSets") { "Default" } else { $paramset })
                  Write-Verbose "ParameterSet: $setName"
                  $output = $output | Add-Member NoteProperty ParameterSet -value "$setName" -Passthru
                  Write-Output $Output | Select-Object $PropertySet
               }
            }
         }
      }
   }
}
}

# This is nested stuff, so that you can call the SCRIPT, and after it defines the global function, we will call that.
Get-Parameter @PSBoundParameters

