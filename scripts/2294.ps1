function ConvertFrom-CliXml {
    param(
        [parameter(position=0,mandatory=$true,valuefrompipeline=$true)]
        [validatenotnull()]
        [string]$string
    )
    begin
    {
        $inputstring = ""
    }
    process
    {
        $inputstring += $string
    }
    end
    {
        $type = [type]::gettype("System.Management.Automation.Deserializer")
        $ctor = $type.getconstructor("instance,nonpublic", $null, @([xml.xmlreader]), $null)
        $sr = new-object io.stringreader $inputstring
        $xr = new-object xml.xmltextreader $sr
        $deserializer = $ctor.invoke($xr)
        $method = @($type.getmethods("nonpublic,instance") | where-object {$_.name -like "Deserialize"})[1]
        $done = $type.getmethod("Done", [reflection.bindingflags]"nonpublic,instance")
        while (!$done.invoke($deserializer, @()))
        {
            try {
                $method.invoke($deserializer, "")
            } catch {
                write-warning "Could not deserialize $string: $_"
            }
        }
    }
}

