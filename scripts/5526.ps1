#requires -Version 3.0
#function Edit-Function
#{


<#
    .SYNOPSIS
        Creates and edits functions in the session in a script editor.
    
    .DESCRIPTION
        The Edit-Function.ps1 script lets you create or edit functions in your session in a function editor.

        It opens the specified function in the script editor that you specify or, if you don't speciy an editor, it tries checking for the editor configured in git, and searching for Sublime, and falls back to Notepad. When you finish editing the function and close the editor, the script updates the function in your session with the new function code.
        
        Functions are tricky to edit, because most code editors require a file. Edit-Function.ps1 creates a temporary file with the function code. Then, when you close the editor, it replaces the function in your session with the edited function and deletes the temporary file.

        If you have a favorite editor, you can use the Editor parameter to specify it. ALternatively, the script will search your git config, or for sublime or fall back to notepad and will store it for further executions in the same session.  If you want to avoid the search, you can set the "EDITOR" environment variable, or set the PSEditor global variable in your profile. 

        REMEMBER: Because functions are specific to a session, your function edits are lost when you close the session unless you save them in a permanent file, such as your Windows PowerShell profile.
    
    .EXAMPLE
        Edit-Function Prompt

        Opens the prompt function in a default editor (gitpad, Sublime, Notepad, whatever)

    .EXAMPLE
        dir Function:\cd* | Edit-Function -Editor "C:\Program Files\Sublime Text 3\subl.exe" -Param "-n -w"

        Pipes all functions starting with cd to Edit-Function, which opens them one at a time in a new sublime window (opens each one after the other closes).

    .EXAMPLE
        Get-Command TabExpan* | Edit-Function -Editor 'C:\Program Files\SAPIEN Technologies, Inc\PowerShell Studio 2014\PowerShell Studio.exe
        
        Edits the TabExpansion and/or TabExpansion2 (whichever exists) in PowerShell Studio 2014 using the full path to the .exe file.
        Note that this also sets PowerShell Studio as your default editor for future calls.

    .NOTES
        By Joel Bennett (@Jaykul) and June Blender (@juneb_get_help)
        
        If you'd like anything changed  ... feel free to push new version on PoshCode, or tweet at me :-)
        - Do you not like that I make every editor the default?
        - Think I should detect notepad2 or notepad++ or something?
        
        About ISE: it doesn't support waiting for the editor to close, sorry.
#>
    [CmdletBinding()]
    param
    (
        # Specifies the name of the function to create or edit. Enter a function name or pipe a function to Edit-Function.ps1. This parameter is required. If the function doesn't exist in the session, Edit-Function creates it.
        [Parameter(Mandatory = $true,
                   ValueFromPipelineByPropertyName = $true)]
        [System.String]
        $Name,

        # Specifies a code editor. If the editor is in the Path environment variable (Get-Command <editor>), you can enter just the editor name. Otherwise, enter the path to the executable file for the editor.
        # Defaults to the value of $PSEditor.Command or $PSEditor or Env:Editor if any of them are set.
        [System.String]
        $Editor = $(if($global:PSEditor.Command){ $global:PSEditor.Command } else { $global:PSEditor } ),

        # Specifies commandline parameters for the editor. 
        # Edit-Function.ps1 passes these editor-specific parameters to the editor you select. 
        # For example, sublime uses -n -w to trigger a mode where closing the *tab* will return
        [System.String]
        $Parameters = $global:PSEditor.Parameters
    )
    begin
    {
        function Split-Command {
            # The normal (unix) "Editor" environment variable can include parameters
            # so it can be executed from command by just appending the file name.
            # However, PowerShell can't deal with that, so:
            param(
                [Parameter(Mandatory=$true)]
                [string]$Command
            )
            $Parts = @($Command -Split " ")

            for($count=$Parts.Length; $count -gt 1; $count--) {
                $Editor = ($Parts[0..$count] -join " ").Trim("'",'"')
                if((Test-Path $Editor) -and (Get-Command $Editor -ErrorAction SilentlyContinue)) { 
                    $Editor
                    $Parts[$($Count+1)..$($Parts.Length)] -join " "
                    break
                }
            }
        }
    }
    process
    {
        #Creates a temporary file in your temp directory with a .tmp.ps1 extension.
        $file = [IO.Path]::GetTempFileName() | Rename-Item -NewName { [IO.Path]::ChangeExtension($_, ".tmp.ps1") } -PassThru

        #If you have a function with this name, it saves the function code in the temporary file.
        if (Test-Path Function:\$Name) {
            Set-Content -Path $file -Value (Get-Content Function:\$Name)
        }
        $LastWriteTime = (Get-Item $File).LastWriteTime

        do { # This is the GOTO hack: use break to skip to the end once we find it:
            # In this test, we let the Get-Command error leak out on purpose
            if($Editor -and (Get-Command $Editor)) { break }

            if ($Editor -and !(Get-Command $Editor -ErrorAction SilentlyContinue))
            {
                Write-Verbose "Editor is not a valid command, split it:"
                $Editor, $Parameters = Split-Command $Editor
                if($Editor) { break }
            }


            if (Test-Path Env:Editor)
            {
                Write-Verbose "Editor was not passed in, trying Env:Editor"
                $Editor, $Parameters = Split-Command $Env:Editor
                if($Editor) { break }
            }


            # If no editor is specified, try looking in git config
            if (Get-Command Git -ErrorAction SilentlyContinue)
            {
                Write-Verbose "PSEditor and Env:Editor not found, searching git config"
                $Editor, $Parameters = Split-Command (git config core.editor)
                if($Editor) { break }
            }

            # Search for Sublime
            Write-Verbose "Editor not found, trying Sublime"
            if ($Editor = Get-ChildItem C:\Program*\* -recurse -filter "sublime_text.exe" -ErrorAction SilentlyContinue | Select-Object -First 1)
            {
                $Parameters = "-n -w"
                break
            }

            # Settling for Notepad (should probably try some other searches search for Notepad++ probably, but whatever)
            Write-Verbose "Editor not found, trying notepad"
            $Editor = "notepad"

            if(!$Editor -or !(Get-Command $Editor -ErrorAction SilentlyContinue -ErrorVariable NotFound)) { 
                if($NotFound) { $PSCmdlet.ThrowTerminatingError( $NotFound[0] ) }
                else { 
                    throw "Could not find an editor (not even notepad!)"
                }
            }
        } while($false)

        # There are several reasons we might need to update the editor variable
        if($PSBoundParameters.ContainsKey("Editor") -or 
           $PSBoundParameters.ContainsKey("Parameters") -or 
           !(Test-Path variable:global:PSeditor) -or 
           ($PSEditor.Command -ne $Editor))
        {
            $global:PSEditor = New-Object PSObject -Property @{
                Command = "$Editor"
                Parameters = "$Parameters"
            } | Add-Member ScriptMethod ToString -Value { "'" + $this.Command + "' " + $this.Parameters } -Force -PassThru
        }

        # Avoid errors if Parameter is null/empty.
        Write-Verbose "$PSEditor '$File'"
        if ($Parameters)
        {
            Start-Process -FilePath $Editor -ArgumentList $Parameters, $file -Wait
        }
        else
        {
            Start-Process -FilePath $Editor -ArgumentList $file -Wait
        }
        
        if($LastWriteTime -ne (Get-Item $File).LastWriteTime) {
            Write-Verbose "Changed $Name function"
        
            #Recreates the function from the code in the temporary file and then deletes the file.
            Set-Content -Path Function:\$Name -Value ([scriptblock]::create((Get-Content $file -Raw)))
            Remove-Item $File
        } else {
            Write-Warning "No change to $Name function"
        }
    }
#}
