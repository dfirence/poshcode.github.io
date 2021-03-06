function killItWithFire {
  $TrustedInstallerProcess = Get-Process -ProcessName trustedinstaller
  if($TrustedInstallerProcess){
    Write-Host -ForegroundColor GREEN "TrustedInstaller process is running, killing it now."
    Stop-Process $TrustedInstallerProcess.Id -Force
  } else {
    Write-Host "TrustedInstaller process is not running."
  }
  $TrustedInstallerService = Get-Service trustedinstaller
  if($TrustedInstallerService.status -eq "Running"){
    Write-Host -ForegroundColor GREEN "TrustedInstaller service is running, stopping it now."
    Set-Service $TrustedInstallerService.name -Status stopped
  }
  Write-Host -ForegroundColor GREEN "Disabling TrustedInstaller service."
  Set-Service $TrustedInstallerService.name -StartupType Disabled
}
killItWithFire
