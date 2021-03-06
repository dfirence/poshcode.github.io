# -==-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
#        Author: Kris Cieslak (defaultset.blogspot.com)
#          Date: 2010-05-26
#   Description: Identifying knowledge base article by id number taken from 
#                string or filename.
#
#    Parameters: filename / knowledge base number
#               
#  Requirements: Internet connection
#
# Usage example:
#                ./get-kbinfo.ps1 KB926139 
#            or  
#                ./get-kbinfo.ps1 WindowsXP-KB926139-x86-ENU.exe
#            or 
#                ls Windows* | % { ./get-kbinfo.ps1 $_.Name }
#
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=--=-=-=-=--=-=-=-=-=-=-=-=-=-=
 PARAM ($filename = $(throw "Specifiy the file name"))

 $page = New-Object System.Net.WebClient;  
 $kb = [regex]::match($filename,'KB\d*|kb\d*').ToString();
 $p = $page.DownloadString('http://support.microsoft.com/kb/'+$kb)
 $p = [regex]::replace( [regex]::match($p,'<h1 class="title">.*</h1>').ToString(), '<h1 class="title">|</h1>', '' )
 write-host -Fore Yellow `n'[*] Filename: '$filename  
 write-host `n'    '$p `n'    ( http://support.microsoft.com/kb/'$kb' )'`n

