function edit-file2 ([string]$path=newfile.ps1) 
{
$paths = @(resolve-path $path -ErrorAction SilentlyContinue); if ($paths.count -gt 1) {if ($psplus.Confirm(You are about to open the below files. Are you sure?, Open multiple files, $paths) -eq $FALSE) {break} } elseif ($paths.count -eq 0) {	if ($psplus.Confirm(No files matched your request. Do you want to create a new file?, Create New File, $path) -eq $TRUE) {[En
11:01
vironment]::CurrentDirectory = (Get-Item (Get-Location)).FullName; trap { Write-Error $_.Exception.Message; continue} . {$path = [System.IO.Path]::GetFullPath($path); if (!($path.Contains(.))) {$path += .ps1}; > $path; $paths = @($path) }} else {break}}; foreach ($path in $paths) { $psplus.OpenFile((get-item $path).FullName) }
}
