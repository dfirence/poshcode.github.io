

function RomanNumeral($Num,$Pos) {

[array]$RomanFormat="9","0","00","000","01","1","10","100","1000","02"
[array]$RomanColumns="I","V","X","X","L","C"


$Format=$RomanFormat[$num]
$NumberOfCharacters=$Format.Length
If ( $Format -ne "9" )
    {
    For ($Counter=0;$Counter -lt ($numberOfCharacters);$counter++) {
        [int]$ColumnPosition=[convert]::toint16($Format[$Counter],10)
        Write-Host $RomanColumns[$Columnposition+(3*$Pos)] -nonewline
        }
    }
}


function convertToRoman ($Number) {

$NumberString=$number.tostring()
$NumberOfDigits=$NumberString.Length

For ($NumberPosition=0;$numberPosition -lt $NumberString.length;$NumberPosition++) {
    
	$NumbertoSend=[convert]::toint16(($NumberString[$NumberPosition]),10)
	$position=($NumberOfDigits-1)-$NumberPosition
    RomanNumeral $NumberToSend  $position
    }
}

do 
{
$current=get-date
$thehour=$current.hour
$theminute=$current.minute
$theseconds=$current.second

IF ($thehour -eq 0 ) { $thehour=12 }
IF ($thehour -gt 12) { $thehour=$thehour-12 }

$Location=$HOST.UI.RAWUI.CursorPosition

converttoroman $thehour
write-host ":" -nonewline
converttoroman $theminute
write-host ":" -nonewline
converttoroman $theseconds
write-host "        "
start-sleep -seconds 1
$HOST.UI.RAWUI.CursorPosition=$Location
} until ($FALSE)
