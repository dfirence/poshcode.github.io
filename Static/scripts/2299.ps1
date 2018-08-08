########################################################################
## Copyright (c) Joel Bennett, 2010
## Free for use under MS-PL, MS-RL, GPL 2, or BSD license. Your choice. 

function Write-Output {
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
    [AllowEmptyCollection()]
    [AllowNull()]
    [System.Management.Automation.PSObject]
    ${InputObject}
,
	[Parameter()]
	[Switch]
	$Passthru
, 
	[Parameter()]
	[Switch]
	$CollectInput
)

begin
{
	if($CollectInput) {
		$Collection = New-Object System.Collections.Generic.List[PSObject]
	}
}

process
{
	if($InputObject) {
		if($CollectInput) {
			$Collection.AddRange( ([PSObject[]]@($InputObject)) )
		} else {
			$PSCmdlet.WriteObject( $InputObject, !$Passthru )
		}
	}
}

end
{
	if($CollectInput) {
		$PSCmdlet.WriteObject( $Collection, !$Passthru )
	}
}
<#
.SYNOPSIS
    Sends the specified objects to the next command in the pipeline. If the command is the last 
    command in the pipeline, the objects are displayed in the console.
.DESCRIPTION
    The Write-Output function sends the specified object down the pipeline to the next command. If the command is the last command in the pipeline, the object is displayed in the console.
    
    Write-Output sends objects down the primary pipeline, also known as the "output stream" or the "success pipeline." To send error objects down the error pipeline, use Write-Error.
    
	This function provides a pair of enhancements to the built-in Write-Output. First, it offers the option of Passthru, which causes collections to be output without unrolling (that is, output as collections to the pipeline), and second, it includes an option to collect input from the pipeline and output it all at once at the end.
.PARAMETER InputObject
    Specifies the objects to send down the pipeline. Enter a variable that contains the objects, or type a command or expression that gets the objects.
.PARAMETER CollectInput
	Specifies that pipeline input should be collected and output all at once at the end. This effectively allows you to take streaming input and turn it into a collection.
	
	Note that this causes the output to be a List[PSObject].
.PARAMETER Passthru
	Specifies that the output should be "as-is" ... meaning that if you specify a collection as input, you'll get a collection as output, rather than having Write-Output output individual items one at a time.
.EXAMPLE    
    $p = get-process
    
    C:\PS>write-output $p
    
    Description
    -----------
    These commands get objects representing the processes running on the computer and display the objects on the console.
    
.EXAMPLE    
    $p = get-process | Select-Object -First 10
    
    C:\PS>write-output $p  | ForEach-Object { $_.GetType() }
		
	IsPublic IsSerial Name       BaseType                             
	-------- -------- ----       --------                             
	True     False    Process    System.ComponentModel.Component      
	True     False    Process    System.ComponentModel.Component      
	True     False    Process    System.ComponentModel.Component      
	True     False    Process    System.ComponentModel.Component      
	True     False    Process    System.ComponentModel.Component      
	True     False    Process    System.ComponentModel.Component      
	True     False    Process    System.ComponentModel.Component      
	True     False    Process    System.ComponentModel.Component      
	True     False    Process    System.ComponentModel.Component      
	True     False    Process    System.ComponentModel.Component

    C:\PS>write-output $p -passthru | ForEach-Object { $_.GetType() }
    
	
	IsPublic IsSerial Name       BaseType                             
	-------- -------- ----       --------                             
	True     True     Object[]   System.Array    
	
    Description
    -----------
    These commands demonstrate the difference between using and not using -passthru. Without it, each object passes through the ForEach and it's type is output. With -Passthru, only a single object is output, with a collection type of Object[].
    
.EXAMPLE
    Get-Process | Select-Object -First 10 | Write-Output -Passthru | ForEach-Object { $_.GetType() }
    
    Description
    -----------
    This command pipes the first ten processes to the ForEach-Object, demonstrating that -Passthru will always force collection output.
    
.EXAMPLE
    Get-Process | Write-Output -Passthru -CollectInput | ForEach-Object { $_.GetType() }
    
    Description
    -----------
    This command collects all of the processes before outputting them to the ForEach-Object as a List[PSObject]
#>
}
