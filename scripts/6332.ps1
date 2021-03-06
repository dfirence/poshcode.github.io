###################################################################
##  Description:  Generic script for publishing and launching App-V
##  packages in Citrix published app is calls the script and passes
##  it the name of the package and the name of the EXE to launch.  
##  App-V packages should be saved in a DFS structure that uses the
##  name of the app as the folder.
##
##  This script is provided as is and may be freely used and 
##  distributed so long as proper credit is maintained.
##
##  Written by: thegeek@thecuriousgeek.org
##  Website:  http://thecuriousgeek.org
##  Date Modified:  05-01-2016
###################################################################


param(
	[string]$appName,
	[string]$exeName
)

# Window message to the user so they don't think nothing is happening
Write-Host "`n`n                        Your application is loading..."

Import-Module AppvClient
# Try and get package to see if it's loaded
$package = Get-AppVClientPackage -Name $appName

# If the package isn't already loaded, load it
If ( !$package ) {
	Try {
		# Add and publish package.  Make sure to update with your own path
		$package = Add-AppVClientPackage \\PathToApp-VPackageStorage\$appName\$appName.appv
		Publish-AppVClientPackage $appName -Global | Out-Null
		$didComplete = $true
	} Catch {
		# If it didn't complete, popup an error message to the user with details
		$errorMessage = "Error Item: $_.Exception.ItemName `n`nError Message: $_.Exception.Message"
		$didComplete = $false
		$wshell = New-Object -ComObject Wscript.Shell
		$wshell.Popup($errorMessage,0,"Error loading application",0x0)
	}
} else {
	# Package is already loaded
	$didComplete = $true
}

# In order to know when the app has launched, we'll check the number of window titles
# This is the count before we try to start the app
$windowTitleCount = (get-process | where {$_.MainWindowTitle}).Count

If ($didComplete) { 
	# Get the local package directory as set in App-V Config, used for building path to EXE
	# Powershell can't expand regular environment variables so have to use CMD to echo it back
	$cmdExpand = "cmd /c echo $( (Get-AppVClientConfiguration | where {$_.Name -eq 'PackageInstallationRoot'}).Value )"
	$packageRoot = Invoke-Expression $cmdExpand
	$packagePath = "$packageRoot\$($package.PackageId)\$($package.VersionId)\Root\VFS"
	# Pull in deployment config because it contains the path to all executables.  Make sure to update with your own path
	[XML]$packageConfig = Get-Content "PathToApp-VPackageStorage\$appName\$($appName)_DeploymentConfig.xml"
	$packageApps = $packageConfig.DeploymentConfiguration.UserConfiguration.Applications.Application.Id
	# Loop through each app/exe listed in the config and find the one that contains the $appExe passed to the script
	ForEach ($app in $packageApps) {
		If ($app -match $exeName) {
			$appPath = $app
			break
		}
	}
	# Get rid of the special characters App-V uses to reference variables in it's application path so we can create the real path
	$appPath = $appPath -replace "(\[|\{|\}|\])",""  #previous regex  [^0-9a-zA-Z\\\s\.]
	$fullPath = "$packagePath\$appPath"
	Start $fullPath
	
	# Check number of window titles again and keep looping until the count is greater than the starting one we took earlier
	$currentTitleCount = (get-process | where {$_.MainWindowTitle}).Count
	While ($windowTitleCount -ge $currentTitleCount) {
		$currentTitleCount = (get-process | where {$_.MainWindowTitle}).Count
	}
}
