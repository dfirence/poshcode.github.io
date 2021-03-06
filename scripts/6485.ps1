$e = ([char]27) + "["
$global:ANSI = @{
   ESC = ([char]27) + "["
   Clear = "${e}0m"
   fg = @{
      Clear       = "${e}39m"

      Black       = "${e}30m";  DarkGray    = "${e}90m"
      DarkRed     = "${e}31m";  Red         = "${e}91m"
      DarkGreen   = "${e}32m";  Green       = "${e}92m"
      DarkYellow  = "${e}33m";  Yellow      = "${e}93m"
      DarkBlue    = "${e}34m";  Blue        = "${e}94m"
      DarkMagenta = "${e}35m";  Magenta     = "${e}95m"
      DarkCyan    = "${e}36m";  Cyan        = "${e}96m"
      Gray        = "${e}37m";  White       = "${e}97m"
   }
   bg = @{
      Clear       = "${e}49m"
      Black       = "${e}40m"; DarkGray    = "${e}100m"
      DarkRed     = "${e}41m"; Red         = "${e}101m"
      DarkGreen   = "${e}42m"; Green       = "${e}102m"
      DarkYellow  = "${e}43m"; Yellow      = "${e}103m"
      DarkBlue    = "${e}44m"; Blue        = "${e}104m"
      DarkMagenta = "${e}45m"; Magenta     = "${e}105m"
      DarkCyan    = "${e}46m"; Cyan        = "${e}106m"
      Gray        = "${e}47m"; White       = "${e}107m"
   }
}

$global:ANSI.fg.Default = $global:ANSI.fg."$($Host.UI.RawUI.ForegroundColor)"
$global:ANSI.fg.Background = $global:ANSI.fg."$($Host.UI.RawUI.BackgroundColor)"
$global:ANSI.bg.Default = $global:ANSI.bg."$($Host.UI.RawUI.BackgroundColor)"


function global:prompt {
   # FIRST, make a note if there was an error in the previous command
   $err = !$?

   # PowerLine font characters
   $RIGHT  = [char]0xe0b0 # Solid, right facing triangle
   $GT     = [char]0xe0b1 # right facing triangle
   $LEFT   = [char]0xe0b2 # Solid, right facing triangle
   $LT     = [char]0xe0b3 # right facing triangle
   $BRANCH = [char]0xe0a0 # Branch symbol
   $LOCK   = [char]0xe0a2 # Padlock
   $RAQUO  = [char]0x203a # Single right-pointing angle quote ?
   $GEAR   = [char]0x2699 # The settings icon, I use it for debug
   $EX     = [char]0x27a6 # The X that looks like a checkbox.
   $POWER  = [char]0x26a1 # The Power lightning-bolt icon
   $MID    = [char]0xB7   # Mid dot (I used to use this for pushd counters)


   try {
      # Put the path in the title ... (don't restrict this to the FileSystem)
      $Host.UI.RawUI.WindowTitle = "{0} - {1} ({2})" -f $global:WindowTitlePrefix, (Convert-Path $pwd),  $pwd.Provider.Name
      # Make sure Windows & .Net know where we are
      # They can only handle the FileSystem, and not in .Net Core
      [Environment]::CurrentDirectory = (Get-Location -PSProvider FileSystem).ProviderPath
   } catch {}

   # Determine what nesting level we are at (if any)
   $Nesting = "$GEAR" * $NestedPromptLevel

   # Generate PUSHD(push-location) Stack level string
   $Stack = (Get-Location -Stack).count

   $(&{
      # If we can use advanced ANSI sequences, we can do some extra cool things 
      if($env:ConEmuANSI -eq "ON" -or $env:TERM -match "xterm") {
         $w = [Console]::BufferWidth
         $local:LastCommand = Get-History -Count 1
         $Elapsed = if($global:LastCommand.ID -ne $LastCommand.Id) {
            $global:LastCommand = $local:LastCommand
            $Duration = $LastCommand.EndExecutionTime - $LastCommand.StartExecutionTime
            if($Duration.TotalSeconds -ge 1.0) {
               "{0:h\:mm\:ss\.ffff}" -f $Duration
            } else {
               "{0}ms" -f $Duration.TotalMilliseconds
            }
         } else { '' }
         # 11 chars is "hh:mm:ss tt"
         $ElapsedLength = [Math]::Max($Elapsed.Length,12)
         $ElapsedPadding = " " * ($ElapsedLength - $Elapsed.Length)
         $TimeStamp = "{0:h:mm:ss tt}" -f [DateTime]::Now

         "${e}s" # MARK LOCATION
         if($Elapsed) {
            # Go UP one line and write at the end of that ...
            # TODO: If there's anything there, and add a line otherwise
            "${e}1A${e}${w}G${e}${ElapsedLength}D"
            "$($ANSI.fg.DarkGray)$($ANSI.bg.Default)$ElapsedPadding$LEFT" # DarkGray on Transparent
            "$($ANSI.fg.White)$($ANSI.bg.DarkGray)$Elapsed" # White on DarkGray
            "${e}u" # RECALL LOCATION
         }
         # Go to the end of the line and put a timestamp there ...
         "${e}${w}G${e}$($TimeStamp.Length)D"
         "$($ANSI.fg.DarkGray)$($ANSI.bg.Default)$LEFT" # DarkGray on Transparent
         "$($ANSI.fg.White)$($ANSI.bg.DarkGray)$TimeStamp" # White on DarkGray
         "${e}u" # RECALL LOCATION
      }

         # Output prompt string
         # Set some colors that I might use in other scripts
         if($err) {
            $fg_ = $ANSI.fg.DarkRed
            $bg_ = $ANSI.bg.DarkRed
         } else {
            $fg_ = $ANSI.fg.DarkBlue
            $bg_ = $ANSI.bg.DarkBlue
         }

         "$($ANSI.fg.DarkYellow)$($ANSI.bg.DarkYellow)<$($ANSI.fg.White)$($ANSI.bg.DarkYellow)#$($myinvocation.historyID)${Nesting}"
         if($Stack) {
            "$($ANSI.fg.DarkYellow)$($ANSI.bg.DarkGray)$RIGHT"
            "$($ANSI.fg.White)$($ANSI.bg.DarkGray)$RAQUO$Stack" # White on DarkGray
            "$($ANSI.fg.DarkGray)$bg_$RIGHT" # DarkGray on the prompt color
         } else {
            "$($ANSI.fg.DarkYellow)$bg_$RIGHT"
         }
         
         "$($ANSI.fg.White)$bg_$($pwd.Drive.Name):${GT}$(Split-Path $pwd.Path -Leaf)"
         
         if($global:VcsStatusEnabled) {
            # It's worth noting that I have my own PSGit module...
            Write-VcsStatus
         } else {
            "$fg_$($ANSI.bg.Default)$RIGHT$($ANSI.fg.Background)$($ANSI.bg.Default)#>$($ANSI.Clear)"
         }
      }) -join ""
}
