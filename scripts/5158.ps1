Function Setup-Profile{
    
    $hasProfile = Test-Path -Path $profile

    if ($hasProfile -eq $false){
        $answer = Read-Host "No profile detected. Would you like to create one? (Y)es or (N)o"
        while("y","n","yes","no" -notcontains $answer)
        {
        	$answer = Read-Host "Yes or No"
        }
        
            if ($answer -eq "y"){
                New-Item -Path $profile -ItemType "file" -Force
            } 
    }
}
