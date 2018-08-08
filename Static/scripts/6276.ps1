#requires -Version 3

function Get-Sequence
{
  <#
    .SYNOPSIS
        Performs various transformations on the data.
    .DESCRIPTION
        Performs simple transformations on data without needing to define functions for each transformation.

        Rather than declaring a function that describes how to transform each element, what if we could just
        apply a simple transformation to each element that didn’t require a function definition?
        This can be accomplished with lambda functions.

        A lambda function is a nameless (i.e. anonymous) function that accepts arguments and returns the result
        of a simple operation that doesn’t affect variables outside of its scope. In PowerShell lingo, a lambda
        function is simply a script block with a ‘param’ declaration.
    .EXAMPLE
        $IntArray = @(1, 2, 3, 4, 5, 6)
 
        $Double = { param($x) $x * 2 }
        $Sum = { param($x, $y) $x + $y }
        $Product = { param($x, $y) $x * $y }
        $IsEven = { param($x) $x % 2 -eq 0 }
 
        Get-Sequence -Map -Expression $Double -Sequence $IntArray
    .EXAMPLE
        Get-Sequence -Reduce -Expression $Sum -Sequence $IntArray
    .EXAMPLE
        Get-Sequence -Reduce $Product $IntArray
    .EXAMPLE
        Get-Sequence -Filter -Expression $IsEven -Sequence $IntArray
    .NOTES
        Matt Graeber is responsible for the guts of this code.

    .LINK
        http://www.powershellmagazine.com/2013/12/23/simplifying-data-manipulation-in-powershell-with-lambda-functions/
  #>
    [CmdletBinding(DefaultParameterSetName='None')]
    Param
    (
        # Applies a function to each element of a sequence. 
        [Parameter(Mandatory, Position=0, ParameterSetName='Map Sequence')]
        [switch]
        $Map,

        # Applies a function with two arguments cumulatively to a sequence of objects, ‘reducing’ the dataset to a single object.
        [Parameter(Mandatory, Position=0, ParameterSetName='Reduce Sequence')]
        [switch]
        $Reduce,

        # Returns a subset of objects from a sequence when a function evaluates to true.
        [Parameter(Mandatory, Position=0, ParameterSetName='Filter Sequence')]
        [switch]
        $Filter,

        # A script block with a ‘param’ declaration.
        [Parameter(Mandatory, Position=1)]
        [scriptblock]
        $Expression,
 
        # A dataset (An array of anything depending upon the given Expression.)
        [Parameter(Mandatory, Position=2)]
        [ValidateNotNullOrEmpty()]
        [object[]]
        $Sequence
    )

    Begin
    {
        Set-Variable -Option      Constant `
                     -Name        PARAMETER_ERROR `
                     -Value       "Incorrect number of parameters in Expression." `
                     -Description "The Expression ([scriptblock]) specified the wrong number of parameters."

        Set-Variable -Option      Constant `
                     -Name        FUNCTIONS_ERROR `
                     -Value       "The Map, Reduce or Filter switch was not specified." `
                     -Description "The sub-function/switch (Map, Reduce or Filter) was not specified."
    }
    Process
    {
        switch ($PSCmdlet.ParameterSetName)
        {
            'Map Sequence'
            {
                if ($Expression.Ast.ParamBlock.Parameters.Count -eq 1)
                {
                    $Sequence | ForEach-Object { &$Expression $_ }
                }
                else
                {
                    throw $PARAMETER_ERROR
                }
            }
            'Reduce Sequence'
            {
                if ($Expression.Ast.ParamBlock.Parameters.Count -eq 2)
                {
                    $accumulatedValue = $Sequence[0]

                    if ($Sequence.Length -gt 1)
                    {
                        $Sequence[1..($Sequence.Length - 1)] | ForEach-Object {
                            $accumulatedValue = &$Expression $accumulatedValue $_
                        }
                    }
 
                    $accumulatedValue
                }
                else
                {
                    throw $PARAMETER_ERROR
                }
            }
            'Filter Sequence'
            {
                if ($Expression.Ast.ParamBlock.Parameters.Count -eq 1)
                {
                    $Sequence | Where-Object { &$Expression $_ -eq $true }
                }
                else
                {
                    throw $PARAMETER_ERROR
                }
            }
            'Default'
            {
                throw $FUNCTIONS_ERROR
            }
        }
    }
    End
    {
    }
}
