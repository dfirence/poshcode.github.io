$ErrorActionPreference = "SilentlyContinue"

CLS

# Paths
$encrypted_path = "C:\Password_Recovery\Encrypted"
$decrypted_Path = "c:\Password_Recovery\Decrypted\"
$original_Path = "c:\Password_Recovery\Originals\"
$password_Path = "c:\Password_Recovery\Passwords\Passwords.txt"

# Load Password Cache
$arrPasswords = Get-Content -Path $password_Path

# Load File List
$arrFiles = Get-ChildItem $encrypted_path 

# Create counter to display progress
[int] $count = ($arrfiles.count -1)

# Loop through each file
$arrFiles| % {
    $file  = get-item -path $_.fullname 
    # Display current file
    write-host "Processing" $file.name -f "DarkYellow"
    write-host "Items remaining: " $count `n

    # Word docx
    if ($file.Extension -eq ".docx") {

    # Loop through password cache
        $arrPasswords | % {
            $passwd = $_
            
            # New Word Object
            $WordObj = $null
            $WordObj = New-Object -ComObject Word.Application
            $WordObj.Visible = $false
            $WordObj.Options.WarnBeforeSavingPrintingSendingMarkup = $false

            # Attempt to open file
            $WordDoc = $WordObj.Documents.Open($file.fullname, $null, $false, $null, $passwd, $passwd)
            $WordDoc.Activate()
            $content = $null
            $content = $WordDoc.content

            # if password is correct - Save new file without password to $decrypted_Path
            if ($content -ne $null) {
                write-host "opened " -f "Yellow"
                $WordDoc.Password=$null
                $savePath = $decrypted_Path+$file.Name
                write-host "Decrypted: " $file.Name -f "DarkGreen"
                $WordDoc.SaveAs([ref]$savePath)
            # Close document and Application
                $WordDoc.Close()
                $WordObj.Application.Quit()

            # Move original file to $original_Path
                move-item $file.fullname -Destination $original_Path -Force
                }
            else {
            # Close document and Application
                $WordDoc.Close()
                $WordObj.Application.Quit()
            }
        }
    }
    # Excel xlsx
    elseif ($file.Extension -eq ".xlsx") {

    # Loop through password cache
        $arrPasswords | % {
            $passwd = $_
            
            # New Excel Object
            $ExcelObj = $null
            $ExcelObj = New-Object -ComObject Excel.Application
            $ExcelObj.Visible = $false

            # Attempt to open file
            $Workbook = $ExcelObj.Workbooks.Open($file.fullname,1,$false,5,$passwd)
            $Workbook.Activate()

            # if password is correct - Save new file without password to $decrypted_Path
                if ($Workbook.Worksheets.count -ne 0) {
                    $Workbook.Password=$null
                    $savePath = $decrypted_Path+$file.Name
                    write-host "Decrypted: " $file.Name -f "DarkGreen"
                    $Workbook.SaveAs($savePath)
            # Close document and Application
                    $ExcelObj.Workbooks.close()
                    $ExcelObj.Application.Quit()

            # Move origanl file to $original_Path
                    move-item $file.fullname -Destination $original_Path -Force
                }
                else {
            # Close document and Application
                    $ExcelObj.Close()
                    $ExcelObj.Application.Quit()
                }
        }

    }
    
    elseif ($file.Extension -eq ".pptx") {

    # Loop through password cache
    
    $arrPasswords | % {
        $passwd = $_

        # New Powerpoint Object
        $objPPT = New-Object -ComObject Powerpoint.Application

        # Attempt to open file
        $Presentation = $objPPT.ProtectedViewWindows.Open($file, $passwd)

        if ($presentation.application -ne $null) {
        # if password is correct - Enable Edit Mode
            $openPresentationWithPasswords = $Presentation.Edit("ModifyPassword")
        # Remove Password
            $openPresentationWithPasswords.Password = $null

        #Save new file to $decrypted_Path
            $savePath = $decrypted_Path+$file.Name
            write-host $savepath -f "yellow"
            $openPresentationWithPasswords.SaveAs($savePath)
            write-host "Decrypted: " $file.Name -f "DarkGreen"

         # Close document and Application
            $openPresentationWithPasswords.Close()
            $objPPT.Quit()
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($openPresentationWithPasswords) | out-null
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($presentation) | out-null
            [System.Runtime.Interopservices.Marshal]::ReleaseComObject($objPPT) | out-null

        # Move origanl file to $original_Path
            move-item $file.fullname -Destination $original_Path -Force
        }

        else {
        # Close document and Application
            $objPPT.Quit()
             [System.Runtime.Interopservices.Marshal]::ReleaseComObject($openPresentationWithPasswords) | out-null
             [System.Runtime.Interopservices.Marshal]::ReleaseComObject($objPPT) | out-null
        }
    }
}

if ($file.Extension -eq ".pdf") {

    # Loop through password cache
    $arrPasswords | % {
        $passwd = $_
            
        # Path to GhostScript installation
        $ghostScriptPath = "C:\Program Files\gs\gs9.14\bin\gswin32.exe"
        
        $savePath = $decrypted_Path+$file.Name

        # arguments
        $args = '-q', '-dSAFER', '-dBATCH', '-dNOPAUSE', '-sDEVICE=pdfwrite', '-sFONTPATH=%windir%/fonts;xfonts;.', "-sPDFPassword=$passwd", '-dPDFSETTINGS=/prepress', '-dPassThroughJPEGImages=true', "-sOutputFile=$savePath", $file.FullName
        
        # Attempt to Decrypt Document
        & $ghostScriptPath $args 
        # need get-job wait-job # but not time to leave for day
        sleep 2
        Get-Process -name gswin32 

        # Move original file to $original_Path
        if (test-path -path $savePath) {
            move-item $file.fullname -Destination $original_Path -Force
        }
    }
    # Kill GhostScript processes from failed password attempts

    Get-Process -name gswin32 | % {tskill $_.id} | out-null
}
$count--
# Next File
}

Write-host "`n Complete" -f "Green"
