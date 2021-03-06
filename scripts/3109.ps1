##############################################
##Import group policies from a folder to a Domain Controller
##Author: Adam Liquorish
##
##*Currently will only run on Server 2008 R2
##*Script is based on the Microsoft Visual Basic Script for importing group policies.
##*Server doesnt need to be defined as PDC emulator will be contacted by default
##############################################

######Define Parameters

param(

[Parameter(Mandatory=$true,

    HelpMessage="Enter Path for input ie c:\Temp\output.html.")]

    [ValidateNotNullOrEmpty()]

    [string]$outputpath=$(Read-Host -prompt "Path for input"),

[Parameter(Mandatory=$true,

    HelpMessage="Enter Domain")]

    [ValidateNotNullOrEmpty()]

    [string]$computername=$(Read-Host -prompt "Domain Name")

)
######Import Modules
import-module grouppolicy
######End Import Modules

######Define Variables

#Commented out due to introduction of parameters

#zeroize variables

$start=get-date

$prog=1

$i=$null

$a=$null

$b=$null

$c=$null

$max=$null

##Function to take gpo name from each xml

#Start Function

function GPOName ($b)

{

([xml](get-content $b)).GPO.Name

}

#End function

$a=get-childitem -recurse $path

$b=$a|where-object {$_.Name -eq "gpreport.xml"}

$c=foreach ($test in $b){GPOName($test.fullname)}

$c|

Foreach-object {

#Counter for Progress Bar

$max=$b.length

$i++

#Import GPO

Import-GPO -BackupGpoName $_ -TargetName $_ -path $path -CreateIfNeeded -Dom $domain

#Write Progress

Write-Progress -activity "Adding GPO's" -status "Added $i of $max" -PercentComplete (($i/$b.length)*100) -CurrentOperation $_}

Write-Host "Completed....Total Number of GPO's imported:"$b.length
