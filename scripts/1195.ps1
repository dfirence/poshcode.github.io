$null = [Reflection.Assembly]::LoadWithPartialName("System.Speech")

## Create the two main objects we need for speech recognition and synthesis
if(!$Global:SpeechModuleListener){ ## For XP's sake, don't create them twice...
   $Global:SpeechModuleSpeaker = new-object System.Speech.Synthesis.SpeechSynthesizer
   $Global:SpeechModuleListener = new-object System.Speech.Recognition.SpeechRecognizer
}

$Script:SpeechModuleMacros = @{}
## Add a way to turn it off
$Script:SpeechModuleMacros.Add("Stop Listening", { $script:listen = $false; Suspend-Listening })
$Script:SpeechModuleComputerName = ${Env:ComputerName}

function Update-SpeechCommands {
#.Synopsis
#  Recreate the speech recognition grammar
#.Description
#  This parses out the speech module macros,
#  and recreates the speech recognition grammar and semantic results,
#  and then updates the SpeechRecognizer with the new grammar,
#  and makes sure that the ObjectEvent is registered.
   $choices = new-object System.Speech.Recognition.Choices
   foreach($choice in $Script:SpeechModuleMacros.GetEnumerator()) {
   
      $g = New-Object System.Speech.Recognition.GrammarBuilder
      $phrases = @($choice.Key -split "\s*\*\s*")
      for($i=0;$i -lt $phrases.Count;$i++) {
         if($phrases[$i].Length -gt 0) {
            $g.Append( $phrases[$i] )
            if($i+1 -lt $phrases.Count) {
               $g.AppendDictation()
            }
         } elseif($i -eq 0) {
            $g.AppendDictation()
         }
      }
      $choices.Add( (New-Object System.Speech.Recognition.SemanticResultValue $g, $choice.Value.ToString()).ToGrammarBuilder() )
   }

   if($VerbosePreference -ne "SilentlyContinue") { $Script:SpeechModuleMacros.Keys |
      ForEach-Object { Write-Host "$Computer, $_" -Fore Cyan } }

   $builder = New-Object System.Speech.Recognition.GrammarBuilder "$Computer, "
   $builder.Append((New-Object System.Speech.Recognition.SemanticResultKey "Commands", $choices.ToGrammarBuilder()))
   $grammar = new-object System.Speech.Recognition.Grammar $builder
   $grammar.Name = "Power VoiceMacros"

   ## Take note of the events, but only once (make sure to remove the old one)
   Unregister-Event "SpeechModuleCommandRecognized" -ErrorAction SilentlyContinue
   $null = Register-ObjectEvent $grammar SpeechRecognized `
            -SourceIdentifier "SpeechModuleCommandRecognized" `
            -Action { $_ = $event.SourceEventArgs.Result.Text; iex $event.SourceEventArgs.Result.Semantics.Item("Commands").Value  }
   
   $Global:SpeechModuleListener.UnloadAllGrammars()
   $Global:SpeechModuleListener.LoadGrammarAsync( $grammar )
}

function Add-SpeechCommands {
#.Synopsis
#  Add one or more commands to the speech-recognition macros, and update the recognition
#.Parameter CommandText
#  The string key for the command to remove
   [CmdletBinding()]
   Param([hashtable]$VoiceMacros,[string]$Computer=$Script:SpeechModuleComputerName)
   
   ## Add the new macros
   $Script:SpeechModuleMacros += $VoiceMacros
   ## Update the default if they change it, so they only have to do that once.
   $Script:SpeechModuleComputerName = $Computer
   Update-SpeechCommands
}

function Remove-SpeechCommands {
#.Synopsis
#  Remove one or more command from the speech-recognition macros, and update the recognition
#.Parameter CommandText
#  The string key for the command to remove
   Param([string[]]$CommandText)
   foreach($command in $CommandText) { $Script:SpeechModuleMacros.Remove($Command) }
   Update-SpeechCommands
}

function Clear-SpeechCommands {
#.Synopsis
#  Removes all commands from the speech-recognition macros, and update the recognition
#.Parameter CommandText
#  The string key for the command to remove
   $Script:SpeechModuleMacros = @{}
   ## Default value: A way to turn it off
   $Script:SpeechModuleMacros.Add("Stop Listening", { Suspend-Listening })
   Update-SpeechCommands
}


function Start-Listening {
#.Synopsis
#  Sets the SpeechRecognizer to Enabled
   $Global:SpeechModuleListener.Enabled = $true
   Say "Speech Macros are $($Global:SpeechModuleListener.State)"
   Write-Host "Speech Macros are $($Global:SpeechModuleListener.State)"
}
function Suspend-Listening {
#.Synopsis
#  Sets the SpeechRecognizer to Disabled
   $Global:SpeechModuleListener.Enabled = $false
   Say "Speech Macros are disabled"
   Write-Host "Speech Macros are disabled"
}

function Out-Speech {
#.Synopsis
#  Speaks the input object
#.Description
#  Uses the default SpeechSynthesizer settings to speak the string representation of the InputObject
#.Parameter InputObject
#  The object to speak
#  NOTE: this should almost always be a pre-formatted string,
#        most objects don't render to very speakable text.
   Param( [Parameter(ValueFromPipeline=$true)][Alias("IO")]$InputObject )
   $null = $Global:SpeechModuleSpeaker.SpeakAsync(($InputObject|Out-String))
}

function Remove-SpeechXP {
#.Synopis
#  Dispose of the SpeechModuleListener and SpeechModuleSpeaker
   $Global:SpeechModuleListener.Dispose(); $Global:SpeechModuleListener = $null
   $Global:SpeechModuleSpeaker.Dispose(); $Global:SpeechModuleSpeaker = $null
}

set-alias asc Add-SpeechCommands
set-alias rsc Remove-SpeechCommands
set-alias csc Clear-SpeechCommands
set-alias say Out-Speech
set-alias listen Start-Listener
Export-ModuleMember -Function * -Alias * -Variable SpeechModuleListener, SpeechModuleSpeaker
