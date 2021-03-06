<# 
.SYNOPSIS 
    The script saves a username and password, encrypted with a custom key to to a file.
.DESCRIPTION 
    The script saves a username and password, encrypted with a custom key to to a file. The key is coded into the script but should be changed before use. The key allows the password to be decrypted by any user who has the key, on any machine. if the key parameter is omitted from ConvertFrom-SecureString, only the user who generated the file on the computer that generated the file	can decrypt the password.
	see http://bsonposh.com/archives/254 for more info.
	To retrieve the password:
	$key = [byte]57,86,59,11,72,75,18,52,73,46,0,21,56,76,47,12
	$VCCred = Import-Csv 'C:\PATH\FILE.TXT'
	$VCCred.Password = ($VCCred.Password| ConvertTo-SecureString -Key $key)
	$VCCred = (New-Object -typename System.Management.Automation.PSCredential -ArgumentList $VCCred.Username,$VCCred.Password)
.NOTES 
    File Name  : SaveCredentials.ps1
    Author     : Samuel Mulhearn
    Version History: 
	Version 1.0  
		28 Jun 2012.
		Release
.LINK 
    http://poshcode.org/3491
.EXAMPLE 
    Call the script with .\Save-Credentials.ps1 no arguments or parameters are required
#> 

$key = [byte]57,86,59,11,72,75,18,52,73,46,0,21,56,76,47,12
Write-Host "Key length is:" $key.length "The key length is acceptable if 16 or 32"
$ScriptPath =  Split-Path -parent $MyInvocation.MyCommand.Definition
$Outfile = "$ScriptPath\Credentials.txt"
Write-Host "This script will a username and encrpyted password into $outfile"
$null | Out-File -FilePath $Outfile
$credential = Get-Credential
$obj = New-Object -typename System.Object
$obj | Add-Member -MemberType noteProperty -name Username -value $credential.UserName
$obj | Add-Member -MemberType noteProperty -name Password -value ($credential.Password | ConvertFrom-SecureString -key $key)
$obj | Export-Csv -Path $OutFile
write-host "Username and password have been saved to $outfile"
