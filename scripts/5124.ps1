
function Read-Choice {
   <#
      .Synopsis
        Prompt the user for a choice, and return the (0-based) index of the selected item
      .Parameter Message
        This is the prompt that will be presented to the user. Basically, the question you're asking.
      .Parameter Choices
        An array of strings representing the choices (or menu items), with optional ampersands (&) in them to mark (unique) characters which can be used to select each item.
      .Parameter ChoicesWithHelp
        A Hashtable where the keys represent the choices (or menu items), with optional ampersands (&) in them to mark (unique) characters which can be used to select each item, and the values represent help text to be displayed to the user when they ask for help making their decision.
      .Parameter Default
        The (0-based) index of the menu item to select by default (defaults to zero).
      .Parameter MultipleChoice
        Prompt the user to select more than one option. This changes the prompt display for the default PowerShell.exe host to show the options in a column and allows them to choose multiple times.
        Note: when you specify MultipleChoice you may also specify multiple options as the default!
      .Parameter Caption
        An additional caption that can be displayed (usually above the Message) as part of the prompt
      .Parameter Passthru
        Causes the Choices objects to be output instead of just the indexes
      .Example
        Read-Choice "WEBPAGE BUILDER MENU"  "&Create Webpage","&View HTML code","&Publish Webpage","&Remove Webpage","E&xit"
      .Example
        [bool](Read-Choice "Do you really want to do this?" "&No","&Yes" -Default 1)
        
        This example takes advantage of the 0-based index to convert No (0) to False, and Yes (1) to True. It also specifies YES as the default, since that's the norm in PowerShell.
      .Example
        Read-Choice "Do you really want to delete them all?" @{"&No"="Do not delete all files. You will be prompted to delete each file individually."; "&Yes"="Confirm that you want to delete all of the files"}
        
        Note that with hashtables, order is not guaranteed, so "Yes" will probably be the first item in the prompt, and thus will output as index 0.  Because of thise, when a hashtable is passed in, we default to Passthru output.
   #>
   [CmdletBinding()]
   param(
      [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$True)]
      [Array]$Choices
   ,  
      [Parameter(Mandatory=$False, Position=1)]
      [string]$Message = "Choose one of the following options:"
   ,
      [Parameter(Mandatory=$False)]
      [string]$Caption = "Please choose!"
   ,  
      [Parameter(Mandatory=$False)]
      [int[]]$Default  = 0
   ,  
      [Switch]$MultipleChoice
   ,
      [Switch]$Passthru
   )
   begin { 
      $ChoiceDescriptions = @() 
      $Output = @()
   }
   process {
      $Output += $Choices
      $ChoiceDescriptions += $(
         foreach($choice in $Choices) {
            if($Choice -is [System.Collections.IDictionary]) { 
               if($Choice.Count -eq 1) {
                  $Option = $Choice.GetEnumerator()[0]
                  New-Object System.Management.Automation.Host.ChoiceDescription $Option.Key, $Option.Value
               } else {
                  ForEach($Key in $Choice.Keys) {
                     if("Name" -like "${Key}*") {
                        $Name = $Choice.$Key
                     }
                     if("Value" -like "${Key}*") {
                        $Value = $Choice.$Key
                     }
                     if("Expression" -like "${Key}*") {
                        $Value = $Choice.$Key
                     }
                  }
                  if($Name -and $Value) {
                     New-Object System.Management.Automation.Host.ChoiceDescription $Name, $Value
                  } else {
                     $Choice.GetEnumerator() | % { 
                        New-Object System.Management.Automation.Host.ChoiceDescription $_.Key, $_.Value
                     }
                  }
               }
            } else {
               $Props = Get-Member -Input $Choice -Type Properties
               $Name = $Props | Where { "Name" -like "$($_.Name)*" } | Sort Length -Descending | Select -First 1 | %{ $Choice.($_.Name) }
               $Value = $Props | Where { "Value" -like "$($_.Name)*" -or "Expression" -like "$($_.Name)*" } | Sort {$_.Name.Length} -Descending | Select -First 1 | %{ $Choice.($_.Name) }
               if($Name -and $Value) {
                  New-Object System.Management.Automation.Host.ChoiceDescription $Name, $Value
               } else {
                  New-Object System.Management.Automation.Host.ChoiceDescription "$Choice", "$Choice"
               }
            }
         }
      )
   }
   end {
      $Labels = $ChoiceDescriptions | % { $_.Label }
      # Try making unique keys for the labels:
      $Keys =@()
      # If they already have a key
      for($l =0; $l -lt $Labels.Count; $l++) {
         if($Labels[$l].IndexOf('&') -ge 0) {
            $Keys += $Labels[$l][($Labels[$l].IndexOf('&')+1)]
         }
      }
      # Otherwise pick the first letter that's not a key
      for($l =0; $l -lt $Labels.Count; $l++) {
         if($Labels[$l].IndexOf('&') -lt 0) {
            for($i = 0; $i -lt $Labels[$l].Length; $i++) {
               if($Keys -notcontains $Labels[$l][$i]) {
                  $Keys += $Labels[$l][$i]
                  $Labels[$l] = $Labels[$l].Insert($i,'&')
                  $ChoiceDescriptions[$l] = New-Object System.Management.Automation.Host.ChoiceDescription $Labels[$l], $ChoiceDescriptions[$l].HelpMessage
                  break
               }
            }
         }
      }
      # Otherwise, add a number or a letter
      for($l =0; $l -lt $Labels.Count; $l++) {
         if($Labels[$l].IndexOf('&') -lt 0) {
            foreach($i in 49..57+66..90) {
               if($Keys -notcontains [string][char]$i) {
                  $Keys += [string][char]$i
                  $Labels[$l] = '{0}(&{1})' -f $Labels[$l], ([string][char]$i)
                  $ChoiceDescriptions[$l] = New-Object System.Management.Automation.Host.ChoiceDescription $Labels[$l], $ChoiceDescriptions[$l].HelpMessage
                  break
               }
            }
         }
      }

      # Passing an array as the $Default triggers multiple choice prompting.
      if(!$MultipleChoice) { [int]$Default = $Default[0] }

      [int[]]$Answer = $Host.UI.PromptForChoice($Caption,$Message,$ChoiceDescriptions,$Default)

      if($Passthru -or !($choices -is [String[]])) {
         Write-Verbose "$Answer"
         Write-Output  $Output[$Answer]
      } else {
         Write-Output $Answer
      }
   }
}

