#Requires -Version 2.0

<#
	Export-Html behaves exactly like native ConvertTo-HTML
	However it has one optional parameter -Path
	Which lets you specify the output file: e.g.
	Get-Process | Export-Html C:\temp\processes.html
	
	(c) Dmitry Sotnikov
	http://dmitrysotnikov.wordpress.com
	
	Proxy generated using PowerGUI Script Editor code snippets:
	http://poshoholic.com/2009/08/28/learn-powershell-v2-features-using-powershell-code-snippets/
	
	All changes to the proxy commented
	
	This sample from Kirk used for inspiration:
	http://poshoholic.com/2009/09/18/powershell-3-0-why-wait-importing-typed-objects-with-typed-properties-from-a-csv-file/
#>

function Export-Html {
[CmdletBinding(DefaultParameterSetName='Page')]
param(
    [Parameter(ValueFromPipeline=$true)]
    [System.Management.Automation.PSObject]
    ${InputObject},

# Adding Path parameter 
# (made it Position 0, and incremented Position for others)
    [Parameter(Position=0)]
    [Alias('PSPath', 'FilePath')]
    [ValidateNotNullOrEmpty()]
    [System.String]
    ${Path},

    [Parameter(Position=1)]
    [ValidateNotNullOrEmpty()]
    [System.Object[]]
    ${Property},

    [Parameter(ParameterSetName='Page', Position=4)]
    [ValidateNotNullOrEmpty()]
    [System.String[]]
    ${Body},

    [Parameter(ParameterSetName='Page', Position=2)]
    [ValidateNotNullOrEmpty()]
    [System.String[]]
    ${Head},

    [Parameter(ParameterSetName='Page', Position=3)]
    [ValidateNotNullOrEmpty()]
    [System.String]
    ${Title},

    [ValidateSet('Table','List')]
    [ValidateNotNullOrEmpty()]
    [System.String]
    ${As},

    [Parameter(ParameterSetName='Page')]
    [Alias('cu','uri')]
    [ValidateNotNullOrEmpty()]
    [System.Uri]
    ${CssUri},

    [Parameter(ParameterSetName='Fragment')]
    [ValidateNotNullOrEmpty()]
    [Switch]
    ${Fragment},

    [ValidateNotNullOrEmpty()]
    [System.String[]]
    ${PostContent},

    [ValidateNotNullOrEmpty()]
    [System.String[]]
    ${PreContent})

begin
{
    try {
        $outBuffer = $null
        if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer))
        {
            $PSBoundParameters['OutBuffer'] = 1
        }
        $wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('ConvertTo-Html', 
			[System.Management.Automation.CommandTypes]::Cmdlet)
		
		# define string variable to become the target command line
		#region Initialize helper variable to create command
		$scriptCmdPipeline = ''
		#endregion

		# add new parameter handling
		#region Process and remove the Path parameter if it is present
		if ($Path) {
			$PSBoundParameters.Remove('Path') | Out-Null
			$scriptCmdPipeline += " | Out-File -FilePath $Path"
		}
		#endregion
		
		$scriptCmd = {& $wrappedCmd @PSBoundParameters}
		
		# redefine command invocation
		#region Append our pipeline command to the end of the wrapped command script block.
		$scriptCmd = $ExecutionContext.InvokeCommand.NewScriptBlock(
				[string]$scriptCmd + $scriptCmdPipeline
			)
		#endregion
		
		
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

.ForwardHelpTargetName ConvertTo-Html
.ForwardHelpCategory Cmdlet

#>}
