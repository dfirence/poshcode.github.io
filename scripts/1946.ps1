Function global:GET-NEWpassword( $Length, $Complexity) {

# $Length variable serves a dual Purpose
# It assumes nobody wants a tiny password less than
# 8 characters so anything less than than it used
# to pull up one of 8 predined password templates

    If ($Length -eq $NULL) { $Length = 0 }

# If you're going "100%" random you can provide a second
# value which is complexity.
# 
# 1 - just random lowercase letter3
# 3 - is pretty decent (upper/lower/numbers)
# 9 - is "Muah hahaahahahahah!!!"

    If ($Complexity -eq $NULL) { $Complexity = 3 }

# If password Length provided is less than eight
# Function will use one of 8 predefined templates

# Default Settings 8 Character SemiPronouncable Password from a previous
# password generator on Poshcode.org
#
# These are predinable password sets, as long as you like, max *8*
# C = Upper Case Consanant
# c = Lower Case Consanant
# L = Upper Case Alphabet
# l = Lower Case Alphabet
# D = Decimal numbers
# h = Hexidecimal series with Lowercase a-f
# H = Hexidecimal series with Uppercase A-F
# * = Any defined character in the sets

    $passwordTemplateList=,"Cvcvcdd."
    $passwordTemplateList+=,"CvCddvVc"
    $passwordTemplateList+=,"********"
    $passwordTemplateList+=,"CccddVvv"
    $passwordTemplateList+=,"HHHHHHHH"
    $passwordTemplateList+=,"d.d.d.d."
    $passwordTemplateList+=,"dddddddd"
    $passwordTemplateList+=,"0V0cC.0C"

    $PasswordTemplate=$NULL

# All character sets are part of a single Dynamic Array which you
# can easily add to

#Lowercase
    $AsciiArray=,("l","abcdefghijklmnopqrstuvwxyz")
#Uppercase
    $AsciiArray+=,("L","ABCDEFGHIJKLMNOPQRSTUVWXYZ")
#Decimal Numbers
    $AsciiArray+=,("d","0123456789")
#Punctuation
    $AsciiArray+=,(".","!#$%'()*+,-./:;=>?@[]^_")
#Lowercase Vowels
    $AsciiArray+=,("v","aeiou")
#Uppercase Vowels
    $AsciiArray+=,("V","AEIOU")
#HexadecimalNumbers (lowercase on the a-f)
    $AsciiArray+=,("h","0123456789abcdef")
#HexadecimalNumbers (UPPERCASE on the A-F)
    $AsciiArray+=,("H","0123456789ABCDEF")
#Lowercase Consonants
    $AsciiArray+=,("c","abcdfghjklmnpqrstvwxyz")
#Uppercase Consonants
    $AsciiArray+=,("C","ABCDFGHJKLMNPQRSTVWXYZ")

# This variable is important.  If you ADD to the Array
# It checks the size for all of the calculations below
# First Character in the Array such as l,L,d,v etc
# identifies the contents of that row of the array
# such as lowercaseletter, UPPERCASELETTER, Decimalnumber
# vowel

    $Arraysize=($AsciiArray.Length)-1

# Here is part of the magic
#
# If we have a password length less than 8 supplied
# from the parameter, we will call up one of 8 
# predefined templates and use THAT format for
# the password.
#

    If ($Length -lt 8) 
    { 
        $PasswordTemplate = $PasswordTemplateList[$Length]; 
        $Complexity = $Arraysize
    }
#
# Otherwise it is a large password and we will build
# A Pseudo template where each character is our "*"
# wildcard

    Else 
    { 
        Foreach ($count in 1..$Length) 
        { $PasswordTemplate+="*" } 
    }

# Blank out the new Password for good measure, JUST CUZ!

    $NewPassword=$NULL
    
# First loop.  Look at and ACT upon each character in the template
# to produce the appropriate content for that position in the
# password

Foreach ( $item in 0..(($passwordTemplate.Length)-1) ) {
    
    $Asciiset = $passwordtemplate[$item]

# Here is our second loop.  We're going to match the Type of
# Character being used against the master list in the array
# When found, we use that set

# Special scenario.  If we're doing a "Wildcard" "*" then we have to pick
# a random set from the Array to be able to pick a random character

    If ($AsciiSet -eq "*"){ $Asciiset=$AsciiArray[(GET-RANDOM $Complexity)][0]}

    $Arraypos=0
    
# While the two don't match, keep checking the sets.

    while ([byte][char]$AsciiSet -ne [byte][char]($AsciiArray[$Arraypos][0])){$Arraypos++}

# $Arraypos holds the correct set.  Pull out the String of Characters
# Get the length of the array, and use GET-RANDOM to pick a byte

    $String=$AsciiArray[$ArrayPos][1]
    $StringLength=$String.Length

# Now add that to the password

    $NewPassword+=$String.substring((GET-RANDOM $StringLength),1)

# End of loop - this goes on until the password is built

    }

    # this line doesn't work in Windows XP natively, but you can download a utility
    # called "ToClip" that does the same thing.  REplace "Clip" with "ToClip"
    # http://www.fullspan.com/proj/toclip/index.html
    #
    # Send the password to the Clipboard

    $NewPassword | clip

    # Return the password in Plaintext and as Secure-String

    Return $NewPassword, (CONVERTTO-Securestring $NewPassword -asplaintext -force)

}
