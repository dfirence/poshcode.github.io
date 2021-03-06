
function ConvertFrom-CliXml {
    param(
        [Parameter(Position=0, Mandatory=$true, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [String[]]$InputObject
    )
    begin
    {
		$OFS = "`n"
        [String]$xmlString = ""
    }
    process
    {
        $xmlString += $InputObject
    }
    end
    {
        $type = [type]::gettype("System.Management.Automation.Deserializer")
        $ctor = $type.getconstructor("instance,nonpublic", $null, @([xml.xmlreader]), $null)
        $sr = new-object System.IO.StringReader $xmlString
        $xr = new-object System.Xml.XmlTextReader $sr
        $deserializer = $ctor.invoke($xr)
        $method = @($type.getmethods("nonpublic,instance") | where-object {$_.name -like "Deserialize"})[1]
        $done = $type.getmethod("Done", [System.Reflection.BindingFlags]"nonpublic,instance")
        while (!$done.invoke($deserializer, @()))
        {
            try {
                $method.invoke($deserializer, "")
            } catch {
                write-warning "Could not deserialize $string: $_"
            }
        }
		$xr.Close()
		$sr.Dispose()
    }
}

