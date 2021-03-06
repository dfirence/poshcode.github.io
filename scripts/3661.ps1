function ConvertTo-Module {
<#
    .SYNOPSIS
    Quickly convert a .NET type's static methods into functions

    .DESCRIPTION
    Quickly convert a .NET type's static methods into functions.
    
    This function returns a PSModuleInfo, so you should pipe its
    output to Import-Module to use the exported functions.

    .PARAMETER Type
    The type from which to import static methods. 

    .INPUTS
    System.String, System.Type

    .OUTPUTS
    PSModuleInfo

    .EXAMPLE
    ConvertTo-Module System.Math | Import-Module -Verbose

    .EXAMPLE
    [math] | ConvertTo-Module | Import-Module -Verbose

#>
    [outputtype([psmoduleinfo])]
    param(
        [parameter(
            position=0,
            valuefrompipeline=$true,
            mandatory=$true)]
        [validatenotnull()]
        [type]$Type
    )

    new-module {
        param($type)
         
        ($exports = $type.getmethods("static,public").Name | sort -uniq) | `
            % {
                $func = $_
                new-item "function:script:$($_)" `
                    -Value {
                        # look mom! no [scriptblock]::create!
@@                        ($type.FullName -as [type])::$func.invoke($args)

                    }.GetNewClosure() # capture the value of $func
            }
        export-modulemember -function $exports
    } -name $type.Name -ArgumentList $type
}
