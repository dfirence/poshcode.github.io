#requires -version 2.0
# Version History:
# v 0.5 - First Public version
# v 1.0 - Made ConvertFrom-Json work with arbitrary JSON 
#       - switched to xsl style sheets for ConvertTo-JSON
# v 1.1 - Changed ConvertFrom-Json to handle single item results
# v 1.2 - CodeSigned to make a fellow geek happy
# v 1.3 - Changed ConvertFrom-Json to handle zero item results (I hope)
# v 1.4 - Added -File parmeter set to ConvertFrom-Json
#       - Cleaned up some error messages
# v 1.5 - Corrected handling of arrays
# v 1.6 - Corrected pipeline binding on ConvertFrom-Json
#
#  There is no help (yet) because I keep forgetting that I haven't written help yet.
#  Full RoundTrip capability:
#
#  > ls | ConvertTo-Json | ConvertFrom-Json
#  > ps | ConvertTo-Json | Convert-JsonToXml | Convert-XmlToJson | convertFrom-Json
#
#  You may frequently want to use the DEPTH or NoTypeInformation parameters:
#
#  > ConvertTo-Json -Depth 2 -NoTypeInformation
#
#  But then you have to specify the type when you reimport (and you can't do that for deep objects).  
#  This problem also occurs if you convert the result of a SELECT statement (ie: PSCustomObject).
#  For Example:
#
#  > PS | Select PM, WS, CPU, ID, ProcessName |
#  >> ConvertTo-json -NoType |
#  >> convertfrom-json -Type System.Diagnostics.Process
#
#  However, you *can* use PSOjbect as your type when re-importing:
#
#  > $Json = Get-Process | 
#  >> Select PM, WS, CPU, ID, ProcessName, @{n="SnapshotTime";e={Get-Date}} | 
#  >> ConvertTo-Json -NoType 
#  
#  > $Json | ConvertFrom-json -Type PSObject


Add-Type -AssemblyName System.ServiceModel.Web, System.Runtime.Serialization
$utf8 = [System.Text.Encoding]::UTF8

function Write-String {
PARAM(
   [Parameter()]$stream,
   [Parameter(ValueFromPipeline=$true)]$string
)
PROCESS {
  $bytes = $utf8.GetBytes($string)
  $stream.Write( $bytes, 0, $bytes.Length )
}  
}

function Convert-JsonToXml {
PARAM([Parameter(ValueFromPipeline=$true)][string[]]$json)
BEGIN { 
   $mStream = New-Object System.IO.MemoryStream 
}
PROCESS {
   $json | Write-String -stream $mStream
}
END {
   $mStream.Position = 0
   try
   {
      $jsonReader = [System.Runtime.Serialization.Json.JsonReaderWriterFactory]::CreateJsonReader($mStream,[System.Xml.XmlDictionaryReaderQuotas]::Max)
      $xml = New-Object Xml.XmlDocument
      $xml.Load($jsonReader)
      $xml
   }
   finally
   {
      $jsonReader.Close()
      $mStream.Dispose()
   }
}
}
 
function Convert-XmlToJson {
PARAM([Parameter(ValueFromPipeline=$true)][Xml]$xml)
PROCESS {
   $mStream = New-Object System.IO.MemoryStream
   $jsonWriter = [System.Runtime.Serialization.Json.JsonReaderWriterFactory]::CreateJsonWriter($mStream)
   try
   {
     $xml.Save($jsonWriter)
     $bytes = $mStream.ToArray()
     [System.Text.Encoding]::UTF8.GetString($bytes,0,$bytes.Length)
   }
   finally
   {
     $jsonWriter.Close()
     $mStream.Dispose()
   }
}
}

## Rather than rewriting ConvertTo-Xml ...
Function ConvertTo-Json {
[CmdletBinding()]
Param(
   [Parameter(Mandatory=$true,Position=1,ValueFromPipeline=$true)]$InputObject
,
   [Parameter(Mandatory=$false)][Int]$Depth=1
,
   [Switch]$NoTypeInformation
)
END { 
   ## You must output ALL the input at once 
   ## ConvertTo-Xml outputs differently if you just have one, so your results would be different
   $input | ConvertTo-Xml -Depth:$Depth -NoTypeInformation:$NoTypeInformation -As Document | Convert-CliXmlToJson
}
}

Function Convert-CliXmlToJson {
PARAM(
   [Parameter(ValueFromPipeline=$true)][Xml.XmlNode]$xml
)
BEGIN {
   $xmlToJsonXsl = @'
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<!--
  CliXmlToJson.xsl

  Copyright (c) 2006,2008 Doeke Zanstra
  Copyright (c) 2009 Joel Bennett
  All rights reserved.

  Redistribution and use in source and binary forms, with or without modification, 
  are permitted provided that the following conditions are met:

  Redistributions of source code must retain the above copyright notice, this 
  list of conditions and the following disclaimer. Redistributions in binary 
  form must reproduce the above copyright notice, this list of conditions and the 
  following disclaimer in the documentation and/or other materials provided with 
  the distribution.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR 
  OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF 
  THE POSSIBILITY OF SUCH DAMAGE.
-->

  <xsl:output indent="no" omit-xml-declaration="yes" method="text" encoding="UTF-8" media-type="text/x-json"/>
	<xsl:strip-space elements="*"/>
  <!--contant-->
  <xsl:variable name="d">0123456789</xsl:variable>

  <!-- ignore document text -->
  <xsl:template match="text()[preceding-sibling::node() or following-sibling::node()]"/>

  <!-- string -->
  <xsl:template match="text()">
    <xsl:call-template name="escape-string">
      <xsl:with-param name="s" select="."/>
    </xsl:call-template>
  </xsl:template>
  
  <!-- Main template for escaping strings; used by above template and for object-properties 
       Responsibilities: placed quotes around string, and chain up to next filter, escape-bs-string -->
  <xsl:template name="escape-string">
    <xsl:param name="s"/>
    <xsl:text>"</xsl:text>
    <xsl:call-template name="escape-bs-string">
      <xsl:with-param name="s" select="$s"/>
    </xsl:call-template>
    <xsl:text>"</xsl:text>
  </xsl:template>
  
  <!-- Escape the backslash (\) before everything else. -->
  <xsl:template name="escape-bs-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <xsl:when test="contains($s,'\')">
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="concat(substring-before($s,'\'),'\\')"/>
        </xsl:call-template>
        <xsl:call-template name="escape-bs-string">
          <xsl:with-param name="s" select="substring-after($s,'\')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="$s"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Escape the double quote ("). -->
  <xsl:template name="escape-quot-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <xsl:when test="contains($s,'&quot;')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,'&quot;'),'\&quot;')"/>
        </xsl:call-template>
        <xsl:call-template name="escape-quot-string">
          <xsl:with-param name="s" select="substring-after($s,'&quot;')"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="$s"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
  
  <!-- Replace tab, line feed and/or carriage return by its matching escape code. Can't escape backslash
       or double quote here, because they don't replace characters (&#x0; becomes \t), but they prefix 
       characters (\ becomes \\). Besides, backslash should be seperate anyway, because it should be 
       processed first. This function can't do that. -->
  <xsl:template name="encode-string">
    <xsl:param name="s"/>
    <xsl:choose>
      <!-- tab -->
      <xsl:when test="contains($s,'&#x9;')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,'&#x9;'),'\t',substring-after($s,'&#x9;'))"/>
        </xsl:call-template>
      </xsl:when>
      <!-- line feed -->
      <xsl:when test="contains($s,'&#xA;')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,'&#xA;'),'\n',substring-after($s,'&#xA;'))"/>
        </xsl:call-template>
      </xsl:when>
      <!-- carriage return -->
      <xsl:when test="contains($s,'&#xD;')">
        <xsl:call-template name="encode-string">
          <xsl:with-param name="s" select="concat(substring-before($s,'&#xD;'),'\r',substring-after($s,'&#xD;'))"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise><xsl:value-of select="$s"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- number (no support for javascript mantise) -->
  <xsl:template match="text()[not(string(number())='NaN' or
                       (starts-with(.,'0' ) and . != '0'))]">
    <xsl:value-of select="."/>
  </xsl:template>

  <!-- boolean, case-insensitive -->
  <xsl:template match="text()[translate(.,'TRUE','true')='true']">true</xsl:template>
  <xsl:template match="text()[translate(.,'FALSE','false')='false']">false</xsl:template>

  <!-- root object(s) -->
  <xsl:template match="*" name="base">
    <xsl:if test="not(preceding-sibling::*)">
      <xsl:choose>
        <xsl:when test="count(../*)>1"><xsl:text>[</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>{</xsl:text></xsl:otherwise>
      </xsl:choose>
    </xsl:if>
    <xsl:call-template name="escape-string">
      <xsl:with-param name="s" select="name()"/>
    </xsl:call-template>
    <xsl:text>:</xsl:text>
    <!-- check type of node -->
    <xsl:choose>
      <!-- null nodes -->
      <xsl:when test="count(child::node())=0">null</xsl:when>
      <!-- other nodes -->
      <xsl:otherwise>
      	<xsl:apply-templates select="child::node()"/>
      </xsl:otherwise>
    </xsl:choose>
    <!-- end of type check -->
    <xsl:if test="following-sibling::*">,</xsl:if>
    <xsl:if test="not(following-sibling::*)">
      <xsl:choose>
        <xsl:when test="count(../*)>1"><xsl:text>]</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>}</xsl:text></xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <!-- properties of objects -->
  <xsl:template match="*[count(../*[name(../*)=name(.)])=count(../*) and count(../*)&gt;1]">
    <xsl:variable name="inArray" select="translate(local-name(),'OBJECT','object')='object' or ../@Type[starts-with(.,'System.Collections') or contains(.,'[]') or (contains(.,'[') and contains(.,']'))]"/>
    <xsl:if test="not(preceding-sibling::*)">
       <xsl:choose>
         <xsl:when test="$inArray"><xsl:text>[</xsl:text></xsl:when>
         <xsl:otherwise>
            <xsl:text>{</xsl:text>
            <xsl:if test="../@Type">
               <xsl:text>"__type":</xsl:text>      
               <xsl:call-template name="escape-string">
                 <xsl:with-param name="s" select="../@Type"/>
               </xsl:call-template>
               <xsl:text>,</xsl:text>      
             </xsl:if>
         </xsl:otherwise>
       </xsl:choose>
    </xsl:if>
    <xsl:choose>
      <xsl:when test="not(child::node())">
        <xsl:call-template name="escape-string">
          <xsl:with-param name="s" select="@Name"/>
        </xsl:call-template>
        <xsl:text>:null</xsl:text>
      </xsl:when>
      <xsl:when test="$inArray">
        <xsl:apply-templates select="child::node()"/>
      </xsl:when>
      <!--
      <xsl:when test="not(@Name) and not(@Type)">
        <xsl:call-template name="escape-string">
          <xsl:with-param name="s" select="local-name()"/>
        </xsl:call-template>
        <xsl:text>:</xsl:text>      
        <xsl:apply-templates select="child::node()"/>
      </xsl:when>
      -->
      <xsl:when test="not(@Name)">
        <xsl:call-template name="escape-string">
          <xsl:with-param name="s" select="local-name()"/>
        </xsl:call-template>
        <xsl:text>:</xsl:text>      
        <xsl:apply-templates select="child::node()"/>
      </xsl:when> 
      <xsl:otherwise>
        <xsl:call-template name="escape-string">
          <xsl:with-param name="s" select="@Name"/>
        </xsl:call-template>
        <xsl:text>:</xsl:text>
        <xsl:apply-templates select="child::node()"/>
      </xsl:otherwise>
    </xsl:choose>
    <xsl:if test="following-sibling::*">,</xsl:if>
    <xsl:if test="not(following-sibling::*)">       
      <xsl:choose>
        <xsl:when test="$inArray"><xsl:text>]</xsl:text></xsl:when>
        <xsl:otherwise><xsl:text>}</xsl:text></xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>
  
  
  <!-- convert root element to an anonymous container -->
  <xsl:template match="/">
    <xsl:apply-templates select="node()"/>
  </xsl:template>    
</xsl:stylesheet>
'@
}
PROCESS {
   if(Get-Member -InputObject $xml -Name root) {
      Write-Verbose "Ripping to Objects"
      $xml = $xml.root.Objects
   } else {
      Write-Verbose "Was already Objects"
   }
   Convert-Xml -Xml $xml -Xsl $xmlToJsonXsl
}
}

Function ConvertFrom-Xml {
   [CmdletBinding(DefaultParameterSetName="AutoType")]
   PARAM(
      [Parameter(ValueFromPipeline=$true,Mandatory=$true,Position=1)]
      [Xml.XmlNode]
      $xml
      ,
      [Parameter(Mandatory=$true,ParameterSetName="ManualType")]
      [Type]$Type
      ,
      [Switch]$ForceType
   )
   PROCESS{ 
      if(Get-Member -InputObject $xml -Name root) {
         return $xml.root.Objects | ConvertFrom-Xml
      } elseif(Get-Member -InputObject $xml -Name Objects) {
         return $xml.Objects | ConvertFrom-Xml
      }
      $propbag = @{}
      foreach($name in Get-Member -InputObject $xml -MemberType Properties | Where-Object{$_.Name -notmatch "^__|type"} | Select-Object -ExpandProperty name) {
         Write-Verbose "$Name Type: $($xml.$Name.type)"
         $propbag."$Name" = Convert-Properties $xml."$name"
      }
      if(!$Type -and $xml.HasAttribute("__type")) { $Type = $xml.__Type }
      if($ForceType -and $Type) {
         try {
            $output = New-Object $Type -Property $propbag
         } catch {
            $output = New-Object PSObject -Property $propbag
            $output.PsTypeNames.Insert(0, $xml.__type)
         }
      } else {
         $output = New-Object PSObject -Property $propbag
         if($Type) {
            $output.PsTypeNames.Insert(0, $Type)
         }
      }
      Write-Output $output
   }
}

Function Convert-Properties {
param($InputObject)
   switch( $InputObject.type ) {
      "object" {
         return (ConvertFrom-Xml -Xml $InputObject)
         break
      } 
      "string" {
         $MightBeADate = $InputObject.get_InnerText() -as [DateTime]
         ## Strings that are actually dates (*grumble* JSON is crap)               
         if($MightBeADate -and $propbag."$Name" -eq $MightBeADate.ToString("G")) {
            return $MightBeADate
         } else {
            return $InputObject.get_InnerText()
         }
         break
      }
      "number" {
         $number = $InputObject.get_InnerText()
         if($number -eq ($number -as [int])) {
            return $number -as [int]
         } elseif($number -eq ($number -as [double])) {
            return $number -as [double]
         } else {
            return $number -as [decimal]
         }
         break
      }
      "boolean" {
         return [bool]::parse($InputObject.get_InnerText())
      }
      "null" {
         return $null
      }
      "array" {
         [object[]]$Items = $( foreach( $item in $InputObject.GetEnumerator() ) {
            Convert-Properties $item
         } )
         return $Items
      }
      default {
         return $InputObject
         break
      }
   }

}



Function ConvertFrom-Json {
   [CmdletBinding(DefaultParameterSetName="StringInput")]
PARAM(
   [Parameter(Mandatory=$true,Position=1,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,ParameterSetName="File")]
   [Alias("PSPath")]
   [string]$File
,
   [Parameter(ValueFromPipeline=$true,Mandatory=$true,Position=1,ParameterSetName="StringInput")]
   [string]$InputObject
,
   [Parameter(Mandatory=$true)]
   [Type]$Type
   ,
   [Switch]$ForceType
)
BEGIN {
   [bool]$AsParameter = $PSBoundParameters.ContainsKey("File") -or $PSBoundParameters.ContainsKey("InputObject") 
}
PROCESS {
   if($PSCmdlet.ParameterSetName -eq "File") {
      [string]$InputObject = @(Get-Content $File) -Join "`n"
      $null = $PSBoundParameters.Remove("File")
   }
   else 
   {
      $null = $PSBoundParameters.Remove("InputObject")
   }
   [Xml.XmlElement]$xml = (Convert-JsonToXml $InputObject).Root
   if($xml) {
      if($xml.Objects) {
         $xml.Objects.Item.GetEnumerator() | ConvertFrom-Xml @PSBoundParameters
      }elseif($xml.Item -and $xml.Item -isnot [System.Management.Automation.PSParameterizedProperty]) {
         $xml.Item | ConvertFrom-Xml @PSBoundParameters
      }else {
         $xml | ConvertFrom-Xml @PSBoundParameters
      }
   } else {
      Write-Error "Failed to parse JSON with JsonReader"
   }
}
}

#########
### The JSON library is dependent on Convert-Xml from my Xml script module

function Convert-Node {
param(
[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
[System.Xml.XmlReader]$XmlReader,
[Parameter(Position=1,Mandatory=$true,ValueFromPipeline=$false)]
[System.Xml.Xsl.XslCompiledTransform]$StyleSheet
) 
PROCESS {
   $output = New-Object IO.StringWriter
   $StyleSheet.Transform( $XmlReader, $null, $output )
   Write-Output $output.ToString()
}
}
   
function Convert-Xml {
#.Synopsis
#  The Convert-XML function lets you use Xslt to transform XML strings and documents.
#.Description
#.Parameter Content
#  Specifies a string that contains the XML to search. You can also pipe strings to Select-XML.
#.Parameter Namespace
#   Specifies a hash table of the namespaces used in the XML. Use the format @{<namespaceName> = <namespaceUri>}.
#.Parameter Path
#   Specifies the path and file names of the XML files to search.  Wildcards are permitted.
#.Parameter Xml
#  Specifies one or more XML nodes to search.
#.Parameter Xsl
#  Specifies an Xml StyleSheet to transform with...
[CmdletBinding(DefaultParameterSetName="Xml")]
PARAM(
   [Parameter(Position=1,ParameterSetName="Path",Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
   [ValidateNotNullOrEmpty()]
   [Alias("PSPath")]
   [String[]]$Path
,
   [Parameter(Position=1,ParameterSetName="Xml",Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
   [ValidateNotNullOrEmpty()]
   [Alias("Node")]
   [System.Xml.XmlNode[]]$Xml
,
   [Parameter(ParameterSetName="Content",Mandatory=$true,ValueFromPipeline=$true)]
   [ValidateNotNullOrEmpty()]
   [String[]]$Content
,
   [Parameter(Position=0,Mandatory=$true,ValueFromPipeline=$false)]
   [ValidateNotNullOrEmpty()]
   [Alias("StyleSheet")]
   [String[]]$Xslt
)
BEGIN { 
   $StyleSheet = New-Object System.Xml.Xsl.XslCompiledTransform
   if(Test-Path @($Xslt)[0] -ErrorAction 0) { 
      Write-Verbose "Loading Stylesheet from $(Resolve-Path @($Xslt)[0])"
      $StyleSheet.Load( (Resolve-Path @($Xslt)[0]) )
   } else {
      Write-Verbose "$Xslt"
      $StyleSheet.Load(([System.Xml.XmlReader]::Create((New-Object System.IO.StringReader ($Xslt -join "`n")))))
   }
   [Text.StringBuilder]$XmlContent = [String]::Empty 
}
PROCESS {
   switch($PSCmdlet.ParameterSetName) {
      "Content" {
         $null = $XmlContent.AppendLine( $Content -Join "`n" )
      }
      "Path" {
         foreach($file in Get-ChildItem $Path) {
            Convert-Node -Xml ([System.Xml.XmlReader]::Create((Resolve-Path $file))) $StyleSheet
         }
      }
      "Xml" {
         foreach($node in $Xml) {
            Convert-Node -Xml (New-Object Xml.XmlNodeReader $node) $StyleSheet
         }
      }
   }
}
END {
   if($PSCmdlet.ParameterSetName -eq "Content") {
      [Xml]$Xml = $XmlContent.ToString()
      Convert-Node -Xml $Xml $StyleSheet
   }
}
}


New-Alias fromjson ConvertFrom-Json
New-Alias tojson ConvertTo-Json

#New-Alias ipjs Import-Json
#New-Alias epjs Export-Json
#Import-Json, Export-Json, 

Export-ModuleMember -Function ConvertFrom-Json, ConvertTo-Json, Convert-JsonToXml, Convert-XmlToJson, Convert-CliXmlToJson -Alias *

# SIG # Begin signature block
# MIIIDQYJKoZIhvcNAQcCoIIH/jCCB/oCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUVOSNLwCk5kgVZvSmrZS8eSHh
# enegggUrMIIFJzCCBA+gAwIBAgIQKQm90jYWUDdv7EgFkuELajANBgkqhkiG9w0B
# AQUFADCBlTELMAkGA1UEBhMCVVMxCzAJBgNVBAgTAlVUMRcwFQYDVQQHEw5TYWx0
# IExha2UgQ2l0eTEeMBwGA1UEChMVVGhlIFVTRVJUUlVTVCBOZXR3b3JrMSEwHwYD
# VQQLExhodHRwOi8vd3d3LnVzZXJ0cnVzdC5jb20xHTAbBgNVBAMTFFVUTi1VU0VS
# Rmlyc3QtT2JqZWN0MB4XDTEwMDUxNDAwMDAwMFoXDTExMDUxNDIzNTk1OVowgZUx
# CzAJBgNVBAYTAlVTMQ4wDAYDVQQRDAUwNjg1MDEUMBIGA1UECAwLQ29ubmVjdGlj
# dXQxEDAOBgNVBAcMB05vcndhbGsxFjAUBgNVBAkMDTQ1IEdsb3ZlciBBdmUxGjAY
# BgNVBAoMEVhlcm94IENvcnBvcmF0aW9uMRowGAYDVQQDDBFYZXJveCBDb3Jwb3Jh
# dGlvbjCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAMfUdxwiuWDb8zId
# KuMg/jw0HndEcIsP5Mebw56t3+Rb5g4QGMBoa8a/N8EKbj3BnBQDJiY5Z2DGjf1P
# n27g2shrDaNT1MygjYfLDntYzNKMJk4EjbBOlR5QBXPM0ODJDROg53yHcvVaXSMl
# 498SBhXVSzPmgprBJ8FDL00o1IIAAhYUN3vNCKPBXsPETsKtnezfzBg7lOjzmljC
# mEOoBGT1g2NrYTq3XqNo8UbbDR8KYq5G101Vl0jZEnLGdQFyh8EWpeEeksv7V+YD
# /i/iXMSG8HiHY7vl+x8mtBCf0MYxd8u1IWif0kGgkaJeTCVwh1isMrjiUnpWX2NX
# +3PeTmsCAwEAAaOCAW8wggFrMB8GA1UdIwQYMBaAFNrtZHQUnBQ8q92Zqb1bKE2L
# PMnYMB0GA1UdDgQWBBTK0OAaUIi5wvnE8JonXlTXKWENvTAOBgNVHQ8BAf8EBAMC
# B4AwDAYDVR0TAQH/BAIwADATBgNVHSUEDDAKBggrBgEFBQcDAzARBglghkgBhvhC
# AQEEBAMCBBAwRgYDVR0gBD8wPTA7BgwrBgEEAbIxAQIBAwIwKzApBggrBgEFBQcC
# ARYdaHR0cHM6Ly9zZWN1cmUuY29tb2RvLm5ldC9DUFMwQgYDVR0fBDswOTA3oDWg
# M4YxaHR0cDovL2NybC51c2VydHJ1c3QuY29tL1VUTi1VU0VSRmlyc3QtT2JqZWN0
# LmNybDA0BggrBgEFBQcBAQQoMCYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmNv
# bW9kb2NhLmNvbTAhBgNVHREEGjAYgRZKb2VsLkJlbm5ldHRAWGVyb3guY29tMA0G
# CSqGSIb3DQEBBQUAA4IBAQAEss8yuj+rZvx2UFAgkz/DueB8gwqUTzFbw2prxqee
# zdCEbnrsGQMNdPMJ6v9g36MRdvAOXqAYnf1RdjNp5L4NlUvEZkcvQUTF90Gh7OA4
# rC4+BjH8BA++qTfg8fgNx0T+MnQuWrMcoLR5ttJaWOGpcppcptdWwMNJ0X6R2WY7
# bBPwa/CdV0CIGRRjtASbGQEadlWoc1wOfR+d3rENDg5FPTAIdeRVIeA6a1ZYDCYb
# 32UxoNGArb70TCpV/mTWeJhZmrPFoJvT+Lx8ttp1bH2/nq6BDAIvu0VGgKGxN4bA
# T3WE6MuMS2fTc1F8PCGO3DAeA9Onks3Ufuy16RhHqeNcMYICTDCCAkgCAQEwgaow
# gZUxCzAJBgNVBAYTAlVTMQswCQYDVQQIEwJVVDEXMBUGA1UEBxMOU2FsdCBMYWtl
# IENpdHkxHjAcBgNVBAoTFVRoZSBVU0VSVFJVU1QgTmV0d29yazEhMB8GA1UECxMY
# aHR0cDovL3d3dy51c2VydHJ1c3QuY29tMR0wGwYDVQQDExRVVE4tVVNFUkZpcnN0
# LU9iamVjdAIQKQm90jYWUDdv7EgFkuELajAJBgUrDgMCGgUAoHgwGAYKKwYBBAGC
# NwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgor
# BgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUEW0DtdE/
# JxK83G70qiWwclaBOkswDQYJKoZIhvcNAQEBBQAEggEAj4Uojbc96AZ7aKOLgkfP
# E+qkrMWAuGijIacClwgOcUGOzdkNDQAdbvvLJTWafE7uBDFdEuxL7MZDvPDLFPJ0
# U95AjfVwhf7FTEMHL3UOGJS5Lo/JAsnIz6Fza4faLv4kilXyRRME1iBqH/vxllNj
# mGV8Rm0Yg8EZ4ClYLonHuGFT2+XqOA1wbjncZbUfqg/8ybD+TVh/19BJoqSRNoL9
# /TKQTgBoOVSB3pJmvoFfKjxPrS/1fPiVOGi0HfP4JhzAYRy9PDHCmxat0IE+ev9w
# LAjR2YUQ0xJRYIa1rQfJaohi45wMyIoeur3Z3zHL9sk+MbkQvyMO2Qsmi5fU309e
# 1g==
# SIG # End signature block
