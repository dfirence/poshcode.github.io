Do {
Write-Host "
----------360 Visibility - Signature Generator ----------

    1 = Office 365
    2 = On-Premise Active Directory
    3 = Exit

---------------------------------------------------------"
$choice1 = read-host -prompt "Select number & press enter"
} until ($choice1 -eq "1" -or $choice1 -eq "2" -or $choice1 -eq "3")

Switch ($choice1) {

#Beginning of Option 1
#############################
                "1" {
                $CheckMSOnline = (get-item $env:SystemRoot\System32\WindowsPowerShell\v1.0\Modules\MSOnline\Microsoft.Online.Administration.Automation.PSModule.dll).VersionInfo.FileVersion

                if (!$CheckMSOnline ) {
                Write-Host ""
                Write-Host "Failed to locate module MSOnline." -Fore Red
                Write-Host "You do not have the necessary module installed in order to continue..." -Fore Red
                Write-Host ""
                Write-Host "Please navigate to Addons folder and run the installers starting with Microsoft Online Services Sign-in Assistant"
                Write-Host ""
                Write-Host "The application will now exit. Please run it again once you've installed the prerequisites"
                Write-Host ""
                pause
                exit                    
                } 

                #File to specify Users location
				$filename = "O365-settings.txt"
                $file = $PSScriptRoot + "\" + $filename
                $fileexists = Test-Path $file 
                if (!$fileexists) {
                Write-Host ""
                Write-Host "No settings file found. Please ensure the file exists."
                pause
                exit
                }
                Write-Host ""
                Write-Host "Checking O365-Settings File...."

                #set folder location for files, the folder must allready exist
                $save_location = Get-Content $file | Select-Object -Index 1
                if (!$save_location) {
                Write-Host "You need to set a destination in the O365-settings File. Close Program and Run again."
                pause
                exit
                } else {
                Write-Host ""
                Write-Host "O365-Settings File check completed. Continuing..."}

                #connect to O365 tenant
                Write-Host "You will now need to connect to your Office 365 Subscription using an Admin Account."
                $Cred = Get-Credential -Message "Please enter your Office 365 Login."
                                
                $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://ps.outlook.com/powershell/ -Credential $Cred -Authentication Basic –AllowRedirection
                Import-PSSession $Session

                #Ask User to pick template file
                Function Get-FileName($initialDirectory)
                {
                    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
                    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
                    $OpenFileDialog.initialDirectory = $initialDirectory
                    $OpenFileDialog.filter = "HTML (*.htm)| *.htm"
                    $OpenFileDialog.ShowDialog() | Out-Null
                    $OpenFileDialog.filename
                }

                $html_template = Get-FileName "." 
                $html_templateContent = Get-Content $html_template -Raw

                Connect-MsolService -Credential $Cred

                #Get-MsolUser | where {$_.islicensed} | FT  UserPrincipalName, Firstname, Lastname, Title, PhoneNumber
                #$users  = New-Object System.Collections.ArrayList
                $users = Get-MsolUser | where {$_.islicensed} | select  UserPrincipalName, Firstname, Lastname, Title, PhoneNumber

                 foreach ($user in $users) {
  
                  $account_name = "$($user.UserPrincipalName)" 
                  $full_name = “$($user.Firstname) $($user.Lastname)”
                  $job_title = "$($user.Title)"
                  $phone =  "$($user.PhoneNumber)"
 
                  #We need to construct and write the html signature file
                  $output_file = $save_location + $user.UserPrincipalName.Split('@')[0] + ".htm"

                  $htmloutput = $html_templateContent -f $full_name, $job_title, $phone 
                 
                  Write-Host "`t`tNow attempting to create signature htm file for $full_name`n" -Fore Cyan
                  $htmloutput | Out-File $output_file
                }

                #disconnect O365 connection
                get-PSSession | remove-PSSession
                Write-Host ""
                Write-Host "Successfully Completed." -Fore Green
                Write-Host "Signatures have been saved to: $save_location" 
                Write-Host ""
                pause
                exit
                }



#Beginning of Option 2
#############################
                "2" {
                #File to specify Users location
                $file = ".\AD-settings.txt"
                $fileexists = Test-Path $file
                $save_location = Get-Content $file | Select-Object -Index 4               
                $activeusers = Get-Content $file | Select-Object -Index 1                           
             
                if (!$fileexists) {
                Write-Host "No settings file found. Please ensure the file exists."
                pause
                exit
                }
                
                Write-Host "Checking AD-settings File...."
                if (!$save_location) {
                    Write-Host "You need to configure settings.txt. Please specifiy an output directory."
                    pause
                    exit
                }
                $folder = Test-Path $save_location
                if (!$folder) {
                Write-Host "Save location does not exist. Please create folder $save_location in the root folder."
                pause
                exit
                }
                if (!$activeusers) {
                    Write-Host "You need to configure the settings.txt file before proceeding.You will need to re-run the application."
                    pause
                    exit
                } else {Write-Host "AD-Settings File check completed. Continuing..."}

                import-module activedirectory

                
                $users = Get-ADUser -filter * -searchbase $activeusers -Properties *
                Function Get-FileName($initialDirectory)
                {
                    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    
                    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
                    $OpenFileDialog.initialDirectory = $initialDirectory
                    $OpenFileDialog.filter = "HTML (*.htm)| *.htm"
                    $OpenFileDialog.ShowDialog() | Out-Null
                    $OpenFileDialog.filename
                }

                $html_template = Get-FileName "."
                 foreach ($user in $users) {
                  $full_name = “$($user.GivenName) $($User.Surname)”
                  $account_name = "$($User.sAMAccountName)"
                  $job_title = "$($User.title)"
                  $phone =  "$($User.telephoneNumber)"
 
 
                  #We need to construct and write the html signature file
                  $output_file = $save_location + $account_name + ".htm"

                  $htmloutput = $html_template -f $full_name, $job_title, $phone 

                  Write-Host "`n`t360 Visibility Inc.: Signature Deployment - Version 1.1`n" -Fore Magenta
                  Write-Host "`t`tNow attempting to create signature htm file for $full_name`n" -Fore Cyan
                  $htmloutput | Out-File $output_file
                }

                Write-Host ""
                Write-Host "Successfully Completed." -Fore Green
                Write-Host "Signatures have been saved to: $save_location" 
                Write-Host ""
                pause
                exit

                }


#Beginning of option 3
#############################
                "3" {
                exit
                }

}


 
