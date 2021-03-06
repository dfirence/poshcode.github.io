## PowerBot 2.0
## A simple framework to get you started writing your own IRC bots in PowerShell
####################################################################################################
## Requires Meebey.SmartIrc4net.dll to be in your ...\WindowsPowerShell\Libraries\
## You can get Meebey.SmartIrc4net.dll from 
## http://voxel.dl.sourceforge.net/sourceforge/smartirc4net/SmartIrc4net-0.4.0.bin.tar.bz2
####################################################################################################
## Add-Type -path $ProfileDir\Libraries\Meebey.SmartIrc4net.dll
$null = [Reflection.Assembly]::LoadFrom("$ProfileDir\Libraries\Meebey.SmartIrc4net.dll")

function Start-PowerBot {
PARAM(
  $server = "irc.freenode.net"
, [string[]]$channels = @("#PowerShell")
, [string[]]$nick     = @(Read-Host 'You must provide a nickname')
, [string]$password
, $realname = "PowerShell Bot"
, $port               = 6667
)
   
   if(!$global:irc) { 
      $global:irc = New-Object Meebey.SmartIrc4net.IrcClient
      $irc.ActiveChannelSyncing = $true # $irc will track channels for us
      # $irc.Encoding = [Text.Encoding]::UTF8
      $irc.Add_OnError( {Write-Error $_.ErrorMessage} )
      $irc.Add_OnQueryMessage( {PrivateMessage} )
      $irc.Add_OnChannelMessage( {ChannelMessage} )
   }
   
   $irc.Connect($server, $port)
   $irc.Login($nick, $realname, 0, $nick, $password)
   ## $channels | % { $irc.RfcJoin( $_ ) }
   foreach($channel in $channels) { $irc.RfcJoin( $channel ) }
   Resume-PowerBot # Shortcut so starting this thing up only takes one command
}

## Note that PowerBot stops listening if you press a key ...
## You'll have to re-run Resume-Powerbot to get him to listen again
function Resume-PowerBot {
   while(!$Host.UI.RawUI.KeyAvailable) { $irc.ListenOnce($false) }
}

function Stop-PowerBot {
   $irc.RfcQuit("If people listened to themselves more often, they would talk less.")
   $irc.Disconnect()
}

####################################################################################################
## Event Handlers
####################################################################################################
## Event handlers in powershell have TWO automatic variables: $This and $_
##   In the case of SmartIrc4Net:
##   $This  - usually the connection, and such ...
##   $_     - the IrcEventArgs, which just has the Data member:
##

function PrivateMessage { 
   $Data = $_.Data
   # Write-Verbose $Data.From   
   # Write-Verbose $Data.Message
   Write-Verbose $($Data | Out-String)
   
   $command, $params = $Data.MessageArray
   if($PowerBotCommands.ContainsKey($command)) {
      &$PowerBotCommands[$command] $params $Data | 
         Out-String -width (510 - $Data.From.Length - $nick.Length - 3) | 
            % { $_.Trim().Split("`n") | %{ $irc.SendMessage("Message", $Data.Channel, $_.Trim() ) }}
   }
}

function ChannelMessage {
   $Data = $_.Data
   # Write-Verbose $Data.From
   # Write-Verbose $Data.Channel
   # Write-Verbose $Data.Message
   Write-Verbose $($Data | Out-String)
   
   $command, $params = $Data.MessageArray
   if($PowerBotCommands.ContainsKey($command)) {
      &$PowerBotCommands[$command] $params $Data | 
         Out-String -width (510 - $Data.Channel.Length - $nick.Length - 3) | 
            % { $_.Trim().Split("`n") | %{ $irc.SendMessage("Message", $Data.Channel, $_.Trim() ) }}
   }
}

####################################################################################################
## The PowerBotCommands hashtable is extremely simple ...
##
## You register a "command" which must be the FIRST WORD of a message (either private, or channel)
##   and you provide a scriptblock to process said message.  
## The handler scriptblock gets two parameters, for convenience:
##   $Params is the rest of the message text after the command word (which is probably all you need)
##   $Data is the Data propert of the IrcEventArgs, which has everything in it that you could want
## 
## You may do whatever you want in the scriptblock (this runs on your PC, after all), but the 
##   simplest thing is to respond by returning "something" which will be sent to wherever the message
##   came from.  
##
## NOTE 1: Evrything you return is output to Out-String and then the channel or user.  Be careful!
## NOTE 2: 510 is the Max IRC Message Length, including the channel name etc.
##         http`://www.faqs.org/rfcs/rfc1459.html
##
$PowerBotCommands=@{}

## A sample command to get you started
$PowerBotCommands."Hello" = {Param($Query,$Data)
   "Hello, $($Data.Nick)!"
}

$PowerBotCommands."!Echo" = {Param($Query,$Data)
   "$Query"
}

## "!gh|!get-help|!man" 
$PowerBotCommands."!Get-Help" = {Param($Query)
   $help = get-help $Query | Select Name,Synopsis,Syntax
   if($?) {
      if($help -is [array]) {
         "You're going to need to be more specific, I know all about $((($help | % { $_.Name })[0..($help.Length-2)] -join ', ') + ' and even ' + $help[-1].Name)"
      } else {
         @($help.Synopsis,($help.Syntax | Out-String -width 1000).Trim().Split("`n",4,"RemoveEmptyEntries")[0..3])
      }
   } else {
      "I couldn't find the help file for '$Query', sorry.  I probably don't have that snapin loaded."
   }
}


