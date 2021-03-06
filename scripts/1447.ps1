param ($fileName, $computerName=$env:ComputerName)

#######################
function ConvertTo-MIFXml
{
    param ($mifFile)

    $mifText = gc $mifFile | 
    #Remove illegal XML characters
    % { $_ -replace "&", "&amp;" } |
    % { $_ -replace"'", "&apos;" } |
    % { $_ -replace "<", "&lt;" } |
    % { $_ -replace ">", "&gt;" } |
    #Create Component attribute
    % { $_ -replace 'Start Component','<Component' } | 
    #Create Group attribute
    % { $_ -replace 'Start Group','><Group' } | 
    #Create Attribute attribute
    % { $_ -replace 'Start Attribute','><Attribute' } |
    #Create closing tags
    % { $_ -replace 'End Attribute','></Attribute>' } |
    % { $_ -replace 'End Group','</Group>' } |
    % { $_ -replace 'End Component','</Component>'} |
    #Remove all quotes
    % { $_ -replace '"' } | 
    #Remove MIF comments. MIF Comments start with //
    % { $_ -replace "(\s*//\s*.*)" } |
    #Extract name/value and quote value
    % { $_ -replace "\s*([^\s]+)\s*=\s*(.+$)",'$1="$2"' } |
    #Replace tabs with spaces
    % { $_ -replace "\t", " " } |
    #Replace 2 spaces with 1
    % { $_ -replace "\s{2,}", " " }

    #Join the array, cleanup some spacing and extra > signs
    [xml]$mifXml = [string]::Join(" ", $mifText) -replace ">\s*>",">" -replace "\s+>",">"

    return $mifXml

} #ConvertTo-MIFXml

#######################
ConvertTo-MIFXml $fileName | foreach {$_.component} | foreach {$_.Group} | foreach {$_.Attribute} | select @{n='SystemName';e={$computerName}}, `
@{n='Component';e={$($_.psbase.ParentNode).psbase.ParentNode.name}}, @{n='Group';e={$_.psbase.ParentNode.name}}, `
@{n='FileName';e={[System.IO.Path]::GetFileName($FileName)}}, ID, Name, Value
