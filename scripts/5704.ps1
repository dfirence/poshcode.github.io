# Define Filename  
# By accessing the from the Script directly  
# you can create multiple files internally with the # same function by swapping the name 
$Filename='.\test.rtf' 
 
# This function accepts data passed to it and 
# Adds it directly to the Filesystem 
Function Write-RTFDoc 
{ 
Param($content)  
 
$OutputFile=$Script:Filename 
 
Add-Content -Value $content -Path $Outputfile -Force 
} 
 
# This function will allow formatting of the content 
# When provided with a numeric parameter to define 
# the format of the output 
Function Write-RTFLine 
{ 
param ($Style,$Content) 
 
    switch ($Style) 
    { 
        # Header required for beginning of RTF file 
        '0' { $output="{\rtf1\ansi\ansicpg1252\deff0\nouicompat\deflang1033{\fonttbl{\f0\fnil\fcharset0 Calibri;}{\f1\fnil\fcharset2 Symbol;}}`r`n{\*\generator Riched20 6.3.9600}\viewkind4\uc1 "} 
        # Regular Line - Default font 
        '1' { $output=$Content+"\par"} 
        # Bulleted Line 
        '2' { $output="\pard{\pntext\f1\'B7\tab}{\*\pn\pnlvlblt\pnf1\pnindent0{\pntxtb\'B7}}\fi-360\li720\sl276\slmult1\f0\fs22\lang9 "+$Content+"\par" } 
        # Bulleted Line - Last Line 
        '3' { $output="{\pntext\f1\'B7\tab}"+$content+"\par`r`n\pard\sl276\slmult1\par"} 
        # Blank Line - Single blank Paragraph 
        '4' { $output = "\par" } 
        # Final Line required to close RTF output 
        '99' { $output="}" }         
        # Define Font and Formatting 
        '999' { $output="\pard\sl276\slmult1\f0\fs22\lang9 "} 
    # Centered Heading 
    '9999' { $output="\pard\sl276\slmult1\qc\ul\b\f0\fs40 "+$Content+"\par`r`n\pard\sl276\slmult1\fs22\ulnone\b0\par" } 
     }                     
    Write-RTFDoc $output 
 
} 
# This function will operate like Write-RTFLine 
# But will accept up to Four (4) values to create 
# columnized output 
 
Function Write-RTFColumn 
{ 
param($Style,$value1,$value2,$value3,$value4) 
         
     switch($Style) 
    {    
        # Regular Line - 3 column output 
        '0' { $output="\trowd\trgaph108\trleft5\trbrdrl\brdrs\brdrw10 \trbrdrt\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trpaddl108\trpaddr108\trpaddfl3\trpaddfr3 
\clbrdrl\brdrw10\brdrs\clbrdrt\brdrw10\brdrs\clbrdrr\brdrw10\brdrs\clbrdrb\brdrw10\brdrs \cellx3121\clbrdrl\brdrw10\brdrs\clbrdrt\brdrw10\brdrs\clbrdrr\brdrw10\brdrs\clbrdrb\brdrw10\brdrs \cellx6238\clbrdrl\brdrw10\brdrs\clbrdrt\brdrw10\brdrs\clbrdrr\brdrw10\brdrs\clbrdrb\brdrw10\brdrs \cellx9355  
\pard\intbl\widctlpar\f1\fs22 "+$value1+"\cell "+$value2+"\cell "+$value3+"\cell\row  
\pard\sa200\sl276\slmult1\f2\lang9" } 
        # Regular line - 4 column output 
        '1' { $output="\trowd\trgaph108\trleft5\trbrdrl\brdrs\brdrw10 \trbrdrt\brdrs\brdrw10 \trbrdrr\brdrs\brdrw10 \trbrdrb\brdrs\brdrw10 \trpaddl108\trpaddr108\trpaddfl3\trpaddfr3 
\clbrdrl\brdrw10\brdrs\clbrdrt\brdrw10\brdrs\clbrdrr\brdrw10\brdrs\clbrdrb\brdrw10\brdrs \cellx2342\clbrdrl\brdrw10\brdrs\clbrdrt\brdrw10\brdrs\clbrdrr\brdrw10\brdrs\clbrdrb\brdrw10\brdrs \cellx4679\clbrdrl\brdrw10\brdrs\clbrdrt\brdrw10\brdrs\clbrdrr\brdrw10\brdrs\clbrdrb\brdrw10\brdrs \cellx7017\clbrdrl\brdrw10\brdrs\clbrdrt\brdrw10\brdrs\clbrdrr\brdrw10\brdrs\clbrdrb\brdrw10\brdrs \cellx9355  
\pard\intbl\widctlpar\f1\fs22 "+$value1+"\cell "+$value2+"\cell "+$value3+"\cell "+$value4+"\cell\row  
\pard\sa200\sl276\slmult1\f2\lang9" } 
    } 
    Write-RTFDoc $output 
 
} 
 
Write-RTFLine -Style 0 ; # Drop Header to RTF document 
Write-RTFLine -Style 999 ; # Define Font and Style 
#Write-RTFLine -Style 9999 -Content 'This is a Title' 
#Write-RTFLine -Style 1 -Content 'Regular Line' ; # Write line of output 
#Write-RTFLine -Style 1 -Content 'Regular Line' ; # Write another line of output 
#Write-RTFLine -Style 2 -Content 'Bullet 1' ; # Start a bulleted section with some text 
#Write-RTFLine -Style 2 -Content 'Bullet 2' ; # More Bulleted text 
#Write-RTFLine -Style 3 -Content 'Bullet 3' ; # STOP - Last line of Bulleted text 
Write-RTFColumn -Style 0 -Value1 1 -value2 2 -value3 3 ; # Let's write 3 columns of info 
Write-RTFColumn -Style 0 -Value1 1 -value2 2 -value3 3 ; # Let's write 3 columns of info 
Write-RTFColumn -Style 0 -Value1 1 -value2 2 -value3 3 ; # Let's write 3 columns of info 
Write-RTFLine -Style 99 ; # Close off the RTF Document 
 

