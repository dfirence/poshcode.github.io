##
## Start-WimmEmulator.ps1
##
## Starts the WIMM emulator - must be placed in the add-ons\addon_wimm_one_7\tools
## directory along with the rest of the WIMM tools. 
##
## http://dev.wimm.com/

if(-not $env:ANDROID_SDK_DIR)
{
    $env:ANDROID_SDK_DIR = Resolve-Path (Join-Path $psscriptRoot ..\..\..)
}

if(-not (Test-Path "$env:HOMEPATH\.android\avd\WIMMOne.ini"))
{
    Write-Verbose "Creating WIMMOne avd"
    & "$env:ANDROID_SDK_DIR\tools\android.bat" create avd -s WIMMOne -n WIMMOne -t "WIMM Labs, Inc.:WIMM One Add-On:7" -c 9M --force
}

$certPath = Join-Path $env:ANDROID_SDK_DIR "add-ons\addon_wimm_one_7\credentials"
$certFile = dir "$certPath\*.pfx" | Select -Last 1
if(-not $certFile)
{
    throw "You must have a PFX certificate file installed at $certPath"
}
Write-Verbose "CertFile is $($certFile.FullName)"

$id = dir "$env:ANDROID_SDK_DIR\add-ons\addon_wimm_one_7\credentials\*.id" | Select -Last 1
if(-not $id)
{
    throw "You must have an ID file installed at $certPath"
}
$id = $id | Get-Content
Write-Verbose "ID is $id"

$imagePath = "$env:HOMEPATH\.android\avd\WIMMOne.avd\env.img"
$otpPath= "$env:HOMEPATH\.android\avd\WIMMOne.avd\otp.img"
$imagePath,$otpPath | Foreach-Object {
    if(-not (Test-Path $_))
    {
        $bytes = [byte[]] (Get-Content (Join-Path $psscriptRoot nand.dat) -Encoding Byte)
        Set-Content $_ ($bytes * 1024) -Encoding Byte
    }
}

& $env:ANDROID_SDK_DIR\tools\emulator.exe -avd WIMMOne -prop dev.id=$id -qemu -nand "env,size=0x40000,file=$imagePath" -nand "otp,size=0x40000,file=$otpPath"
& $env:ANDROID_SDK_DIR\platform-tools\adb.exe -e wait-for-device push "$($certFile.FullName)" /data/misc/nv/cert.pfx
