function Get-FormatData {
	[CmdletBinding(HelpUri='http://go.microsoft.com/fwlink/?LinkID=144303', DefaultParameterSetName='S')]
	param(
		[Parameter(Position=0, ParameterSetName='S')]
		[ValidateNotNullOrEmpty()]
		[string[]]$TypeName = '*'
,
		[Parameter(ValueFromPipeline, ParameterSetName='I')]
		$InputObject
	)
	begin {
		if ($PSCmdlet.ParameterSetName -ceq 'I') {
			$seen = @{}
		} else {
			try {
				$outBuffer = $null
				if ($PSBoundParameters.TryGetValue('OutBuffer', [ref]$outBuffer)) {
					$PSBoundParameters['OutBuffer'] = 1
				}
				$wrappedCmd = $ExecutionContext.InvokeCommand.GetCommand('Microsoft.PowerShell.Utility\Get-FormatData', [System.Management.Automation.CommandTypes]::Cmdlet)
				$scriptCmd = {& $wrappedCmd @PSBoundParameters}
				$steppablePipeline = $scriptCmd.GetSteppablePipeline($myInvocation.CommandOrigin)
				$steppablePipeline.Begin($PSCmdlet)
			} catch {
				throw
			}
		}
	}
	process {
		if ($PSCmdlet.ParameterSetName -ceq 'I') {
			if ($null -cne $InputObject) {
				$names = [System.Collections.Generic.List[string]]@()
				if ($InputObject -is [type]) {
					$t = $InputObject
					do {
						if (-not $seen.ContainsKey($t.FullName)) {
							$seen[$t.FullName] = 0
							$null = $names.Add([System.Management.Automation.WildcardPattern]::Escape($t.FullName))
						} 
						$t = $t.BaseType
					} while ($null -cne $t)
				} else {
					foreach ($n in $InputObject.pstypenames) {
						if (-not $seen.ContainsKey($n)) {
							$seen[$n] = 0
							$null = $names.Add([System.Management.Automation.WildcardPattern]::Escape($n))
						}
					}
				}
				if (0 -lt $names.Count) {
					Microsoft.PowerShell.Utility\Get-FormatData -TypeName $names.ToArray()
				}
			}
		} else {
			try {
				$steppablePipeline.Process($_)
			} catch {
				throw
			}
		}
	}
	end {
		if ($PSCmdlet.ParameterSetName -ceq 'S') {
			try {
				$steppablePipeline.End()
			} catch {
				throw
			}
		}
	}
}
<#
.ForwardHelpTargetName Get-FormatData
.ForwardHelpCategory Cmdlet
#>
