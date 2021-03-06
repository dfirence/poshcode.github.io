## Get-Credential 
## An improvement over the default cmdlet which has no options ...
###################################################################################################
## History
## v 2.1 Fix the comment help and parameter names to agree with each other (whoops)
## v 2.0 Rewrite for v2 to replace the default Get-Credential
## v 1.2 Refactor ShellIds key out to a variable, and wrap lines a bit
## v 1.1 Add -Console switch and set registry values accordingly (ouch)
## v 1.0 Add Title, Message, Domain, and UserName options to the Get-Credential cmdlet
###################################################################################################
function Get-Credential { 
## .Synopsis
##    Gets a credential object based on a user name and password.
## .Description
##    The Get-Credential function creates a credential object for a specified username and password, with an optional domain. You can use the credential object in security operations.
## 
##    The function accepts more parameters to customize the security prompt than the default Get-Credential cmdlet (including forcing the call through the console if you're in the native PowerShell.exe CMD console), but otherwise functions identically.
##
## .Parameter UserName
##    A default user name for the credential prompt, or a pre-existing credential (would skip all prompting)
## .Parameter Title
##    Allows you to override the default window title of the credential dialog/prompt
##
##    You should use this to allow users to differentiate one credential prompt from another.  In particular, if you're prompting for, say, Twitter credentials, you should put "Twitter" in the title somewhere. If you're prompting for domain credentials. Being specific not only helps users differentiate and know what credentials to provide, but also allows tools like KeePass to automatically determine it.
## .Parameter Message
##    Allows you to override the text displayed inside the credential dialog/prompt.
##    
##    You can use this for things like presenting an explanation of what you need the credentials for.
## .Parameter Domain
##    Specifies the default domain to use if the user doesn't provide one (by default, this is null)
## .Parameter GenericCredentials
##    The Get-Credential cmdlet forces you to always return DOMAIN credentials (so even if the user provides just a plain user name, it prepends "\" to the user name). This switch allows you to override that behavior and allow generic credentials without any domain name or the leading "\".
## .Parameter Inline
##    Forces the credential prompt to occur inline in the console/host using Read-Host -AsSecureString (not implemented properly in PowerShell ISE)
##
[CmdletBinding(DefaultParameterSetName="Better")]
PARAM(
   [Parameter(Position=1,Mandatory=$false)]
   [Alias("Credential")]
   [PSObject]$UserName=$null,
   [Parameter(Position=2,Mandatory=$false)]
   [string]$Title=$null,
   [Parameter(Position=3,Mandatory=$false)]
   [string]$Message=$null,
   [Parameter(Position=4,Mandatory=$false)]
   [string]$Domain=$null,
   [Parameter(Mandatory=$false)]
   [switch]$GenericCredentials,
   [Parameter(Mandatory=$false)]
   [switch]$Inline
)
PROCESS {
   if( $UserName -is [System.Management.Automation.PSCredential]) {
      return $UserName
   } elseif($UserName -ne $null) {
      $UserName = $UserName.ToString()
   }
   
   if($Inline) {
      if($Title)    { Write-Host $Title }
      if($Message)  { Write-Host $Message }
      if($Domain) { 
         if($UserName -and $UserName -notmatch "[@\\]") { 
            $UserName = "${Domain}\${UserName}"
         }
      }
      if(!$UserName) {
         $UserName = Read-Host "User"
         if(($Domain -OR !$GenericCredentials) -and $UserName -notmatch "[@\\]") {
            $UserName = "${Domain}\${UserName}"
         }
      }
      return New-Object System.Management.Automation.PSCredential $UserName,$(Read-Host "Password for user $UserName" -AsSecureString)
   }
   if($GenericCredentials) { $Credential = "Generic" } else { $Credential = "Domain" }
   
   ## Now call the Host.UI method ... if they don't have one, we'll die, yay.
   ## BugBug? PowerShell.exe disregards the last parameter
   $Host.UI.PromptForCredential($Title, $Message, $UserName, $Domain, $Credential,"Default")
}
}
