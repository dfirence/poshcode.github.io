########################################################################################################################
# NAME
#     Edit-RDP
#
# SYNOPSIS
#     Opens a RDP file for editing.
#
# SYNTAX
#     Edit-RDP [-Path] <string>
#
# DETAILED DESCRIPTION
#     The Edit-RDP cmdlet opens an existing RDP file for editing using the Microsoft Terminal Services Client.
#
# PARAMETERS
#     -Path <string>
#         Specifies the path to the RDP file.
#
#         Required?                    true
#         Position?                    1
#         Default value                
#         Accept pipeline input?       false
#         Accept wildcard characters?  false
#
# INPUT TYPE
#     
#
# RETURN TYPE
#     
#
# NOTES
#
#     -------------------------- EXAMPLE 1 --------------------------
#
#     C:\PS>Edit-RDP -Path C:\myserver.rdp
#
#
#     This command opens the specified RDP file for edit in Terminal Services Client.
#
#

#Function global:Edit-RDP {
    param(
        [string]$Path = (throw "A path to a RDP file is required.")
    )

    if (Test-Path $path) {
        mstsc.exe /edit $path
    } else {
        throw "Path does not exist."
    }
#}
