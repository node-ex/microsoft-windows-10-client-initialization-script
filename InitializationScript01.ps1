$ACTIVATE_READLINE_STATEMENT = @"

# Enable Bash-like auto-completion
Set-PSReadlineKeyHandler -Key Tab -Function Complete

"@

function setExecutionPolicy {
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine

  Write-Host '>>> Execution policy has been set to RemoteSigned.'
}

function initializePowerShellProfile {
  $PSProfileDirectory = Join-Path -Path $HOME -ChildPath 'Documents\WindowsPowerShell'
  $PSProfileFile = Join-Path -Path $PSProfileDirectory -ChildPath 'profile.ps1'

  if (Test-Path $PSProfileDirectory) {
    Write-Host '>>> PowerShell profile directory exists.'
  } else {
    New-Item -ItemType Directory -Force -Path $PSProfileDirectory
    Write-Host '>>> PowerShell profile directory has been created.'
  }

  if (Test-Path $PSProfileFile) {
    Write-Host '>>> PowerShell profile file exists.'
  } else {
    New-Item -ItemType File -Force -Path $PSProfileFile
    Write-Host '>>> PowerShell profile file has been created.'
  }

  $codeExists = Select-String -Path $PSProfileFile -Pattern ($ACTIVATE_READLINE_STATEMENT + '3') -List

  if ($codeExists.length -gt 0) {
    Add-Content -NoNewline -Force -Path $PSProfileFile -Value $ACTIVATE_READLINE_STATEMENT
    Write-Host '>>> Statement for readline activation has been added to PowerShell profile file.'
  } else {
    Write-Host '>>> Statement for readline activation exists in PowerShell profile file.'
  }
}

function setupWindowsUpdate {
  $windowsUpdateRegistryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'

  if(-not (Test-Path $windowsUpdateRegistryPath)) {
    New-Item -Path $windowsUpdateRegistryPath -Force
  }

  Set-ItemProperty -Path $windowsUpdateRegistryPath -Name 'NoAutoUpdate' -Value 0
  Set-ItemProperty -Path $windowsUpdateRegistryPath -Name 'AUOptions' -Value 2
  Set-ItemProperty -Path $windowsUpdateRegistryPath -Name 'ScheduledInstallDay' -Value 0
  Set-ItemProperty -Path $windowsUpdateRegistryPath -Name 'ScheduledInstallEveryWeek' -Value 1
  Set-ItemProperty -Path $windowsUpdateRegistryPath -Name 'ScheduledInstallTime' -Value 3
  Set-ItemProperty -Path $windowsUpdateRegistryPath -Name 'NoAUAsDefaultShutdownOption' -Value 1
  Set-ItemProperty -Path $windowsUpdateRegistryPath -Name 'NoAUShutdownOption' -Value 1
}

function enableWindowsSubsystemForLinux {
  Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -WarningAction SilentlyContinue | Out-Null
  Write-Host '>>> Virtual Machine Platform has been enabled.'

  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -WarningAction SilentlyContinue | Out-Null
  Write-Host '>>> Windows Subsystem for Linux (WSL) has been enabled.'
}

function enableWindowsContainerization {
  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart -WarningAction SilentlyContinue | Out-Null
  Write-Host '>>> Hyper-V feature has been enabled.'

  Enable-WindowsOptionalFeature -Online -FeatureName Containers -All -NoRestart -WarningAction SilentlyContinue | Out-Null
  Write-Host '>>> Containers feature has been enabled.'
}

function enableDeveloperMode {
  Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Name 'AllowDevelopmentWithoutDevLicense' -Value '1'
  Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' -Name 'AllowAllTrustedApps' -Value '1'
  Write-Host '>>> Enable Developer mode.'
}

function configureFileExplorer() {
  $explorerPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
  $explorerAdvancedPath = Join-Path -Path $explorerPath -ChildPath 'Advanced'
  $explorerCabinetStatePath = Join-Path -Path $explorerPath -ChildPath 'CabinetState'

  # Do not hide extensions for known file types
  Set-ItemProperty $explorerAdvancedPath 'HideFileExt' '0'
  # Show hidden files, folders, drives
  Set-ItemProperty $explorerAdvancedPath 'Hidden' '1'
  # Do not hide emptry drives
  Set-ItemProperty $explorerAdvancedPath 'HideDrivesWithNoMedia' '0'
  # Hide protected operating system files
  Set-ItemProperty $explorerAdvancedPath 'ShowSuperHidden' '0'

  # Display the full path in the title bar
  Set-ItemProperty $explorerCabinetStatePath 'FullPath' '0'

  Stop-Process -ProcessName Explorer -Force # This will restart the Explorer service to make this work.

  Write-Host '>>> File Explorer has been configured.'
}

function enableRdp {
  $terminalServerPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
  $rdpTcpPath = $terminalServerPath + '\WinStations\RDP-Tcp'
  # Enable Remote Desktop
  Set-ItemProperty -Path $terminalServerPath -Name 'fDenyTSConnections' -Type DWord -Value 0
  # Enable secure RDP authentication (NLA – Network Level Authentication)
  Set-ItemProperty -Path $rdpTcpPath -name "UserAuthentication" -Value 1
  # Allow incoming RDP connections in Windows Firewall
  Enable-NetFirewallRule -Name 'RemoteDesktop*'

  Write-Host '>>> RDP has been enabled.'
}

function enableFirewall {
  Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
  Write-Host '>>> Windows Firewall has been enabled.'
}

function announceSuccessNextSteps {
  Write-Host '>>> Script has finished running.'
  Write-Host '>>> Next steps:'
  Write-Host '>>> 1. Manually uninstall unnecessary programs'
  Write-Host '>>> 2. Manually remove unnecessary programs from Startup'
  Write-Host '>>> 3. Manually stop unnecessary Services'
  Write-Host '>>> 4. Restart PC'
  Write-Host '>>> 5. Run the next script'
}

function main {
  setExecutionPolicy
  initializePowerShellProfile
  setupWindowsUpdate
  enableWindowsSubsystemForLinux
  enableWindowsContainerization
  enableDeveloperMode
  configureFileExplorer
  enableRdp
  enableFirewall
  announceSuccessNextSteps
}

main
