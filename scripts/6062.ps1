trap { Write-Warning ($_.ScriptStackTrace | Out-String) }

# This timer is used by Trace-Message, I want to start it immediately
$Script:TraceVerboseTimer = New-Object System.Diagnostics.Stopwatch
$Script:TraceVerboseTimer.Start()

# PS5 introduced PSReadLine, which chokes in non-console shells, so I snuff it.
try { $NOCONSOLE = $FALSE; [System.Console]::Clear() } catch { $NOCONSOLE = $TRUE }

# If your PC doesn't have this set already, someone could tamper with this script...
# but at least now, they can't tamper with any of the modules/scripts that I auto-load!
Set-ExecutionPolicy AllSigned Process

# Ok, now import environment so we have PSProcessElevated and Trace-Message
# The others will get loaded automatically, but it's faster to load them explicitly
Import-Module $PSScriptRoot\Modules\Environment, Microsoft.PowerShell.Management, Microsoft.PowerShell.Security, Microsoft.PowerShell.Utility

# Check SHIFT state ASAP at startup so I can use that to control verbosity :)
Add-Type -Assembly PresentationCore, WindowsBase
try {
    $global:SHIFTED = [System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::LeftShift) -OR
                  [System.Windows.Input.Keyboard]::IsKeyDown([System.Windows.Input.Key]::RightShift)
} catch {
    $global:SHIFTED = $false
}
# If SHIFT is pressed, use verbose output from here on
if($SHIFTED) { $VerbosePreference = "Continue" }

##  Fix colors before anything gets output.
if($Host.Name -eq "ConsoleHost") {
    $Host.PrivateData.ErrorForegroundColor    = "DarkRed"
    $Host.PrivateData.WarningForegroundColor  = "DarkYellow"
    $Host.PrivateData.DebugForegroundColor    = "Green"
    $Host.PrivateData.VerboseForegroundColor  = "Cyan"
    $Host.PrivateData.ProgressForegroundColor = "Yellow"
    $Host.PrivateData.ProgressBackgroundColor = "DarkMagenta"
    if($PSProcessElevated) {
        $Host.UI.RawUI.BackgroundColor = "DarkGray"
        Clear-Host # To get rid of the weird trim
    }
} elseif($Host.Name -eq "Windows PowerShell ISE Host") {
    $Host.PrivateData.ErrorForegroundColor    = "DarkRed"
    $Host.PrivateData.WarningForegroundColor  = "Gold"
    $Host.PrivateData.DebugForegroundColor    = "Green"
    $Host.PrivateData.VerboseForegroundColor  = "Cyan"
    if($PSProcessElevated) {
        $Host.UI.RawUI.BackgroundColor = "DarkGray"
        Clear-Host # To get rid of the weird trim
    }
}

# First call to Trace-Message, pass in our TraceTimer that I created at the top to make sure we time EVERYTHING.
Trace-Message "Microsoft.PowerShell.* Modules Imported" -Stopwatch $TraceVerboseTimer

## Set the profile directory first, so we can refer to it from now on.
Set-Variable ProfileDir (Split-Path $MyInvocation.MyCommand.Path -Parent) -Scope Global -Option AllScope, Constant -ErrorAction SilentlyContinue
Set-Variable LiveID (
        [System.Security.Principal.WindowsIdentity]::GetCurrent().Groups |
        Where-Object { $_.Value -match "^S-1-11-96" }
    ).Translate([System.Security.Principal.NTAccount]).Value  -Scope Global -Option AllScope, Constant -ErrorAction SilentlyContinue
Set-Variable ReReverse @('(?sx) . (?<=(?:.(?=.*$(?<=((.) \1?))))*)', '$2') -Scope Global -Option AllScope, Constant -ErrorAction SilentlyContinue

###################################################################################################
## I add my "Scripts" directory and all of its direct subfolders to my PATH
[string[]]$folders = Get-ChildItem $ProfileDir\Tool[s], $ProfileDir\Utilitie[s], $ProfileDir\Scripts\*,$ProfileDir\Script[s] -ad | % FullName

## Developer tools stuff ...
## I need InstallUtil, MSBuild, and TF (TFS) and they're all in the .Net RuntimeDirectory OR Visual Studio*\Common7\IDE
$folders += [System.Runtime.InteropServices.RuntimeEnvironment]::GetRuntimeDirectory()
## MSBuild is now in 'C:\Program Files (x86)\MSBuild\{version}'
$folders += Set-AliasToFirst -Alias "msbuild" -Path 'C:\Program Files (x86)\MSBuild\*\Bin\MsBuild.exe' -Description "Visual Studio's MsBuild" -Force -Passthru
$folders += Set-AliasToFirst -Alias "merge" -Path "C:\Program*Files*\Perforce\p4merge.exe","C:\Program*Files*\DevTools\Perforce\p4merge.exe" -Description "Perforce" -Force -Passthru
$folders += Set-AliasToFirst -Alias "tf" -Path "C:\Program*Files*\*Visual?Studio*\Common7\IDE\TF.exe", "C:\Program*Files*\DevTools\*Visual?Studio*\Common7\IDE\TF.exe" -Description "Visual Studio" -Force -Passthru
$folders += Set-AliasToFirst -Alias "Python","Python2","py2" -Path "C:\Python2*\python.exe", "D:\Python2*\python.exe" -Description "Python 2.x" -Force -Passthru
$folders += Set-AliasToFirst -Alias "Python3","py3" -Path "C:\Python3*\python.exe", "D:\Python3*\python.exe" -Description "Python 3.x" -Force -Passthru
Set-AliasToFirst -Alias "iis","iisexpress" -Path 'C:\Progra*\IIS*\IISExpress.exe' -Description "Personal Profile Alias"

Trace-Message "Development aliases set"

## I really need to make a "Editor" module for this stuff, maybe make this part of the ModuleBuilder suite?
if(!(Test-Path Env:Editor)) {
   if($Editor = Get-Item 'C:\Progra*\Sublime*\sublime_text.exe','C:\Progra*\*\Sublime*\sublime_text.exe' | Sort VersionInfo.ProductVersion -Desc | Select-Object -First 1) {
      $folders += Split-Path $Editor

      function edit { start $Editor @( $Args + @("-n","-w")) }
      [Environment]::SetEnvironmentVariable("Editor", "'${Env:Editor}' -n -w", "User")
      Trace-Message "Env:Editor set: ${Env:Editor} "
   } else {
      Trace-Message -AsWarning "Sublime Text (edit command) is not available"
   }
}

$ENV:PATH = Select-UniquePath $folders ${Env:Path}
Trace-Message "PATH Updated"

## Make sure we have my Projects folder in the module path
$Env:PSModulePath = Select-UniquePath "$ProfileDir\Modules",(Get-SpecialFolder *Modules -Value),${Env:PSModulePath},"${Home}\Projects\Modules"
Trace-Message "PSModulePath Updated "

## I have a few additional custom type and format data items which take prescedence over anyone else's
Update-TypeData   -PrependPath "$ProfileDir\Formats\Types.ps1xml"
Trace-Message "Type Data Updated"

Update-FormatData -PrependPath "$ProfileDir\Formats\Formats.ps1xml"
Trace-Message "Format Data Updated"

## And a couple of functions that can't be saved as script files, and aren't worth modularizing
function Reset-Module ($ModuleName) { rmo $ModuleName; ipmo $ModuleName -force -pass | ft Name, Version, Path -Auto }

## The qq shortcut for quick quotes
function qq {param([Parameter(ValueFromRemainingArguments=$true)][string[]]$q)$q}

## Custom aliases I can't live without
Set-Alias   say          Speech\Out-Speech         -Option Constant, ReadOnly, AllScope -Description "Personal Profile Alias"
Set-Alias   gph          Get-PerformanceHistory    -Option Constant, ReadOnly, AllScope -Description "Personal Profile Alias"

# I really prefer that all of my sessions start in my profile directory
if($ProfileDir -ne (Get-Location)) {
   Push-Location $ProfileDir
}

# And I'm learning to use PSDrives
New-PSDrive Documents FileSystem (Get-SpecialFolder MyDocuments -Value)

# I no longer worry about OneDrive, because I mapped my Documents into it, so there's only OneDrive
if( ($OneDrive = (Get-ItemProperty HKCU:\Software\Microsoft\OneDrive UserFolder -EA 0).UserFolder) -OR
    ($OneDrive = (Get-ItemProperty HKCU:\Software\Microsoft\SkyDrive UserFolder -EA 0).UserFolder) -OR
    ($OneDrive = (Get-ItemProperty HKCU:\Software\Microsoft\Windows\CurrentVersion\SkyDrive UserFolder -EA 0).UserFolder)
  ) {
    New-PSDrive OneDrive FileSystem $OneDrive
    Trace-Message "OneDrive:\ mapped to $OneDrive"
}
if(Test-Path $Home\Projects) {
    New-PSDrive Projects FileSystem $Home\Projects
    New-PSDrive Modules FileSystem $Home\Projects\Modules
}


## My prompt function is in it's own script, and executing it imports previous history
if($Host.Name -ne "Package Manager Host") {
  . Set-Prompt -Clean
  Trace-Message "Prompt fixed"
}

if($Host.Name -eq "ConsoleHost" -and !$NOCONSOLE) {

    if(-not (Get-Module PSReadLine)) { Import-Module PSReadLine }

    ## If you have history to reload, you must do that BEFORE you import PSReadLine
    ## That way, the "up arrow" navigation works on the previous session's commands
    function Set-PSReadLineMyWay {
        param(
            $BackgroundColor = $(if($PSProcessElevated) { "DarkGray" } else { "Black" } )
        )
        $Host.UI.RawUI.BackgroundColor = $BackgroundColor
        $Host.UI.RawUI.ForegroundColor = "Gray"

        Set-PSReadlineOption -TokenKind Keyword -ForegroundColor Yellow -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind String -ForegroundColor Green -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Operator -ForegroundColor DarkGreen -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Variable -ForegroundColor DarkMagenta -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Command -ForegroundColor DarkYellow -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Parameter -ForegroundColor DarkCyan -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Type -ForegroundColor Blue -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Number -ForegroundColor Red -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Member -ForegroundColor DarkRed -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind None -ForegroundColor White -BackgroundColor $BackgroundColor
        Set-PSReadlineOption -TokenKind Comment -ForegroundColor Black -BackgroundColor DarkGray

        Set-PSReadlineOption -EmphasisForegroundColor White -EmphasisBackgroundColor $BackgroundColor `
                             -ContinuationPromptForegroundColor DarkBlue -ContinuationPromptBackgroundColor $BackgroundColor `
                             -ContinuationPrompt (([char]183) + "  ")
    }

    Set-PSReadLineMyWay
    Set-PSReadlineKeyHandler -Key "Ctrl+Shift+R" -Functio ForwardSearchHistory
    Set-PSReadlineKeyHandler -Key "Ctrl+R" -Functio ReverseSearchHistory

    Set-PSReadlineKeyHandler Ctrl+M SetMark
    Set-PSReadlineKeyHandler Ctrl+Shift+M ExchangePointAndMark

    Set-PSReadlineKeyHandler Ctrl+K KillLine
    Set-PSReadlineKeyHandler Ctrl+I Yank
    Trace-Message "PSReadLine fixed"
} else {
    Remove-Module PSReadLine -ErrorAction SilentlyContinue
    Trace-Message "PSReadLine skipped!"
}

###################################################################################################
## I love my random quotes ...
$Script:QuoteDir = Join-Path (Split-Path $ProfileDir -parent) "@stuff\Quotes"
if(Test-Path $Script:QuoteDir) {
    # Only export $QuoteDir if it refers to a folder that actually exists
    Set-Variable QuoteDir (Resolve-Path $QuoteDir) -Scope Global -Option AllScope -Description "Personal PATH Variable"

    function Get-Quote {
        param(
            $Path = "${QuoteDir}\attributed quotes.txt",
            [int]$Count=1
        )
        if(!(Test-Path $Path) ) {
            $Path = Join-Path ${QuoteDir} $Path
            if(!(Test-Path $Path) ) {
                $Path = $Path + ".txt"
            }
        }
        Get-Content $Path | Where-Object { $_ } | Get-Random -Count $Count
    }
    
    ## Get a random quote, and print it in yellow :D
    if( Test-Path "${QuoteDir}\attributed quotes.txt" ) {
        Get-Quote | Write-Host -Foreground Yellow
    }
    
    Set-Alias gq Get-Quote
    Trace-Message "Random Quotes Loaded"
}

## Fix em-dash screwing up our commands...
$ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = {
    param( $CommandName, $CommandLookupEventArgs )
    if($CommandName.Contains([char]8211)) {
        $CommandLookupEventArgs.Command = Get-Command ( $CommandName -replace ([char]8211), ([char]45) ) -ErrorAction Ignore
    }
}

Trace-Message "Profile Finished!" -KillTimer

## And finally, relax the code signing restriction so we can actually get work done
Set-ExecutionPolicy RemoteSigned Process

# SIG # Begin signature block
# MIIXxAYJKoZIhvcNAQcCoIIXtTCCF7ECAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGBLX9YFunORH8Q6Oq7PzQ2xe
# WeCgghL3MIID7jCCA1egAwIBAgIQfpPr+3zGTlnqS5p31Ab8OzANBgkqhkiG9w0B
# AQUFADCBizELMAkGA1UEBhMCWkExFTATBgNVBAgTDFdlc3Rlcm4gQ2FwZTEUMBIG
# A1UEBxMLRHVyYmFudmlsbGUxDzANBgNVBAoTBlRoYXd0ZTEdMBsGA1UECxMUVGhh
# d3RlIENlcnRpZmljYXRpb24xHzAdBgNVBAMTFlRoYXd0ZSBUaW1lc3RhbXBpbmcg
# Q0EwHhcNMTIxMjIxMDAwMDAwWhcNMjAxMjMwMjM1OTU5WjBeMQswCQYDVQQGEwJV
# UzEdMBsGA1UEChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFu
# dGVjIFRpbWUgU3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMjCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBALGss0lUS5ccEgrYJXmRIlcqb9y4JsRDc2vCvy5Q
# WvsUwnaOQwElQ7Sh4kX06Ld7w3TMIte0lAAC903tv7S3RCRrzV9FO9FEzkMScxeC
# i2m0K8uZHqxyGyZNcR+xMd37UWECU6aq9UksBXhFpS+JzueZ5/6M4lc/PcaS3Er4
# ezPkeQr78HWIQZz/xQNRmarXbJ+TaYdlKYOFwmAUxMjJOxTawIHwHw103pIiq8r3
# +3R8J+b3Sht/p8OeLa6K6qbmqicWfWH3mHERvOJQoUvlXfrlDqcsn6plINPYlujI
# fKVOSET/GeJEB5IL12iEgF1qeGRFzWBGflTBE3zFefHJwXECAwEAAaOB+jCB9zAd
# BgNVHQ4EFgQUX5r1blzMzHSa1N197z/b7EyALt0wMgYIKwYBBQUHAQEEJjAkMCIG
# CCsGAQUFBzABhhZodHRwOi8vb2NzcC50aGF3dGUuY29tMBIGA1UdEwEB/wQIMAYB
# Af8CAQAwPwYDVR0fBDgwNjA0oDKgMIYuaHR0cDovL2NybC50aGF3dGUuY29tL1Ro
# YXd0ZVRpbWVzdGFtcGluZ0NBLmNybDATBgNVHSUEDDAKBggrBgEFBQcDCDAOBgNV
# HQ8BAf8EBAMCAQYwKAYDVR0RBCEwH6QdMBsxGTAXBgNVBAMTEFRpbWVTdGFtcC0y
# MDQ4LTEwDQYJKoZIhvcNAQEFBQADgYEAAwmbj3nvf1kwqu9otfrjCR27T4IGXTdf
# plKfFo3qHJIJRG71betYfDDo+WmNI3MLEm9Hqa45EfgqsZuwGsOO61mWAK3ODE2y
# 0DGmCFwqevzieh1XTKhlGOl5QGIllm7HxzdqgyEIjkHq3dlXPx13SYcqFgZepjhq
# IhKjURmDfrYwggSjMIIDi6ADAgECAhAOz/Q4yP6/NW4E2GqYGxpQMA0GCSqGSIb3
# DQEBBQUAMF4xCzAJBgNVBAYTAlVTMR0wGwYDVQQKExRTeW1hbnRlYyBDb3Jwb3Jh
# dGlvbjEwMC4GA1UEAxMnU3ltYW50ZWMgVGltZSBTdGFtcGluZyBTZXJ2aWNlcyBD
# QSAtIEcyMB4XDTEyMTAxODAwMDAwMFoXDTIwMTIyOTIzNTk1OVowYjELMAkGA1UE
# BhMCVVMxHTAbBgNVBAoTFFN5bWFudGVjIENvcnBvcmF0aW9uMTQwMgYDVQQDEytT
# eW1hbnRlYyBUaW1lIFN0YW1waW5nIFNlcnZpY2VzIFNpZ25lciAtIEc0MIIBIjAN
# BgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAomMLOUS4uyOnREm7Dv+h8GEKU5Ow
# mNutLA9KxW7/hjxTVQ8VzgQ/K/2plpbZvmF5C1vJTIZ25eBDSyKV7sIrQ8Gf2Gi0
# jkBP7oU4uRHFI/JkWPAVMm9OV6GuiKQC1yoezUvh3WPVF4kyW7BemVqonShQDhfu
# ltthO0VRHc8SVguSR/yrrvZmPUescHLnkudfzRC5xINklBm9JYDh6NIipdC6Anqh
# d5NbZcPuF3S8QYYq3AhMjJKMkS2ed0QfaNaodHfbDlsyi1aLM73ZY8hJnTrFxeoz
# C9Lxoxv0i77Zs1eLO94Ep3oisiSuLsdwxb5OgyYI+wu9qU+ZCOEQKHKqzQIDAQAB
# o4IBVzCCAVMwDAYDVR0TAQH/BAIwADAWBgNVHSUBAf8EDDAKBggrBgEFBQcDCDAO
# BgNVHQ8BAf8EBAMCB4AwcwYIKwYBBQUHAQEEZzBlMCoGCCsGAQUFBzABhh5odHRw
# Oi8vdHMtb2NzcC53cy5zeW1hbnRlYy5jb20wNwYIKwYBBQUHMAKGK2h0dHA6Ly90
# cy1haWEud3Muc3ltYW50ZWMuY29tL3Rzcy1jYS1nMi5jZXIwPAYDVR0fBDUwMzAx
# oC+gLYYraHR0cDovL3RzLWNybC53cy5zeW1hbnRlYy5jb20vdHNzLWNhLWcyLmNy
# bDAoBgNVHREEITAfpB0wGzEZMBcGA1UEAxMQVGltZVN0YW1wLTIwNDgtMjAdBgNV
# HQ4EFgQURsZpow5KFB7VTNpSYxc/Xja8DeYwHwYDVR0jBBgwFoAUX5r1blzMzHSa
# 1N197z/b7EyALt0wDQYJKoZIhvcNAQEFBQADggEBAHg7tJEqAEzwj2IwN3ijhCcH
# bxiy3iXcoNSUA6qGTiWfmkADHN3O43nLIWgG2rYytG2/9CwmYzPkSWRtDebDZw73
# BaQ1bHyJFsbpst+y6d0gxnEPzZV03LZc3r03H0N45ni1zSgEIKOq8UvEiCmRDoDR
# EfzdXHZuT14ORUZBbg2w6jiasTraCXEQ/Bx5tIB7rGn0/Zy2DBYr8X9bCT2bW+IW
# yhOBbQAuOA2oKY8s4bL0WqkBrxWcLC9JG9siu8P+eJRRw4axgohd8D20UaF5Mysu
# e7ncIAkTcetqGVvP6KUwVyyJST+5z3/Jvz4iaGNTmr1pdKzFHTx/kuDDvBzYBHUw
# ggUmMIIEDqADAgECAhACXbrxBhFj1/jVxh2rtd9BMA0GCSqGSIb3DQEBCwUAMHIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJ
# RCBDb2RlIFNpZ25pbmcgQ0EwHhcNMTUwNTA0MDAwMDAwWhcNMTYwNTExMTIwMDAw
# WjBtMQswCQYDVQQGEwJVUzERMA8GA1UECBMITmV3IFlvcmsxFzAVBgNVBAcTDldl
# c3QgSGVucmlldHRhMRgwFgYDVQQKEw9Kb2VsIEguIEJlbm5ldHQxGDAWBgNVBAMT
# D0pvZWwgSC4gQmVubmV0dDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
# AJfRKhfiDjMovUELYgagznWf+HFcDENk118Y/K6UkQDwKmVyVOvDyaVefjSmZZcV
# NZqqYpm9d/Iajf2dauyC3pg3oay8KfXAADLHgbmbvYDc5zGuUNsTzMUOKlp9h13c
# qsg898JwpRpI659xCQgJjZ6V83QJh+wnHvjA9ojjA4xkbwhGp4Eit6B/uGthEA11
# IHcFcXeNI3fIkbwWiAw7ZoFtSLm688NFhxwm+JH3Xwj0HxuezsmU0Yc/po31CoST
# nGPVN8wppHYZ0GfPwuNK4TwaI0FEXxwdwB+mEduxa5e4zB8DyUZByFW338XkGfc1
# qcJJ+WTyNKFN7saevhwp02cCAwEAAaOCAbswggG3MB8GA1UdIwQYMBaAFFrEuXsq
# CqOl6nEDwGD5LfZldQ5YMB0GA1UdDgQWBBQV0aryV1RTeVOG+wlr2Z2bOVFAbTAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAwbjA1
# oDOgMYYvaHR0cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1n
# MS5jcmwwNaAzoDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3Vy
# ZWQtY3MtZzEuY3JsMEIGA1UdIAQ7MDkwNwYJYIZIAYb9bAMBMCowKAYIKwYBBQUH
# AgEWHGh0dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwgYQGCCsGAQUFBwEBBHgw
# djAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4GCCsGAQUF
# BzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRTSEEyQXNz
# dXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkqhkiG9w0B
# AQsFAAOCAQEAIi5p+6eRu6bMOSwJt9HSBkGbaPZlqKkMd4e6AyKIqCRabyjLISwd
# i32p8AT7r2oOubFy+R1LmbBMaPXORLLO9N88qxmJfwFSd+ZzfALevANdbGNp9+6A
# khe3PiR0+eL8ZM5gPJv26OvpYaRebJTfU++T1sS5dYaPAztMNsDzY3krc92O27AS
# WjTjWeILSryqRHXyj8KQbYyWpnG2gWRibjXi5ofL+BHyJQRET5pZbERvl2l9Bo4Z
# st8CM9EQDrdG2vhELNiA6jwenxNPOa6tPkgf8cH8qpGRBVr9yuTMSHS1p9Rc+ybx
# FSKiZkOw8iCR6ZQIeKkSVdwFf8V+HHPrETCCBTAwggQYoAMCAQICEAQJGBtf1btm
# dVNDtW+VUAgwDQYJKoZIhvcNAQELBQAwZTELMAkGA1UEBhMCVVMxFTATBgNVBAoT
# DERpZ2lDZXJ0IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTEkMCIGA1UE
# AxMbRGlnaUNlcnQgQXNzdXJlZCBJRCBSb290IENBMB4XDTEzMTAyMjEyMDAwMFoX
# DTI4MTAyMjEyMDAwMFowcjELMAkGA1UEBhMCVVMxFTATBgNVBAoTDERpZ2lDZXJ0
# IEluYzEZMBcGA1UECxMQd3d3LmRpZ2ljZXJ0LmNvbTExMC8GA1UEAxMoRGlnaUNl
# cnQgU0hBMiBBc3N1cmVkIElEIENvZGUgU2lnbmluZyBDQTCCASIwDQYJKoZIhvcN
# AQEBBQADggEPADCCAQoCggEBAPjTsxx/DhGvZ3cH0wsxSRnP0PtFmbE620T1f+Wo
# ndsy13Hqdp0FLreP+pJDwKX5idQ3Gde2qvCchqXYJawOeSg6funRZ9PG+yknx9N7
# I5TkkSOWkHeC+aGEI2YSVDNQdLEoJrskacLCUvIUZ4qJRdQtoaPpiCwgla4cSocI
# 3wz14k1gGL6qxLKucDFmM3E+rHCiq85/6XzLkqHlOzEcz+ryCuRXu0q16XTmK/5s
# y350OTYNkO/ktU6kqepqCquE86xnTrXE94zRICUj6whkPlKWwfIPEvTFjg/Bougs
# UfdzvL2FsWKDc0GCB+Q4i2pzINAPZHM8np+mM6n9Gd8lk9ECAwEAAaOCAc0wggHJ
# MBIGA1UdEwEB/wQIMAYBAf8CAQAwDgYDVR0PAQH/BAQDAgGGMBMGA1UdJQQMMAoG
# CCsGAQUFBwMDMHkGCCsGAQUFBwEBBG0wazAkBggrBgEFBQcwAYYYaHR0cDovL29j
# c3AuZGlnaWNlcnQuY29tMEMGCCsGAQUFBzAChjdodHRwOi8vY2FjZXJ0cy5kaWdp
# Y2VydC5jb20vRGlnaUNlcnRBc3N1cmVkSURSb290Q0EuY3J0MIGBBgNVHR8EejB4
# MDqgOKA2hjRodHRwOi8vY3JsNC5kaWdpY2VydC5jb20vRGlnaUNlcnRBc3N1cmVk
# SURSb290Q0EuY3JsMDqgOKA2hjRodHRwOi8vY3JsMy5kaWdpY2VydC5jb20vRGln
# aUNlcnRBc3N1cmVkSURSb290Q0EuY3JsME8GA1UdIARIMEYwOAYKYIZIAYb9bAAC
# BDAqMCgGCCsGAQUFBwIBFhxodHRwczovL3d3dy5kaWdpY2VydC5jb20vQ1BTMAoG
# CGCGSAGG/WwDMB0GA1UdDgQWBBRaxLl7KgqjpepxA8Bg+S32ZXUOWDAfBgNVHSME
# GDAWgBRF66Kv9JLLgjEtUYunpyGd823IDzANBgkqhkiG9w0BAQsFAAOCAQEAPuwN
# WiSz8yLRFcgsfCUpdqgdXRwtOhrE7zBh134LYP3DPQ/Er4v97yrfIFU3sOH20ZJ1
# D1G0bqWOWuJeJIFOEKTuP3GOYw4TS63XX0R58zYUBor3nEZOXP+QsRsHDpEV+7qv
# tVHCjSSuJMbHJyqhKSgaOnEoAjwukaPAJRHinBRHoXpoaK+bp1wgXNlxsQyPu6j4
# xRJon89Ay0BEpRPw5mQMJQhCMrI2iiQC/i9yfhzXSUWW6Fkd6fp0ZGuy62ZD2rOw
# jNXpDd32ASDOmTFjPQgaGLOBm0/GkxAG/AeB+ova+YJJ92JuoVP6EpQYhS6Skepo
# bEQysmah5xikmmRR7zGCBDcwggQzAgEBMIGGMHIxCzAJBgNVBAYTAlVTMRUwEwYD
# VQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAv
# BgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EC
# EAJduvEGEWPX+NXGHau130EwCQYFKw4DAhoFAKB4MBgGCisGAQQBgjcCAQwxCjAI
# oAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIB
# CzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkEMRYEFEK+ajEqdWJom+3DIJ8V
# 5dxU28+WMA0GCSqGSIb3DQEBAQUABIIBAE3f3+MbO4GvzA/XmIr0Szr0fKfM1qgg
# OgCjxRw+TlN+ytzV7lZcxbPTE7AMRVfm97SbS+o1tGQooxwAZRff/7qdNknF+lfD
# 7QdGqKBOlEqSBmxDzrG6spnuC8eca8FUtLbqyDLjNNvtWednPj+EjUpKaAeVWEKR
# pVwHIbTUCEXOTIr2vPcliEjOXw1aYBLWsmAk7SFkvqkEB5GXVlh/0cVwziDSUwDp
# Fsy8Wvub4cZjr79LTE+ss+NY+/udqgquDi1Kgf9idVSvtDcph0m6/1Ri1J3zBQX+
# 8PCsjS4z1qKZuECLyNDVcHkpfdkNz4FnkQoCmr/wRxr/fIE6k4Mzs8ehggILMIIC
# BwYJKoZIhvcNAQkGMYIB+DCCAfQCAQEwcjBeMQswCQYDVQQGEwJVUzEdMBsGA1UE
# ChMUU3ltYW50ZWMgQ29ycG9yYXRpb24xMDAuBgNVBAMTJ1N5bWFudGVjIFRpbWUg
# U3RhbXBpbmcgU2VydmljZXMgQ0EgLSBHMgIQDs/0OMj+vzVuBNhqmBsaUDAJBgUr
# DgMCGgUAoF0wGAYJKoZIhvcNAQkDMQsGCSqGSIb3DQEHATAcBgkqhkiG9w0BCQUx
# DxcNMTUxMDIxMjI1NzIxWjAjBgkqhkiG9w0BCQQxFgQU7si9+w2c0LF42xmug4+D
# wYuB0z4wDQYJKoZIhvcNAQEBBQAEggEAdACmXOhAc3OQL9oNF/Jx4e7xIaTrBAgX
# 8u6MEBoUA+XxQWVdoME050mWySpO9NtQJWrrsAIneCEpYbwwNGeEgOrmRemQhred
# jSDUN6XFa0We9NoyUGC6Cob+GOdL1s2ludrJ+MlOCht1myJMMFhV7X7rKVj8xmHb
# vwBd7r26QH3Y1SIq1Tmjg/Qwf9Q5EOv7gaR7/qMfxutjROqvAnALl4+tG6gtopHI
# rb9lmuoBLncKi+YslDVMXskm8fHAKUQIVXcbSfOSgEd1S33YF1dQ05U9VdDBIDjf
# jYwa9onZQtKvemzjmDj3vwouS9UtXYz4vzuD1FhWtUi8Kt95HOW4Bw==
# SIG # End signature block

