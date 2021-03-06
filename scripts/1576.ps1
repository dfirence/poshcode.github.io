# ModuleWriteErrorUsageExample.psm1

# To use this you need to have the ModuleWriteError module loaded.
#Import-Module c:\scripts\ModuleWriteError

# Also:: Using $ErrorView = "CategoryView" is useful too.

function Get-Foo {
   	[CmdletBinding()]
	param(
		[string]$name,
		[switch]$interrupt
	)
	Process {
		# Just imagine you did some parsing of a file and the foo object wasn't found.
		$MyErrorRecord = (
			New-ModuleError -ErrorCategory ObjectNotFound `
			-message "Cannot get `'$Name`' because it does not exist." `
			-identifierText FooObjectNotFound -targetObject $($Name)
		)
		$PSCmdlet.WriteError( $MyErrorRecord )
	}
}

function Set-Foo {
   	[CmdletBinding()]
	param(
		[string]$name,
		[switch]$interrupt
	)
	Process {
		# we need to get Foo to make sure we can set it.
                # Play with the -ea value to see how that changes the ev_errors values.
		get-foo $Name -ev ev_errors	-ea "SilentlyContinue"

		## Trap this module's non-terminating written errors, similar to a catch.
		$ev_errors | sort -Unique |  foreach { $_ |
			where { ($_.exception.getType().Name -eq `
				"$($MyInvocation.MyCommand.ModuleName)ModuleException") -and
				($_.CategoryInfo.Category.ToString() -eq "ObjectNotFound") } |
			%{
				# Do whatever processing would be done to handle the error, or
				# alter the record and rethrow from this function to present the
				# user with an error that matches the function they called.
				
				# Keep the first part of the FQEid since WriteError will append
				# the current command name.
				$new_FQI = $([regex]::match($_.FullyQualifiedErrorId,
					"(.*?,){2}").Groups[0].value).ToString().TrimEnd(",")
		
				# This allows WriteError to correctly apply function naming.
				$MyErrorRecord = (
					new-object System.Management.Automation.ErrorRecord $_.Exception,
					"$($new_FQI)",
					$_.CategoryInfo.Category,
					$_.CategoryInfo.TargetName)
				
				# Modify the message presented to the user so that instead of
				# reporting that we can not 'get' the object when the user called 'set' 
				$MyErrorRecord.ErrorDetails = (
					New-Object System.Management.Automation.ErrorDetails `
					"Cannot set `'$Name`' because it was not found." )
					
				# Not sure which is better here...  The activity should present
				# what action caused the error, but should it be the action of
				# this command, or the action of what this command was doing.
				# Neither of these are _really_ needed.
				#$MyErrorRecord.CategoryInfo.Activity = "$($MyPrefixedCommandName)"
				#$MyErrorRecord.CategoryInfo.Activity = $curr_error.CategoryInfo.Activity

				# Finally re-write it from here.
				$PSCmdlet.WriteError( $MyErrorRecord )
			}
		}
	}
}

function Test-foo {
   	[CmdletBinding()]
	param()

	Write-Host "`n********************************************************************************" -ForegroundColor Cyan
	$Error.Clear()
	Write-Host "Sample output from Get-Foo call:" -ForegroundColor Gray
	Get-Foo bar -ev ev_errors
	Write-Host "`nDump of what is in `$ev_errors after calling Get-Foo:" -ForegroundColor Gray
	foreach ($err in $ev_errors) {Write-Warning ($err|Out-String)}
	#Write-Host "`nDump of what is in `$Local:Error after calling Get-Foo:" -ForegroundColor Gray
	#Write-Output -InputObject $Local:Error
	Write-Host "`nDump of what is in `$Global:Error after calling Get-Foo:" -ForegroundColor Gray
	Write-Output -InputObject $Global:Error

	Write-Host "`nPlease enter the following command: `'`$Global:Error.clear(); exit`'" -ForegroundColor Blue
	$Host.EnterNestedPrompt()

	Write-Host "`n`n********************************************************************************" -ForegroundColor Cyan
	Write-Host "`nSample output from Set-Foo call:" -ForegroundColor Gray
	Set-Foo bar -ev ev_errors
	Write-Host "`nDump of what is in `$ev_errors after calling Set-Foo:" -ForegroundColor Gray
	foreach ($err in $ev_errors) {Write-Warning ($err|Out-String)}
	#Write-Host "`nDump of what is in `$Local:Error after calling Set-Foo:" -ForegroundColor Gray
	#Write-Output -InputObject $Local:Error
	Write-Host "`nDump of what is in `$Global:Error after calling Set-Foo:" -ForegroundColor Gray
	Write-Output -InputObject $Global:Error
}

