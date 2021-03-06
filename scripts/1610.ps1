#.Synopsis
#  Generate pseudo-random passwords based on templates
#
#.Parameter Template
#  The template for the password you want to generate. This defines which types of characters are generated for each character in the password. The valid template characters are:
#  * * - any character: a-z, A-Z, 0-9 + punctuation
#  * A - any alphanumeric character: a-z, A-Z, 0-9
#  * a - any alphabetic character: a-z, A-Z
#  * L - any uppercase letter
#  * l - any lowercase letter
#  * C - uppercase consonant  
#  * c - lowercase consonant
#  * V - uppercase vowel
#  * v - lowercase vowel
#  * . - punctuation
#  * # - numeric character
#  * An actual number modifies the presceding character to allow UP TO that many of that character class
#  * An escaped character: \L will be inserted literally...
#  * Anything else will be inserted literally...
#
#.Example
#  New-Password "Cvcvc##"
#  Jemad46
#
#  Description
#  -----------
#  Generates a "pronounceable" 7 character password consisting of alternating consonants and vowels followed by a 2-digit number
#
#.Example
#  ("Cvcvc##," * 8).Split(",") | New-Password
#
#  Description
#  -----------
#  Demonstrates that the function can take pipeline input. Passing multiple templates via the pipeline will generate multiple passwords. 
#  In this case, we generate EIGHT "pronounceable" 7 character password consisting of alternating consonants and vowels followed by a 2-digit number
#
#.Example
#  New-Password "Cvvc.Cvvc##"
#  Ziir-Diud55
#
#  Description
#  -----------
#  Generates a password which starts with an upper-case consonant, followed by two lower-case vowels, followed by a punctuation mark, followed by an upper-case consonant, followed by two lower-case vowels, followed by two numbers.
#
#.Example
#  New-Password "********"
#  !u($OA:*
#
#  Description
#  -----------
#  Generates a totally random 8 character password
#
#.Example
#  New-Password "Get-Cvcvvc"
#  Get-Wodeaj
#
#  Description
#  -----------
#  Generates a password which looks like a strange PowerShell command, starting with "Get-" and ending with an uppercase consonant, a vowel, a consonant, two vowels, and a final consonant.
#
#.Notes
#  On PowerShell 2.0 if you define an alias "rand" to point to Microsoft.PowerShell.Utility\Get-Random, this script will use the Get-Random cmdlet instead of it's built-in rand function.
#  Set-Alias rand Microsoft.PowerShell.Utility\Get-Random -Option AllScope
#.Inputs
#  [String]
#    A string template for a password
#.Outputs 
#  [String] 
#    A password string

# function New-Password {
#[CmdletBinding()]
Param (
#   [Parameter(ValueFromPipeline=$true,Position=0)]
   [string]$Template = "************"
)

BEGIN {
  #if($Template.Length -lt 8) { THROW "Passwords less than 8 characters are not allowed." }
   ## You might consider avoiding the O which is easily confused with 0 except in the Consolas font ;)
   [char[]]$UpperAlpha = 'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z'
   [char[]]$LowerAlpha = 'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'
   [char[]]$UpperConsonants = 'B','C','D','F','G','H','J','K','L','M','N','P','Q','R','S','T','V','W','X','Y','Z'
   [char[]]$LowerConsonants = 'b','c','d','f','g','h','j','k','l','m','n','p','q','r','s','t','v','w','x','y','z'
   [char[]]$LowerVowels = 'a','e','i','o','u' 
   [char[]]$UpperVowels = 'A','E','I','O','U' 
   [char[]]$Numeric = '1','2','3','4','5','6','7','8','9','0'
   # In case this is used in a DCPromo answer files, theres a few chars to avoid: Ampersand, Less than, double quote and back slash
   # And because they're easily confused for ' , let's also avoid the backtick ` 
   ## '&','<','"','\','``',
   [char[]]$Punctuation = '!','#','$','%','''','(',')','*','+',',','-','.','/',':',';','=','>','?','@','[',']','^','_' 
   
   $script:RANDOM = new-object Random
   function rand { 
      begin { $list = @() }
      process { $list += $_ }
      end { 
         $list[$RANDOM.Next(0,$list.Count-1)] 
      }
   }
}
PROCESS {
   if($_) { $Template = $_ }
   Write-Verbose "Template: $Template"
   $password = ""
   $randoms = @()
   for($c = 0; $c -lt $Template.Length; $c++) {
      switch -CaseSensitive ($Template[$c])
      {
         'l' { # Make this character a Lowercase Alpha
            $password += $LowerAlpha | rand
            break
         }
         'L' { # Make this character a Uppercase Alpha
            $password += $UpperAlpha | rand
            break
         } 
         'l' { # Make this character a Lowercase Alpha
            $password += $LowerAlpha | rand
            break
         }
         'C' { # Make this character a Uppercase consonant
            $password += $UpperConsonants | rand
            break
         }
         'c' { # Make this character a Lowercase consonant
            $password += $LowerConsonants | rand
            break
         }
         'V' { # Make this character a Uppercase vowel
            $password += $UpperVowels | rand
            break
         }
         'v' { # Make this character a Lowercase vowel
            $password += $LowerVowels | rand
            break
         }
         '.' { # Make this character punctuation
            $password += $Punctuation | rand
            break
         }
         '#' { # Make this character numeric
            $password += $Numeric | rand
            break
         }
         'a' { # Make this character any alphabetic
            $password += $UpperAlpha + $LowerAlpha  | rand
            break
         }          
         'A' { # Make this character any alphanumeric
            $password += $UpperAlpha + $LowerAlpha + $Numeric | rand
            break
         } 
         '*' { # Make this character any character
            $password += $UpperAlpha + $LowerAlpha + $Numeric + $Punctuation | rand
            break
         }
         # For a number, decrement the number, and then go back one...
         { [bool](([string]$_) -as [int]) } { 
            if($randoms -notcontains $c) {
               $randoms += $c
               [int]$count = $(0..([int][string]$_) | rand)
            } else { 
               [int]$count = $(([int][string]$_) - 1)
            }
            if($c -gt 0 -and $count -gt 0) { 
               $Template = $Template.Remove($c,1).Insert($c,$count)
               $c -= 2 
               Write-Verbose "ALTER Template: $Template  Active: $($Template[$c]) ($c), Generating $count ($_)  Password: $password"
            }
            break
         }
         '\' {
            $password += $Template[($c++)]
            break
         }
         default {
            $password += $Template[$c]
            break
         }
      }
   }
   return $Password
}
#}
