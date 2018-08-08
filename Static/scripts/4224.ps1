$sourcex86 = 'http://javadl.sun.com/webapps/download/AutoDL?BundleId=79063' #Java 7 u 25 x86
$sourcex64 = 'http://javadl.sun.com/webapps/download/AutoDL?BundleId=79065' #Java 7 u 25 x64

$64bit = $false
if(Test-Path 'C:\Program Files (x86)' -PathType Container){
    $64bit = $true
}

try{
    if(Test-Path 'C:\Download\Java' -PathType Container){
        $destinationx86 ='C:\Download\Java\java7u25x86.exe'
        if($64bit){
            $destinationx64 ='C:\Download\Java\java7u25x64.exe'
        }
    }
    else{
        New-Item -Path 'C:\Download' -Name 'Java' -ItemType directory
        $destinationx86 ='C:\Download\Java\java7u25x86.exe'
        if($64bit){
            $destinationx64 ='C:\Download\Java\java7u25x64.exe'
        }
    }

    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($sourcex86, $destinationx86)
    if($64bit){
        $wc.DownloadFile($sourcex64, $destinationx64)
    }
}
catch{
    $Error[0]
    return (-1)
}




CMD /c $destinationx86 /s
if($64bit){
    CMD /c $destinationx64 /s
}
