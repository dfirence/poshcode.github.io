## Get-HtmlHelp - by Joel Bennett
## version 3.0
#####################################################################
## Cool Example, using ShowUI:
##    Import-Module HtmlHelp
##    Import-Module ShowUI
##    function Show-Help { [CmdletBinding()]param([String]$Name)  
##       Window { WebBrowser -Name wb } -On_Loaded { 
##          $wb.NavigateToString((Get-HtmlHelp $Name))
##          $this.Title = "Get-Help $Name"
##       } -Show
##    }
##    Show-Help Get-Help
## 
#####################################################################
#Import System.Web in order to use HtmlEncode functionality
Add-Type -Assembly System.Web

function ConvertTo-Dictionary([hashtable]$ht) {
   $kvd = new-object "System.Collections.Generic.Dictionary``2[[System.String],[System.String]]"
   foreach($kv in $ht.GetEnumerator()) { $kvd.Add($kv.Key,$kv.Value) }
   return $kvd
}


function htmlEncode {
   param([Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Mandatory=$true)][String]$Text)
   process{ [System.Web.HttpUtility]::HtmlEncode($Text) }
}

function trim {
   param([Parameter(ValueFromPipeline=$true,Mandatory=$true)][String]$string)
   process{ $string.Trim() }
}

function trimEncode{
   param([Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Mandatory=$true)][String]$Text)
   process{ [System.Web.HttpUtility]::HtmlEncode($Text).Trim() }
}

function HHSplit {
   param(
      $Separator="\s*\r?\n",
      [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
      [String]$inputObject
   )
   process{ 
      foreach($item in [regex]::Split($inputObject,$Separator)) {
         $item.Trim() | Where {$_.Length} 
      }
   }
}

function HHjoin {
   param(
      [Parameter(Position=0)]
      $Separator=$ofs,
      
      [Parameter(ValueFromPipeline=$true,Mandatory=$true)]
      [String[]]
      $inputObject
   )
   begin   { [string[]]$array = $inputObject }
   process { $array += $inputObject }
   end     { 
      Write-Verbose $Array.Length
      if($array.Length -gt 1) { 
         [string]::Join($Separator,$array)
      } else { 
         $array
      }
   }
}
function Out-HtmlTag {
   param([Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Mandatory=$true)][String]$Text, $Tag="p")
   process{
      $html = $Text | out-string -width ([int]::MaxValue) | HHSplit | trimEncode | HHjoin "</$tag>`n<$tag>"
      $html = $html -replace '(\S+)(http://.*?)([\s\p{P}](?:\s|$))','<a href="$2">$1</a>$3'
      "<$tag>$html</$tag>"
   }
}
function Out-HtmlList {
   param([Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Mandatory=$true)][String]$Text)
   process{
      "<li>$($Text | out-string -width ([int]::MaxValue) | HHSplit | trimEncode | HHjoin "</li>`n<li>")</li>"
   }
}
function Out-HtmlDefList {
   param(
      [Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Mandatory=$true)]$Node,
      [String[]]$Term,
      [String[]]$Definition
   )
   # begin { "<dl>"}
   process{
      $tx = $Node
      foreach($t in $Term) { $tx = $tx.$t; Write-Verbose "${t}: $tx" }
      $dx = $Node
      foreach($d in $Definition) { $dx = $dx.$d; Write-Verbose "${t}: $dx"  }
      "<dt>{0}</dt><dd>{1}</dd>" -f ($tx | trimEncode),($dx | trimEncode)
   }
   # end { "</dl>"}
}
function Out-HtmlBr {
   param([Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,Mandatory=$true)][String]$Text)
   process{
      $Text | out-string -width ([int]::MaxValue) | HHSplit | trimEncode | HHjoin "<br />"
   }
}

## Utility Functions 
function Get-UtcTime {
   Param($Format="")
   [DateTime]::Now.ToUniversalTime().ToString($Format)
}
function Encode-Twice {
   param([Parameter(ValueFromPipeline=$true,Mandatory=$true)][String]$string)
   process {
      [System.Web.HttpUtility]::UrlEncode( [System.Web.HttpUtility]::UrlEncode( $string ) )
   }
}


## Get-HtmlHelp - A Helper function for generating help:
## Usage:  Get-HtmlHelp Get-*
function Get-HtmlHelp {
   param([string[]]$commands, [string]$baseUrl = "http://http://technet.microsoft.com/en-us/library/")
   $commands | Get-Command -EA "SilentlyContinue" | Get-Help -Full | Convert-HelpToHtml $baseUrl
}

function textile {
param([string]$text)

$text -replace '(?<=\r\n\r\n|^)\*\s(.*)(?=\r\n)',"<ul>`r`n<li>`$1</li>"                     <# start of a list      #>`
      -replace '(?<=\r\n)\*\s+((?:.|\r\n(?![\*\r]))+)(?=\r\n\r\n|\r\n\*|$)',"<li>`$1</li>"  <# middle of a list     #>`
      -replace '</li>(?=\r\n\r\n|$)',"</li>`r`n</ul>"                                       <# end of the list      #>`
      -replace '(?<=\r\n\r\n|^)([^\n]*)(?=\r\n\r\n|$)',"<p>`r`n`$1`r`n</p>"                 <# regular paragraphs   #>`
      -replace '(?<=\r\n\r\n)([^\r\n]*\s+[^\r\n]*)\r\n(-+)(?=\r\n\r\n)',"<h3>`$1</h3>"      <# headers              #>`
      -replace '(?<=[^\r\n>])(\r\n)(?=[^\r\n]+)',"<br />`$1"                                <# remaining linebreaks #>`
      -replace "  "," &nbsp;"  # Because the content is originally for get-help, preserve whitespace
}

function Convert-ParameterHelp {
param([Parameter(ValueFromPipeline=$true,Mandatory=$true)]$ParameterItem) 
process {
   $name = $( 
      if($ParameterItem.position -ne "named") {
         "[-<strong>{0}</strong>]" -f $ParameterItem.name
      } else { 
         "-<strong>{0}</strong>" -f $ParameterItem.name
      }
   )

   if($ParameterItem.required -eq "false") {
      "<nobr>[{0} {1}]</nobr>" -f $name, $ParameterItem.parameterValue
   } else {
      "<nobr>{0} {1}</nobr>" -f $name, $ParameterItem.parameterValue
   }
}
}

function Convert-SyntaxItem {
param([Parameter(ValueFromPipeline=$true,Mandatory=$true)]$SyntaxItem) 
process {
   "<li>{0} {1}</li>" -f $SyntaxItem.name, $($SyntaxItem.parameter | Convert-ParameterHelp | join " ")
}
}

function Convert-HelpToHtml {
param(
[string]$baseUrl,

[Parameter(ValueFromPipeline=$true)]
$Help
)
PROCESS {
      #  throw "Can only process -Full view help output"

      # Name isn't needed, since this is going as the body, but ...
      # $data = "<html><head><title>$(trimEncode($help.Name))</title></head><body>";
      # $data += "<h1>$(trimEncode($help.Name))</h1>"
$data = @"
<html>
<head>
<title>$(trimEncode($help.Name))</title>
<style type="text/css">
   h1, h2, h3, h4, h5, h6 { color: #369 }
   ul.syntax {
      list-style: none outside;
      font-size: .9em;
      font-family: Consolas, "DejaVu Sans Mono", "Lucida Console", monospace;
   }
   ul.syntax li {
      margin: 3px 0px;
   }
   table.parameters th {
      text-align: left;
   }
</style>
</head>
<body>
<h1>$(trimEncode($help.Name))</h1>
"@
      # Synopsis
      $data += "<h2>Synopsis</h2>$($help.Synopsis | Out-HtmlTag -Tag p)"
      
      # Syntax
      $data += "<h2 class='syntax'>Syntax</h2><ul class='syntax'>$($help.Syntax.syntaxItem | Convert-SyntaxItem)</ul>"
   
      # Related Commands
      $data += "<h2>Related Commands</h2>"
      foreach ($relatedLink in $help.relatedLinks.navigationLink) {
         if($relatedLink.linkText -and !$relatedLink.linkText.StartsWith("about")) {
            $uri = ""
            if( $relatedLink.uri -ne "" ) {
               $uri = $relatedLink.uri
            } else {
               $uri = "$baseUrl/$((get-command $relatedLink.linkText -EA "SilentlyContinue").PSSnapin.Name)/$($relatedLink.linkText)"
            }
            $data += "<a href='$(trimEncode($uri))'>$(trimEncode($relatedLink.linkText))</a><br>"
         }
      }
   
      # Detailed Description
      $data += "<h2>Detailed Description</h2>$($help.Description | Out-HtmlTag -Tag p)"
   
      # Parameters
      $data += "<h2>Parameters</h2>"
      foreach($param in $help.parameters.parameter) {
         $data += "<h4>-$(trimEncode($param.Name)) [&lt;$(trimEncode($param.type.name))&gt;]</h4>"
         $data += $param.Description | Out-HtmlTag -Tag p
         $data += "<table class='parameters'>"
         $data += "<tr><th>Required? &nbsp;</th><td> $(trimEncode($param.Required))</td></tr>"
         $data += "<tr><th>Position? &nbsp;</th><td> $(trimEncode($param.Position))</td></tr>"
         if($param.DefaultValue) {
            $data += "<tr><th>Default value? &nbsp;</th><td> $(trimEncode($param.defaultValue))</td></tr>"
         }
         $data += "<tr><th>Accept pipeline input? &nbsp;</th><td> $(trimEncode($param.pipelineInput))</td></tr>"
         $data += "<tr><th>Accept wildcard characters? &nbsp;</th><td> $(trimEncode($param.globbing))</td></tr></table>"
      }
   
      if($help.inputTypes) {
         # Input Type
         $data += "<h3>Input Type</h3><dl class='input'>$(
            $help.inputTypes.inputType | Out-HtmlDefList -Term type, name -Definition description
         )</dl>"
      }
      if($help.returnValues) {
         # Return Type
         $data += "<h3>Output Type</h3><dl class='output'>$(
            $help.returnValues.returnValue | Out-HtmlDefList -Term type, name -Definition description
         )</dl>"
      }
      # Notes
      $data += "<h2>Notes</h2>$($help.alertSet.alert | Out-HtmlTag -Tag p)"
   
      # Examples
      if($help.Examples.example -and $help.Examples.example.Length) {
         $data += "<h2>Examples</h2>"
         
         foreach($example in $help.Examples.example){
            if($example.title) {
               $data += "<h4>$(trimEncode($example.title.trim(' -')))</h4>"
            }
            $data += "<code><strong>C:\PS&gt;</strong>&nbsp;$(($example.code | Out-HtmlBr) -replace "<br />C:\\PS&gt;","<br /><strong>C:\PS&gt;</strong>&nbsp;")</code>"
            $data += "<p>$($example.remarks | out-string -width ([int]::MaxValue) | Out-HtmlTag -Tag p)</p>"
         }
      }
      $data += "</body></html>"

      write-output $data
}}

# Export-ModuleMember Get-HtmlHelp

