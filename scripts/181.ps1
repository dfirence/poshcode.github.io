# Get-RemoteRegistry
# NOTE: you have to have access, and the remote registry service has to be running
param(
  [string]$computer = $(Read-Host "Remote Computer Name")
  ,[string]$Path     = $(Read-Host "Remote Registry Path (must start with HKLM,HKCU,etc)")
  ,[switch]$Verbose
)
if ($Verbose) { $VerbosePreference = 2 } # Only affects this script.

  $root, $last = $Path.Split("\")
  $last = $last[-1]
  $Path = $Path.Substring($root.Length + 1,$Path.Length - ( $last.Length + $root.Length + 2))

  #split the path to get a list of subkeys that we will need to access
  # ClassesRoot, CurrentUser, LocalMachine, Users, PerformanceData, CurrentConfig, DynData
  switch($root) {
    "HKCR"  { $root = "ClassesRoot"}
    "HKCU"  { $root = "CurrentUser" }
    "HKLM"  { $root = "LocalMachine" }
    "HKU"   { $root = "Users" }
    "HKPD"  { $root = "PerformanceData"}
    "HKCC"  { $root = "CurrentConfig"}
    "HKDD"  { $root = "DynData"}
    default { return "Path argument is not valid" }
  }


  #Access Remote Registry Key using the static OpenRemoteBaseKey method.
  Write-Verbose "Accessing $root from $computer"
  $rootkey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($root,$computer)
  if(-not $rootkey) { Write-Error "Can't open the remote $root registry hive" }

  Write-Verbose "Opening $Path"
  $key = $rootkey.OpenSubKey( $Path )
  if(-not $key) { Write-Error "Can't open $($root + '\' + $Path) on $computer" }

  $subkey = $key.OpenSubKey( $last )

  if($subkey) {
    $subkey.GetSubKeyNames() | foreach { "{0}\" -f $_ }
    $subkey.GetValueNames() | foreach { "({3}) {0} = {1}" -f $_, $subkey.GetValue($_), $subkey.GetValueKind($_) }
  }
  else
  {
    $key.GetValue($last)
  }

