## Format-Table with wrapping and string trimming.
function Format-TablePlus() {
[CmdletBinding()]
param(
   [Switch]
   ${AutoSize},

   [Switch]
   ${HideTableHeaders},

   [Switch]
   ${Wrap},

   [Parameter(Position=0)]
   [System.Object[]]
   ${Property},

   [System.Object]
   ${GroupBy},

   [System.String]
   ${View},

   [Switch]
   ${ShowError},

   [Switch]
   ${DisplayError},

   [Switch]
   ${Force},

   [ValidateSet('CoreOnly','EnumOnly','Both')]
   [System.String]
   ${Expand},

   [System.Int32]
   ${Width} = $Host.Ui.RawUI.BufferSize.Width,

   [Switch]
   ${PadEnd},

   [Parameter(ValueFromPipeline=$true)]
   [System.Management.Automation.PSObject]
   ${InputObject}
)

begin
{
   try {
      $outBuffer = $null
      if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
      {
         $PSBoundParameters['OutBuffer'] = 1
      }
      # need to get rid of these before we pass this to the Format-Table cmdlet
      $null = $PSBoundParameters.Remove("Width")
      $null = $PSBoundParameters.Remove("TrimEnd")
      
      $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Format-Table', [System.Management.Automation.CommandTypes]::Cmdlet)
      
      ## I made the trimming optional, but defaulted it to on ;)
      $scriptCmd = &{ 
         if($PadEnd) {
            {& $wrappedCmd @PSBoundParameters | Out-String -Stream -Width $Width }
         } else {
            {& $wrappedCmd @PSBoundParameters | Out-String -Stream -Width $Width | % { $_.TrimEnd() } }
         }
      }
      $steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
      $steppablePipeline.Begin($PSCmdlet) 
   } catch {
      throw
   }
}

process
{
   try {
      $steppablePipeline.Process($_)
   } catch {
      throw
   }
}

end
{
   try {
      $steppablePipeline.End()
   } catch {
      throw
   }
}
<#

.ForwardHelpTargetName Format-Table
.ForwardHelpCategory Cmdlet

#>
}
