#requires -version 2.0
## An update using New-WebServiceProxy to the MSDN ContentService instead of HttpRest
## See: http: //services.msdn.microsoft.com/ContentServices/ContentService.asmx

## YOU MUST SAVE THIS FILE AS Get-OnlineHelp.ps1 in your path, and call it as Get-OnlineHelp
## __OR__ dot-source it -- DO NOT run it twice!

## This is a VERY EARLY prototype of a function that could retrieve cmdlet help from TechNet ...
## and hypothetically, other online help sites which used the same format (none)

## TODO:
## Properly format <pre> in the console
## Properly format the tables at the end of parameters

## Version History
## 0.9 - 2010-07-27 - Added the rest of the parameters, fixed output, support -FULL, etc. THIS VERSION
## 0.3 - 2010-03-25 - Fixed a buggy type check which failed on first run.
## 0.2 - 2010-03-24 - Switched to using the ContentService Web Service.  PoshCode.org/1723
## 0.1 - 2010-03-23 - Initial release depended on HttpRest.  PoshCode.org/1719

[CmdletBinding(DefaultParameterSetName="Default")]
param(
   [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=0)]
   [System.String]
   ${Name},

   [System.String]
   ${Path},

   [System.String[]]
   ${Category},

   [System.String[]]
   ${Component},

   [System.String[]]
   ${Functionality},

   [System.String[]]
   ${Role},

   [Parameter(Mandatory=$true,ParameterSetName='Detailed')]
   [Switch]
   ${Detailed},

   [Parameter(Mandatory=$true,ParameterSetName='Full')]
   [Switch]
   ${Full},

   [Parameter(Mandatory=$true,ParameterSetName='Examples')]
   [Switch]
   ${Examples},

   [Parameter(Mandatory=$true,ParameterSetName='Parameters')]
   [System.String]
   ${Parameter},

   [Switch]
   ${Online}
)


# http://poshcode.org/1718
function Select-Expand {
<# 
.Synopsis
   Like Select-Object -Expand, but with recursive iteration of a select chain
.Description
   Takes a dot-separated series of properties to expand, and recursively iterates the output of each property ...
.Parameter Property
   A collection of property names to expand.
   
   Each property can be a dot-separated series of properties, and each one is expanded, iterated, and then evaluated against the next
.Parameter InputObject
   The input to be selected from
.Parameter Unique
   If set, this becomes a pipeline hold-up, and the total output is checked to ensure uniqueness
.Parameter EmptyToo
   If set, Select-Expand will include empty/null values in it's output
.Example
   Get-Help Get-Command | Select-Expand relatedLinks.navigationLink.uri -Unique

   This will return the online-help link for Get-Command.  It's the equivalent of running the following command:

   C:\PS> Get-Help Get-Command | Select-Object -Expand relatedLinks | Select-Object -Expand navigationLink | Select-Object -Expand uri | Where-Object {$_} | Select-Object -Unique
#>
param(
   [Parameter(ValueFromPipeline=$false,Position=0)]
   [string[]]$Property
,
   [Parameter(ValueFromPipeline=$true)]
   [Alias("IO")]
   [PSObject[]]$InputObject
,
   [Switch]$Unique
,
   [Switch]$EmptyToo
)
begin { 
   if($unique) {
      $output = @()
   }
}
process {
   foreach($io in $InputObject) {
      foreach($prop in $Property -split "\.") {
         if($io -ne $null) {
            $io = $io | Select-Object -Expand $prop
            Write-Verbose $($io | out-string)
         }
      }
      if(!$EmptyToo -and ($io -ne $null)) {
         $io = $io | Where-Object {$_}
      }
      if($unique) {
         $output += @($io)
      } 
      else {
         Write-Output $io
      }
   }
}
end {
   if($unique) {
      Write-Output $output | Select-Object -Unique
   }
}
}
# New-Alias slep Select-Expand

# http://poshcode.org/1722
function Get-HttpResponseUri {
#.Synopsis
#   Fetch the HEAD for a url and return the ResponseUri.
#.Description
#   Does a HEAD request for a URL, and returns the ResponseUri. This is useful for resolving (in a service-independent way) shortened urls.
#.Parameter ShortUrl
#   A (possibly) shortened URL to be resolved to its redirect location.
[CmdletBinding()]
param(
   [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$true)]
   [Alias("Uri","Url")]
   [string]$ShortUrl
)
process {
   $req = [System.Net.HttpWebRequest]::Create($ShortUrl)
   $req.Method = "HEAD"
   $response = $req.GetResponse()
   Write-Output $response.ResponseUri
   $response.Close() # clean up like a good boy
}
}
# New-Alias Resolve-ShortUri Select-Expand

if( -not("Mtps.ContentService" -as [type] -and $global:MtpsWebServiceProxy -as "Mtps.ContentService")) {
$global:MtpsWebServiceProxy = New-WebServiceProxy "http://services.msdn.microsoft.com/ContentServices/ContentService.asmx?wsdl" -Namespace Mtps
}

function global:Get-OnlineHelp {
[CmdletBinding(DefaultParameterSetName="Default")]
param(
   [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true, Position=0)]
   [System.String]
   ${Name},

   [System.String]
   ${Path},

   [System.String[]]
   ${Category},

   [System.String[]]
   ${Component},

   [System.String[]]
   ${Functionality},

   [System.String[]]
   ${Role},

   [Parameter(Mandatory=$true,ParameterSetName='Detailed')]
   [Switch]
   ${Detailed},

   [Parameter(Mandatory=$true,ParameterSetName='Full')]
   [Switch]
   ${Full},

   [Parameter(Mandatory=$true,ParameterSetName='Examples')]
   [Switch]
   ${Examples},

   [Parameter(Mandatory=$true,ParameterSetName='Parameters')]
   [System.String]
   ${Parameter},

   [Switch]
   ${Online}
)
begin {
   $HelpValues = $(
      switch($PsCmdlet.ParameterSetName) {
         "Default"   {"name", "synopsis", "syntax", "description", "related links", "remarks"}
         "Full"      {"name", "synopsis", "syntax", "description", "parameters", "inputs and outputs", "examples", "notes", "see also"}
         "Detailed"  {"name", "synopsis", "syntax", "description", "parameters", "examples", "remarks"}
         "Examples"  {"name", "synopsis", "examples"}
         "Parameter" {"name", "synopsis", "parameters"}
      }
   )
}
process { 
### Get the Help ID
   $uri = Get-Help @PSBoundParameters | Select-Expand relatedLinks.navigationLink.uri -Unique | Get-HttpResponseUri
   if(!$uri) { throw "Couldn't find online help URL for $Name" }   
   $id = [IO.Path]::GetFileNameWithoutExtension( $uri.segments[-1] )
   write-verbose "Content Id: $id"

### Get the Help Content
   $content = $MtpsWebServiceProxy.GetContent( (New-Object 'Mtps.getContentRequest' -Property @{locale = $PSUICulture; contentIdentifier = $id; requestedDocuments = (New-Object Mtps.requestedDocument -Property @{Selector="Mtps.Failsafe"}) }) )
   $global:OnlineHelpContent = $content.primaryDocuments |?{$_.primaryFormat -eq "Mtps.Failsafe"} | Select -Expand Any

### NAME
   $NameNode = $global:OnlineHelpContent.SelectSingleNode("//*[local-name()='div' and @class='topic']/*[local-name()='div' and @class='title']")
   $NameNode.SetAttribute("header","NAME")

### Ditch the navigation and stuff
   $global:OnlineHelpContent = $global:OnlineHelpContent.SelectSingleNode("//*[local-name()='div' and @id='mainBody']")
   
### SYNOPSIS
   $Synopsis = $global:OnlineHelpContent.SelectSingleNode("*[local-name()='p']")
   $Synopsis.SetAttribute("header","SYNOPSIS")

   $global:help = @{Name=$NameNode; Synopsis=$Synopsis}

### EVERYTHING ELSE   
   $headers = $OnlineHelpContent.h2  | ForEach-Object { $_.get_InnerText().Trim() }
   $content = $OnlineHelpContent.div | ForEach-Object { $_ }

   if($headers.Count -ne $content.Count) { 
      Write-Warning "Unmatched content"
      foreach($header in $headers) {
        $help.$header = $OnlineHelpContent.SelectNodes( "//*[preceding-sibling::*[1][local-name()='h2' and normalize-space()='$header']]" )| 
                                    ForEach { $_.SetAttribute("header",$header.ToUpper()); $_ }
      }
   }
   else {
      for($h=0;$h -lt $headers.Count; $h++){
         $help.($headers[$h]) = $content[$h]
         $help.($headers[$h]).SetAttribute("header",$headers[$h].ToUpper())
      }
   }
   
### PARAMETERS
   #  $Global:Parameters = $global:OnlineHelpContent.RemoveChild( $global:OnlineHelpContent.SelectSingleNode("//*[local-name()='div' and @id='sectionSection2']") )
   #  $Parameters.SetAttribute("header","PARAMETERS")
   #  ## Create the parameters
   #  $help.Parameters = $Parameters
   $parameternames = $help.Parameters.h3  | ForEach-Object { $_.get_InnerText().Trim() }
   foreach($header in $parameternames) {
      foreach($node in $help.Parameters.SelectNodes( "//*[preceding-sibling::*[1][local-name()='h3' and normalize-space()='$header']]" ) ) {
         $node.SetAttribute("header",$header)
      }
   }   

### EXAMPLES
   $help.Examples = $Help.Notes.Clone()
   $help.Examples.SetAttribute("header","EXAMPLES")
   $help.Examples.set_InnerXml('')
   ForEach($key in $help.Keys -match "Example \d+" | sort { [int]($_ -replace "Example ") }) {
      $help[$key].Header = $help[$key].Header -creplace "EXAMPLE","Example"
      $null = $help.Examples.AppendChild( $help[$key] )
      $null = $help.Remove($key)
   }

   foreach($section in $help[$HelpValues]) {
      if($section -isnot [PSObject]) { $section = New-Object PSObject $section }
      if($Section.div -and @($Section.div)[0].header) {
         $header = New-Object PSObject -Property @{header=$section.Header}
         $header.PSTypeNames.Insert(0,"PoshCode.HtmlCommandHelpInfo+Section")
         $header
         
         foreach($subsection in $Section.div) {
            $null = $subsection.PSTypeNames.Insert(0,"PoshCode.HtmlCommandHelpInfo+Section")
            $subsection
         }
      } else {
         $null = $section.PSTypeNames.Insert(0,"PoshCode.HtmlCommandHelpInfo+Section")
         $section
      }
   }
   
}
}

Get-OnlineHelp @PSBoundParameters

# Since you can't update format data without a file that has a ps1xml ending, let's make one up...
$tempFile = "$([IO.Path]::GetTempFileName()).ps1xml"
Set-Content $tempFile @'
<?xml version="1.0" encoding="utf-8" ?>
<Configuration>
    <ViewDefinitions>
        <View>
            <Name>HtmlCommandHelpSection</Name>
            <ViewSelectedBy>
                <TypeName>PoshCode.HtmlCommandHelpInfo+Section</TypeName>
            </ViewSelectedBy>
            <CustomControl>
               <CustomEntries>
                   <CustomEntry>
                       <CustomItem>
                           <Frame>
                               <LeftIndent>4</LeftIndent>
                               <CustomItem>
                                   <ExpressionBinding>
                                       <ScriptBlock>
                                          Write-Host $_.Header.Trim() -Fore Cyan -NoNewLine
                                          return " "
                                       </ScriptBlock>
                                   </ExpressionBinding>
                                   <NewLine/>
                                   <ExpressionBinding>
                                       <ScriptBlock>$_.get_InnerText().trim() -replace '^[\n\s]*\n|\n\s+$'</ScriptBlock>
                                   </ExpressionBinding>
                                   <NewLine/>
                               </CustomItem> 
                           </Frame>
                       </CustomItem>
                   </CustomEntry>
               </CustomEntries>
            </CustomControl>
        </View>
        <!--View>
            <Name>HtmlCommandHelpHeader</Name>
            <ViewSelectedBy>
                <TypeName>PoshCode.HtmlCommandHelpInfo+Header</TypeName>
            </ViewSelectedBy>
            <CustomControl>
               <CustomEntries>
                   <CustomEntry>
                       <CustomItem>
                           <ExpressionBinding>
                              <ScriptBlock>Write-Host $_ -Fore Cyan; ""</ScriptBlock>
                           </ExpressionBinding>
                       </CustomItem>
                   </CustomEntry>
               </CustomEntries>
            </CustomControl>
        </View-->
    </ViewDefinitions>
</Configuration>
'@
Update-FormatData -Append $tempFile
