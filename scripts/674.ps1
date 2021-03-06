########################################################################################################################
# NAME
#     New-RDP
#
# SYNOPSIS
#     Creates a new RDP file to store Remote Desktop connection settings.
#
# SYNTAX
#     Start-RDP [-Path] <string> [[-Server] <string>] [-PassThru] [-Force]
#
# DETAILED DESCRIPTION
#     The New-RDP cmdlet creates a new, blank RDP file with required settings.
#
# PARAMETERS
#     -Path <string>
#         Specifies the path to save the new RDP file at.
#
#         Required?                    true
#         Position?                    1
#         Default value                
#         Accept pipeline input?       false
#         Accept wildcard characters?  false
#
#     -Server <string>
#         Specifies the name of the server to connect to.  May also include an IP address, domain, and/or port.
#
#         Required?                    false
#         Position?                    2
#         Default value                
#         Accept pipeline input?       false
#         Accept wildcard characters?  false
#
#     -PassThru <SwitchParameter>
#         Passes thru an object that represents the new RDP file to the pipeline.  By default, this cmdlet does
#         not pass any objects through the pipeline.
#
#         Required?                    false
#         Position?                    named
#         Default value                false
#         Accept pipeline input?       false
#         Accept wildcard characters?  false
#
#     -Force <SwitchParameter>
#         Overrides restrictions that prevent the command from succeeding.
#
#         Required?                    false
#         Position?                    named
#         Default value                false
#         Accept pipeline input?       false
#         Accept wildcard characters?  false
#
# INPUT TYPE
#     
#
# RETURN TYPE
#     System.IO.FileInfo
#
# NOTES
#
#     -------------------------- EXAMPLE 1 --------------------------
#
#     C:\PS>New-RDP -Path C:\myserver.rdp -Server myserver
#
#
#     This command creates a new RDP file to connect to the server named "myserver".
#
#

#Function global:New-RDP {
    param(
        [string]$Path = $(throw "A path to the new RDP file is required."),
        [string]$Server = "",
        [switch]$PassThru,
        [switch]$Force
    )

    if (!(Test-Path $path) -or $force) {
        Set-Content -Path $path -Value "full address:s:$server" -Force
        if ($passthru) {
            Get-ChildItem -Path $path
        }
    } else {
        throw "Path already exists, use the -Force switch."
    }
#}
