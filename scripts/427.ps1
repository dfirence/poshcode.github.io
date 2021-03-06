## EnvStacks.psm1 module
## NOTE: If you "download" this, make sure it's a psm1 extension before you Add-Module
## NOTE: this will work as a regular v1.0 script if you dot-source it, but it *will* pollute your variable space a bit
##       you'll need to comment out the Export-ModuleMember line at the bottom ...
########################################################################################################################
## EnvStacks gives you the ability to set and change your environment variables in a stack-like way so you can easily
##   roll back to the previous value whenever you want -- particularly it includes a couple of very useful functions
##   for working with Path variables so that you can add or remove specific items easily.
##
## Push-EnvVariable    - set the value of an environment variable while stashing the current value in the stack
## Pop-EnvVariable     - recall the previous value of an environment variable from the stack
## Add-EnvPathItem     - Add an item to the front or end of a path variable (a semi-colon delimited string)
## Remove-EnvPathItem  - Remove items from path variables easily -- including by pattern matching or by index
##
## (c) Joel 'Jaykul' Bennett, 2008 -- Freely licensed under GPL/MPL/New BSD/MIT
########################################################################################################################
## Usage Example:
##
## [213]: add-module EnvStacks
@@## VERBOSE: Loading module from path 'Scripts:\Modules\EnvStacks\EnvStacks.psm1'.
@@## VERBOSE: Importing function 'Pop-EnvVariable'.
@@## VERBOSE: Importing function 'Add-EnvPathItem'.
@@## VERBOSE: Importing function 'Remove-EnvPathItem'.
@@## VERBOSE: Importing function 'Push-EnvVariable'.
## [214]: $Env:SessionName
## Console
## [215]: Push-EnvVariable SessionName Graphical
## [216]: $Env:SessionName
## Graphical
## [217]: Pop-EnvVariable SessionName
## [218]: $Env:SessionName
## Console
## [219]: $ENV:PSPACKAGEPATH
## Scripts:\Modules;C:\Users\JBennett\Documents\WindowsPowerShell\Packages
## [220]: Push-EnvVariable PSPackagePath C:\Users\JBennett\Documents\WindowsPowerShell\Packages
## [221]: $ENV:PSPACKAGEPATH
## C:\Users\JBennett\Documents\WindowsPowerShell\Packages
## [222]: Pop-EnvVariable PSPackagePath
## [223]: $ENV:PSPACKAGEPATH
## Scripts:\Modules;Scripts:\AutoModules;C:\Users\JBennett\Documents\WindowsPowerShell\Packages
## [224]: Add-EnvPathItem PSPackagePath "$($PSHOME)Packages"
## [225]: $ENV:PSPACKAGEPATH
## Scripts:\Modules;Scripts:\AutoModules;C:\Users\JBennett\Documents\WindowsPowerShell\Packages;C:\Windows\system32\WindowsPowerShell\v1.0\Packages
## [226]: Remove-EnvPathItem PSPackagePath -Pop
## [227]: $ENV:PSPACKAGEPATH
## Scripts:\Modules;Scripts:\AutoModules;C:\Users\JBennett\Documents\WindowsPowerShell\Packages
## [228]: Add-EnvPathItem PSPackagePath "$($PSHOME)Packages" -First
## [229]: Pop-EnvVariable PSPackagePath
## [230]: $ENV:PSPACKAGEPATH
## Scripts:\Modules;Scripts:\AutoModules;C:\Users\JBennett\Documents\WindowsPowerShell\Packages
## [231]: Add-EnvPathItem PSPackagePath "$($PSHOME)Packages" -First
## [232]: $ENV:PSPACKAGEPATH
## C:\Windows\system32\WindowsPowerShell\v1.0\Packages;Scripts:\Modules;Scripts:\AutoModules;C:\Users\JBennett\Documents\WindowsPowerShell\Packages
## [233]: Remove-EnvPathItem PSPackagePath -First
@@## VERBOSE: Removing First Item C:\Windows\system32\WindowsPowerShell\v1.0\Packages
## [234]: $ENV:PSPACKAGEPATH
## Scripts:\Modules;Scripts:\AutoModules;C:\Users\JBennett\Documents\WindowsPowerShell\Packages
## [235]: Pop-EnvVariable PSPackagePath
## [236]: $ENV:PSPACKAGEPATH
## C:\Windows\system32\WindowsPowerShell\v1.0\Packages;Scripts:\Modules;Scripts:\AutoModules;C:\Users\JBennett\Documents\WindowsPowerShell\Packages
## [237]: Pop-EnvVariable PSPackagePath
## [238]: $ENV:PSPACKAGEPATH
## Scripts:\Modules;Scripts:\AutoModules;C:\Users\JBennett\Documents\WindowsPowerShell\Packages
## [239]: Pop-EnvVariable PSPackagePath
@@##  Can't pop 'PSPackagePath', there's nothing in the stack
@@##  At Scripts:\AutoModules\EnvStacks\EnvStacks.psm1:28 char:12
## [240]: Remove-EnvPathItem Path *PowerShell* -Return
@@## VERBOSE: Removing Items like '*PowerShell*'...
## C:\Windows\system32\WindowsPowerShell\v1.0\
## C:\Program Files\PowerShell Community Extensions
## C:\Program Files\PowerShell Community Extensions\Scripts
## C:\Users\JBennett\Documents\WindowsPowerShell
## C:\Users\JBennett\Documents\WindowsPowerShell\Scripts
## C:\Users\JBennett\Documents\WindowsPowerShell\Scripts\Demo
########################################################################################################################



## This is slightly silly stuff, but we have to use the full name for the stack because it's in a different assembly
## PowerShell support for generics is *HORRIBLE*
$dictionaryType = [System.Collections.Generic.Dictionary``2].AssemblyQualifiedName
$stackType      = [System.Collections.Generic.Stack``1].AssemblyQualifiedName
$stringType     = [System.String].AssemblyQualifiedName

$stringStackType = "$stackType" -replace "``1", "``1[[$stringType]]"

# Note that this is a dictionary of string to stringstacktype ...
$stringStringStackDictionaryType = "$dictionaryType" -replace "``2", "``2[[$stringType],[$stringStackType]]"

$EnvStackStacks = new-object $stringStringStackDictionaryType

function Split-EnvPathVariable {
   PARAM([string]$Variable= $(Throw "Parameter '-Variable' (position 1) is required"), $char=";")
	$paths = @()
	if (test-path "Env:\$Variable") {
		$paths = (get-content "Env:\$Variable").Split($char) | Select -Unique
	}
   return $paths
}

function Pop-EnvVariable {
   PARAM([string]$Variable= $(Throw "Parameter '-Variable' (position 1) is required"))
   if($EnvStackStacks.ContainsKey($Variable.ToLower()) -and ($EnvStackStacks[$Variable.ToLower()].Count -gt 0)) {
      Set-Content "Env:\$Variable" $EnvStackStacks[$Variable.ToLower()].Pop()  
   } else {
      throw "Can't pop '$Variable', there's nothing in the stack"
   }
}

function Add-EnvPathItem {
	param([string]$Variable = $(throw "Parameter '-Variable' (position 1) is required"), 
	      $Value   = $(throw "Parameter '-Value' (position 2) is required"),
         [Switch]$First, [Switch]$NoStack, [Switch]$ReturnOld
        )
	
   if(!$NoStack) {
      if(!$EnvStackStacks.ContainsKey($Variable.ToLower())) {
         $EnvStackStacks.Add( $Variable.ToLower(), (new-object $stringStackType))
      }
      
      $EnvStackStacks[$Variable.ToLower()].Push( (get-content "Env:\$Variable") )
   }
   if($ReturnOld) {
      Get-Content "Env:\$Variable"
   }
	
   $paths = Split-EnvPathVariable $Variable

   if($First) {
      $newvar = @([string[]]$Value + $paths) | Select-Object -Unique | Where-Object {$_}
   } else {
      $newvar = @($paths + $Value) | Select-Object -Unique | Where-Object {$_}
   }
   
	$ofs = ';'
   Set-Content "Env:\$Variable" "$newvar"
}

function Remove-EnvPathItem {
	param([string]$Variable = $(throw "Parameter '-Variable' (position 1) is required"), 
         $Value, [int[]]$Index, [Switch]$First, [Switch]$Last, [Switch]$Pop, [Switch]$NoStack, [Switch]$ReturnRemoved
        )

   ## You need to pick just one of these, so if you passed two ...
   if( ($Value -and ($First -or $Last -or $Pop -or $Index)) -or 
                    ($First -and ($Last -or $Pop -or $Index)) -or 
                                 ($Last -and ($Pop -or $Index)) -or
                                             ($Pop -and $Index)) {
      throw "Can't resolve parameter set: you must specify only one of: -Value or -Index or -First or -Last or -Pop"
   }

   if($Pop) { 
      Pop-EnvVariable $Variable
   } elseif(!$NoStack) {
      if(!$EnvStackStacks.ContainsKey($Variable.ToLower())) {
         $EnvStackStacks.Add( $Variable.ToLower(), (new-object $stringStackType))
      }
      
      $EnvStackStacks[$Variable.ToLower()].Push( (get-content "Env:\$Variable") )
   }
   
   $paths = Split-EnvPathVariable $Variable

   if( $Value ) {
      $ofs = ';'
      if($ReturnRemoved) {
         write-verbose "Removing Items like '$Value'... "
         foreach($item in @($Value)) {
            write-output ($paths -like $item)
         }
      } else {
         write-verbose "Removing Items like '$Value'... "
         foreach($item in @($Value)) {
            write-verbose ("Removing {0}" -f ($paths -like $item))
         }
      }
      foreach($item in @($Value)) {
         $paths = $paths -notlike $item
      }
   } elseif($Index) {
      if($ReturnRemoved) {
         write-verbose "Removing Items by Index, $Index"
         write-output $paths[$Index]
      } else {
         write-verbose "Removing Items by Index, $Index: $($paths[$index])"
      }
      foreach($i in $index) { $paths[$i] = "" }
      $paths = $paths -ne ""
   } elseif($First) {
      if($ReturnRemoved) {
         write-verbose "Removing Last Item"
         write-output $paths[0]
      } else {
         write-verbose "Removing First Item $($paths[0])"
      }
      $paths = $paths[1..($paths.Length-1)]
   } elseif($Last) {
      if($ReturnRemoved) {
         write-verbose "Removing Last Item"
         write-output $paths[-1]
      } else {
         write-verbose "Removing Last Item $($paths[-1])"
      }
      $paths = $paths[0..($paths.Length-2)]
   }
   
	$ofs = ';'
	Set-Content "Env:\$Variable" "$paths"
}

function Push-EnvVariable {
	param([string]$Variable = $(throw "Parameter '-Variable' (position 1) is required"), 
	      $Value   = $(throw "Parameter '-Value' (position 2) is required"),
         [Switch]$ReturnOld
   )
	
   if(!$EnvStackStacks.ContainsKey($Variable.ToLower())) {
      $EnvStackStacks.Add( $Variable.ToLower(), (new-object $stringStackType))
   }
   
   $EnvStackStacks[$Variable.ToLower()].Push( (get-content "Env:\$Variable") )

   if($ReturnOld) {
      Get-Content "Env:\$Variable"
   }
   $ofs = ';'
   Set-Content "Env:\$Variable" "$Value"
}

function Clear-EnvStack {
   param([string]$Variable = $(throw "Parameter '-Variable' (position 1) is required"))
   if($EnvStackStacks.ContainsKey($Variable.ToLower())) {
      Write-Verbose ("{0} Items Removed" -f $EnvStackStacks[$Variable.ToLower()].Count)
      $EnvStackStacks[$Variable.ToLower()].Clear()
   }
}
 
Export-ModuleMember Push-EnvVariable, Pop-EnvVariable, Add-EnvPathItem, Remove-EnvPathItem

Set-Alias pushp Add-PathItem        -Option AllScope -scope Global -Description "Module Function alias from EnvStacks"
Set-Alias popp  Remove-PathItem     -Option AllScope -scope Global -Description "Module Function alias from EnvStacks"
Set-Alias pushe Push-EnvVariable    -Option AllScope -scope Global -Description "Module Function alias from EnvStacks"
Set-Alias pope  Pop-EnvVariable     -Option AllScope -scope Global -Description "Module Function alias from EnvStacks"

