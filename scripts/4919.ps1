# Firefox_install_extensions.ps1
# Purpose: install Firefox extensions
# Details: This PowerShell script installs Firefox extensions into the main C:\Program Files (x86)\Mozilla Firefox\extensions folder
# so that they are available to all users. This has been tested for extensions (including dictionaries). It's not designed for plugins.
# Compatibility: Works on at least Firefox 21, 25. Tested on Win7x64.
#
# Prep work:
#   Open Firefox and install the extension(s) you want and close Firefox.
#   Find the installed extension(s): Look in %AppData%\Mozilla\Firefox\Profiles\9grbtiio.default\extensions or C:\Program Files (x86)\Mozilla Firefox\extensions
#   The extension might be a folder or XPI file named something recognizable like "de-DE@dictionaries.addons.mozilla.org" or it might be a GUID.
#   If it's an XPI file, you will need to extract its contents using any UNZIP tool and just name the folder the same as the XPI file.
#   Finally copy this extension folder to this script's folder.
#
# Note 1:
#   This script only copies the extension itself--it does not copy any extension settings. It's up to you to figure out how and where each
#   extension's settings are stored and be able to duplicate them to each user. See below for related info.
#
# Note 2:
#   By default Firefox will not automatically "enable" new extensions that it finds on it's next startup for a specific user. Users typically
#   have to acknowlege and approve its installation. To auto-approve new extensions that get copied to Firefox's own extension folder, you must ensure
#   that the setting "extensions.autoDisableScopes" (in about:config) does not include the bit-value for "all users of this computer". More details about this
#   setting can be found at:
#        https://developer.mozilla.org/en-US/docs/Installing_extensions#Disabling_install_locations
#   Look under the section "Preventing automatic install from specific locations". These "scopes" are defined in the previous section "Disabling install locations".
#   You need to ensure that the value of this setting is NEITHER 8 or 15. A setting of 0-7 will allow the newly-installed extension to run (be enabled)
#   without approval. FYI: By default Firefox ships with a setting of 15 which requires approval of all extensions no matter install location.
#   Finally if you want all users to have this setting, your default Windows profile must already include this setting in Firefox's profile -OR-
#   you can follow these instructions and have locked/shared settings for all users:
#        http://kb.mozillazine.org/Locking_preferences
#        http://mike.kaply.com/2012/03/16/customizing-firefox-autoconfig-files/
#
# 2013-11-05: Scott.Copus@wku.edu: script born
# 2013-11-13: Scott.Copus@wku.edu: fixed issue that would wipe out the existing "extensions" registry key & subvalues (PowerShell bug?)


# find Firefox install directory -- try 64-bit path first
$FFinstallDir = "${Env:ProgramFiles(x86)}\Mozilla Firefox"
$FFextensionsRegKey = "HKLM:\SOFTWARE\Wow6432Node\Mozilla\Firefox\Extensions"
if (!(Test-Path -Path $FFinstalldir)) {
	# if 64-bit path fails, fall back to 32-bit path
	$FFinstallDir    = "${Env:ProgramFiles}\Mozilla Firefox"
	$FFextensionsRegKey = "HKLM:\SOFTWARE\Mozilla\Firefox\Extensions"
}
if (!(Test-Path -Path $FFinstallDir)) {
	Write-Host "Problem: Could not find Firefox installation folder."
	Exit 16003  # 3 = "path not found"
}

# create extensions folder if necessary
$FFextensionsDir = "$FFinstallDir\extensions"
if (!(Test-Path -Path $FFextensionsDir)) {
    New-Item $FFextensionsDir -ItemType Directory -ErrorAction SilentlyContinue -Force | Out-Null
}
# create extensions registry key if necessary
if (!(Test-Path -Path $FFextensionsRegKey)) {
    New-Item $FFextensionsRegKey -ErrorAction SilentlyContinue -Force | Out-Null
}

# install extensions (asssumes extensions are all sub-folders in this script's path)
Get-ChildItem . -Directory | ForEach-Object {
	write-host Installing Firefox extension: $_.Name
	# copy each extension folder to the system
	Copy-Item $_.FullName $FFextensionsDir -Recurse -Force | Out-Null
	# create registry key for each extension
	New-ItemProperty -Path $FFextensionsRegKey -Name $_.Name -Value "$FFextensionsDir\$($_.Name)" -PropertyType String -Force | Out-Null
}

