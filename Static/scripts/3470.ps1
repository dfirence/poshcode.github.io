#function Get-Scope {
#.Synopsis 
#  Determine the scope of execution (are you in a module? how many scope layers deep are you?)
#.Parameter Invocation
#  In order to correctly determine the scope, this function requires that you pass in the $MyInvocation variable when you call it.
#.Parameter ToHost
#  If you just want to *see* the value in the console to debug something, you can pass this switch (and optionally, set the foreground/background colors)
#.Parameter Foreground
#  The Foreground color of host output
#.Parameter Background
#  The Background color of host output
#.Example
# $scope = Get-Scope $MyInvocation
#
# Description
# -----------
# Call Get-Scope and store the output so you can test if you're in module scope, etc.
#.Example
# Get-Scope $MyInvocation -ToHost Magenta DarkBlue
#
# Description
# -----------
# Call Get-Scope and write the output to host, specifying the foreground and background colors

[CmdletBinding()]
param(
   [Parameter(Position=0,Mandatory=$false)]
   [System.Management.Automation.InvocationInfo]$Invocation = $((Get-Variable -scope 1 'MyInvocation').Value)
,
   [Parameter(ParameterSetName="Debugging")]
   [Switch]$ToHost
,
   [Parameter(Position=1,ParameterSetName="Debugging")]
   [ConsoleColor]$Foreground = "Cyan"
,
   [Parameter(Position=2,ParameterSetName="Debugging")]
   [ConsoleColor]$Background = "Black"
)
end {
   function Get-ScopeDepth {
      trap { continue }
      $depth = 0
      do {
        Set-Variable scope_test -Value $depth -Scope ($depth++)
      } while($?)
      return $depth - 1
   }
   $depth = . Get-ScopeDepth
   $callstack = Get-PSCallStack
   
	$IsInteractive = $true
   foreach ($entry in $callStack[1..($callStack.Count - 1)]) {
      write-host $($entry | fl | out-string) -fore Cyan
      if((@('&','.','<ScriptBlock>') -contains $entry.Command)) { # @('&','.') -contains $entry.Position.Text[0]
         continue
      }
      if (($entry.Command -eq 'prompt') -or ($entry.Location -eq 'prompt')) {
         write-host "Found the prompt, we're done here"
         break
      }
      $IsInteractive = $false
      break
   }
   
   $IsGlobal = 0 -eq (Get-Variable scope_test -Scope global).Value

   Remove-Variable scope_test
   Remove-Variable scope_test -Scope global -EA 0

   $PSScope = New-Object PSObject -Property @{ 
      Module = $Invocation.MyCommand.Module
      IsModuleScope = [bool]$Invocation.MyCommand.Module
      IsGlobalScope = $IsGlobal
      IsInteractive = $IsInteractive
      ScopeDepth  = $depth
      PipelinePosition = $Invocation.PipelinePosition
      PipelineLength = $Invocation.PipelineLength
      StackDepth = $callstack.Count - 1
      Invocation = $Invocation
      CallStack = $callstack
   }
   
   if($ToHost) {
      &{
         $PSScope, $PSScope.Invocation | Out-String 
      } | Write-Host -Foreground $Foreground -Background $Background
   } else {
      $PSScope
   }
}
#}

