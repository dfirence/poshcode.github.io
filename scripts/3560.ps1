function Fill-ErUp
{
<#

.Synopsis
    The function will append random integers to a specified file through $Path until it reaches the $Size requirement.
.Description
    Fills a file up with random integers until the file size is equal to the desired size.  Used to increase file mememory size.
.Parameter FilePath
    Path of the file that will be monitored
.Parameter Size
    File size is monitored against this value. When file size is equal or greater than this value, function ceases to operate
.Example
Fill-ErUp -FilePath C:\Test -Size 3MB
Fills up the file with random integers until a size of at least 3MB is reached
.Example
Fill-ErUp -FilePath C:\Test -Size 3MB -ScriptString "Write-Output 'File filled to specified Size'"
After File is filled, the ScriptString is output to the terminal
.Notes
	Author: Paul Kiri.
#>
param(

[Parameter(mandatory=$true,position=0)]
[string[]]$FilePath
,
[Parameter(mandatory=$true,position=1)]
[int]$Size
,
[Parameter(mandatory=$false)]
[string[]]$ScriptString

)

    while((Get-ChildItem $FilePath).length -le $Size)
    {
        Add-Content $FilePath -Value (Get-Random)
    }
Invoke-Command -ScriptBlock ([scriptblock]::Create($ScriptString))
}
