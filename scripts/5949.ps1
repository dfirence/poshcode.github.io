#------------------------------------------------------------------------------
# Strips off the '1-' prefix from phone numbers stored in Active Directory.
# Requires 'ActiveRoles Management Shell for Active Directory' from Quest
# Software.
#------------------------------------------------------------------------------
$data = @()
$users = Get-QADUser -sizelimit 0 `
    | Where-Object { $_.PhoneNumber -like "1-*" } `
    | Where-Object { $_.PhoneNumber.Length -eq 14 } `
    | Sort-Object -Property Name
foreach ( $user in $users )
{
    if ( $user -eq $null )
    {
        continue
    }
    $newPhoneNumber = $user.PhoneNumber.ToString()
    $newPhoneNumber = $newPhoneNumber.Substring(2,12)
    $dataLine = New-Object psObject
    $dataLine | Add-Member -MemberType NoteProperty -Name "User" -Value $user.Name
    $dataLine | Add-Member -MemberType NoteProperty -Name "OldPhone" -Value $user.PhoneNumber
    $dataLine | Add-Member -MemberType NoteProperty -Name "NewPhone" -Value $newPhoneNumber
    $dataLine | Add-Member -MemberType NoteProperty -Name "DN" -Value $user.DN
    $data += $dataLine
    Set-QADUser -Identity $user.DN -PhoneNumber $newPhoneNumber 
}
if ( $data.Count -gt 0 )
{
    $data | Out-GridView
}
