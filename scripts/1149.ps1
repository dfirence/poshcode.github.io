#requires -version 2

function Set-WLWAutoLink{

    param(         
        [Parameter(
            Position=0,Mandatory=$true,ValueFromPipelineByPropertyName=$true
        )] [String]$Name,
        
        [Parameter(
            Position=1,Mandatory=$true,ValueFromPipelineByPropertyName=$true
        )] [String]$URL,
            
        [Parameter()][switch]$OpenInNewWindow        
    )  

    begin
    {
        $Glossary = "$env:APPDATA\Windows Live Writer\LinkGlossary\linkglossary.xml"
        
        if(!(test-path $Glossary))
        {
            throw "linkglossary.xml cannot be found"
        }
        else
        {
            $xml = [xml](Get-Content $Glossary)
            $nodeNames = "text","url","title","rel","openInNewWindow"
        }
    }

    process
    {    
        
        try{
            $node = $xml.glossary.entry | where {$_.text -eq $name}
    
            if($node)
            {
                Write-Verbose "Updating '$name' node." 
                $node.url = [string]$_.url
            }
            else
            {            
                Write-Verbose "Creating '$name' node." 
                $entry = $xml.CreateElement("entry")            
                $nodeNames | foreach { $null = $entry.AppendChild($xml.CreateElement($_))} 
                
                $el = $xml.documentElement.AppendChild($entry)
                $el.text=$Name
                $el.url=$URL
                $el.openInNewWindow = "$openInNewWindow"    
            }
        }
        catch
        {
            Write-Error $_
            Continue
        }
     }


    end
    {
        try
        {
            $xml.save($Glossary)    
        }
        catch
        {
            throw
        }
    }

}
