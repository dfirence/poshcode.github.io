function Rotate-Right {
<#
.SYNOPSIS
Performs a binary rotate right operation.
Author: Matthew Graeber (@mattifestation)

.DESCRIPTION
Rather than implementing the logic to perform a binary rotate operation,
Rotate-Right wraps the private methods contained within
System.Security.Cryptography.SHA256Managed and
System.Security.Cryptography.SHA512Managed.

.OUTPUTS
System.UInt32. Returns a 32-bit unsigned integer
System.UInt64. Returns a 64-bit unsigned integer

.EXAMPLE
PS > Rotate-Right 256 1
128

.EXAMPLE
PS > Rotate-Right ([UInt64] 4294967296) 32
1

.LINK
http://www.exploit-monday.com/2012/07/finding-powershells-missing-binary.html

#>

    [CmdletBinding(DefaultParameterSetName = '32bit')] Param (
        # The 32-bit value to be rotated
        [Parameter(Mandatory = $True, Position = 0, ParameterSetName = '32bit')] [UInt32] $Value32,
        # The 64-bit value to be rotated
        [Parameter(Mandatory = $True, Position = 0, ParameterSetName = '64bit')] [UInt64] $Value64,
        # The offset by which the value will be rotated
        [Parameter(Mandatory = $True, Position = 1)] [Int32] $Offset
    )
    
    $BindingFlags = 'NonPublic, Static'
    
    switch ($PsCmdlet.ParameterSetName) {
        '32bit' {
            $RorMethodInfo = [System.Security.Cryptography.SHA256Managed].GetMethod('RotateRight', $BindingFlags, $null, @([UInt32], [Int32]), $null)
            $RorMethodInfo.Invoke($null, @($Value32, $Offset))
        }
        '64bit' {
            $RorMethodInfo = [System.Security.Cryptography.SHA512Managed].GetMethod('RotateRight', $BindingFlags, $null, @([UInt64], [Int32]), $null)
            $RorMethodInfo.Invoke($null, @($Value64, $Offset))
        }
    }
}
