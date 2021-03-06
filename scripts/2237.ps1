#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\
#
# Script Name: Get-NewPassword.ps1
#       Title: Random Password Generator
#     Version: 1.0
#      Author: johnwcannon at gmail dot com
#        Date: September 16th, 2010
#
# Description: Password gerneration function based upon code
#              originally posted on PoshCode.org by Sean Kearney
#              
#		Usage: Without any arguments, Get-NewPassword
#			   generates an 8 character password with
#			   upper, lower, and numeric characters.
#			   It can accept 2 options, the first is
#			   password length (up to 94) and the other
#			   is complexity (1 to 4). The complexity
#			   Levels are:
#			   1 - Lowercase characters only
#			   2 - Lower and Uppercase characters
#			   3 - Upper, Lower and Numeric (default)
#			   4 - Upper, Lower, Numeric, and Special chars
#			   *Passwords generated do NOT reuse characters
#			    and attempt to avoid creating repeating series
#			    of characters, like abc or 123
#/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\

function global:Get-NewPassword([int]$PasswordLength, [int]$Complexity) {

#Perform some (very) basic input sanitation on the variables (possibly) getting passed
if ($PasswordLength -ne 0)
	{
	if ($PasswordLength -gt 94)
		{
		Write-Host "That's a long password you requested!  There aren't enough unique characters to make a password that long."
		Return
		}
	if ($PasswordLength -lt 1)
		{
		Write-Host $PasswordLength
		Write-Host "You have entered an invalid password length."
		Return
		}
	}
if ($Complexity -ne 0)
	{
	if (($Complexity -lt 1) -or ($Complexity -gt 4))
		{
		Write-Host "You entered an invalid complexity value!"
		Return
		}
	}
# Password length can be from 1 to 94, but defaults to 8 if no value is passed
If ($PasswordLength -eq 0)
	{
	$PasswordLength=8
	}
#Set a default complexity level to 3 if one is not specified
If ($Complexity -eq 0) { $Complexity=3 }

if (($Complexity -eq 3) -and ($PasswordLength -gt 62))
	{
	Write-Host "You have requested a password that has more characters than the `ncomplexity you chose.  Try a complexity of 4 next time"
	Return
	}
if (($Complexity -eq 2) -and ($PasswordLength -gt 52))
	{
	Write-Host "You have requested a password that has more characters than the `ncomplexity you chose.  Try a complexity of 3 or 4 next time"
	Return
	}
if (($Complexity -eq 1) -and ($PasswordLength -gt 26))
	{
	Write-Host "You have requested a password that has more characters than the `ncomplexity you chose.  Try a complexity of 2, 3 or 4 next time"
	Return
	}

# Declare arrays holding the decimal equivalents of the ascii characters
$uppercasedec = 65..90
$lowercasedec = 97..122
$numeraldec = 48..57
#There are 4 ranges of special characters
$specialchardec = 33..47
$specialchardec1 = 58..64
$specialchardec2 = 91..96
$specialchardec3 = 123..126


# Complexity can be from 1 - 4 with the results being
# 1 - Pure lowercase Ascii
# 2 - Mix Uppercase and Lowercase Ascii
# 3 - Ascii Upper/Lower with Numbers
# 4 - Ascii Upper/Lower with Numbers and Special Characters

#Build an array of the complexity specified
if($Complexity -eq 1)
	{
	$passchars += $lowercasedec
	}
if($Complexity -eq 2)
	{
	$passchars += $lowercasedec + $uppercasedec
	}
if($Complexity -eq 3)
	{
	$passchars += $lowercasedec + $uppercasedec + $numeraldec
	}
if($Complexity -eq 4)
	{
	$passchars += $lowercasedec + $uppercasedec + $numeraldec + `
	$specialchardec + $specialchardec1 + $specialchardec2 + $specialchardec3 
	}
	

#Here is the loop that generates a character until the requested
#password length is reached
Foreach ($counter in 1..$PasswordLength)
	{
	$lastchar = $null
	#We pluck out a random character from the character set chosen
	$tempchar = ($passchars | Get-Random)
	
	#We asign a last character chosen variable to prevent repeating patterns like abc or 123
	$lastchar = $tempchar

	#If statement to check if character is adjacent to last character used
	#and checks to make sure that there aren't only two characters left in
	#the set that might create an infinite loop if they are actually adjacent
	If (($lastchar -eq ($tempchar + 1)) -or ($lastchar -eq ($tempchar - 1)) -and ($passchars.count -gt 2))
		{
		#Let's pluck out a new random character since the last one was adjacent
		$tempchar = ($passchars | Get-Random)
		
		#Reset the $lastchar variable so it can be tested again
		$lastchar = $tempchar
		}
	#Now that we have verified that the character isn't adjacent to
	#the last character we pulled, we need to remove it from the array
	$passchars = ($passchars | Where-Object {$_ -ne $tempchar})
	
	#Now we build the password and convert the decimal to ASCII
	$NewPassword=$NewPassword+[char]($tempchar)
	}

# When we are done, we return the completed password 
# back to the calling party
Return $NewPassword

}

