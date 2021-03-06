# There are three kinds of menu items in WPF (and thus, in ShowUI):

Window -Width 300 -Height 150 {
   DockPanel {
      Menu -Dock Top -Height 20 {
         MenuItem -Header "_File" {
            ####### First (and most complicated) MenuItem type:
            ## Menu items hooked to built-in commands that require manual handling
            ## NOTE: These are "ApplicationCommands" defined here:
            ##        http://msdn.microsoft.com/library/system.windows.input.applicationcommands
            MenuItem -Command "New"
            MenuItem -Command "Open"
            MenuItem -Command "Save"
            MenuItem -Command "SaveAs"
            Separator
            MenuItem -Command "Print"
            Separator
            ####### Second most complicated MenuItem type:
            ## Menu items with no Command, and a click handler instead.
            ## There's no "Exit" command (Alt+F4 is handled by the OS)
            ## So if you you want an EXIT menu item, you have to make it up:
            MenuItem -Header "E_xit" -On_Click { Close-Control $window }
         }
         MenuItem -Header "_Edit" {
            ####### Lastly, the most simple MenuItem type:
            ## MenuItems with built-in basic handling.
            ## These are more "ApplicationCommands" that are handled by the RichTextBox.
            ## This sort-of stuff is *why* WPF uses routable Commands: they can be "handled" by any control...
            MenuItem -Command "Undo"
            MenuItem -Command "Redo"
            Separator
            MenuItem -Command "Select All"
            MenuItem -Command "Cut"
            MenuItem -Command "Copy"
            MenuItem -Command "Paste"
            MenuItem -Command "Delete"
            Separator
            ##  TODO:
            MenuItem -Command "Find"
            MenuItem -Command "Replace"
         }
         MenuItem -Header "F_ormat" {
            ## These are "EditingCommands" and are also handled magically by the RichTextBox.
            ## There are lots more of them, but I don't have the patience to add them all:
            ## http://msdn.microsoft.com/library/system.windows.documents.editingcommands
            MenuItem -Header "_Bold" -Command "ToggleBold"
            MenuItem -Header "_Italic" -Command "ToggleItalic"
         }
         MenuItem -Header "_View" {
            ## These are place holders ... you should do something fun here
            MenuItem -Header "_Status Bar"
            MenuItem -Header "_Word Wrap"
         }
         MenuItem -Header "_Help" {
            ## More place holders...
            MenuItem -Header "_About"
         }
      }
      
      ## BUGBUG: My RichTextBox command is borked, it's missing it's parameters!
      ##         FIXED for ShowUI 1.5 (coming VERY soon)
      ## Workaround: Set the Name by hand, since that's all I cared about
      RichTextBox | % { $_.Name = "Content"; $_ }

   } -On_Load {
      ## In the load event, hook up command bindings for commands you need to handle:
      ## You must handle the CanExecute. Set CanExecute to True to enable the menu item
      $this.CommandBindings.Add( (
         CommandBinding -Command "New" `
                     -On_CanExecute {$_.CanExecute = $Content.Document.Blocks.Count -gt 0 }   `
                     -On_Executed { $Content.Document.Blocks.Clear() } 
      ) ) | Out-Null
   }
} -Show

## These cmdlets wrap the built-in commands
## They have switches to output each of the commands
# Get-ApplicationCommand 
# Get-ComponentCommand   
# Get-EditingCommand     
# Get-MediaCommand       
# Get-NavigationCommand  

