$script:sshConfigurationDirectory = 'C:\ProgramData\ssh'
$script:administratorsAuthorizedKeysFile = Join-Path -Path $script:sshConfigurationDirectory -ChildPath 'administrators_authorized_keys'
$script:sshdConfigFile = Join-Path -Path $script:sshConfigurationDirectory -ChildPath 'sshd_config'

function installNugetProvider {
  Install-PackageProvider -Name NuGet -Force
  Write-Host '>>> NuGet Provider has been installed.'
}

function enableSshService {
  # Enable sshd service
  Start-Service sshd
  Start-Service ssh-agent
  # Start sshd service on startup
  Set-Service -Name sshd -StartupType 'Automatic'
  Set-Service -Name ssh-agent -StartupType 'Automatic'

  $firewallRuleArray =
    Get-NetFirewallRule `
      -DisplayGroup 'OpenSSH Server' `
      -Direction 'Inbound' `
      -Enabled $true.ToString()

  # Check whether returned value is not null and not an array => single existing rule
  if ($null -eq $firewallRuleArray.length -and -not ($firewallRuleArray -is [array])) {
    Write-Host '>>> SSH Firewall rule exists.'
  }

  # TODO: Handle other cases
}

function configureSshAuthentication {
  if (-not (Test-Path $script:sshConfigurationDirectory)) {
    New-Item -Path $script:sshConfigurationDirectory -ItemType Directory -Force
    Write-Host '>>> SSH configuration directory has been created.'
  } else {
    Write-Host '>>> SSH configuration directory exists.'
  }

  if (-not (Test-Path $script:administratorsAuthorizedKeysFile)) {
    New-Item -Path $script:administratorsAuthorizedKeysFile -ItemType File -Force
    Write-Host '>>> administrators_authorized_keys file has been created.'
  } else {
    Write-Host '>>> administrators_authorized_keys file exists.'
  }

  # Set ACL for public key authentication
  $acl = Get-Acl $script:administratorsAuthorizedKeysFile
  $acl.SetAccessRuleProtection($true, $false)
  $administratorsRule = New-Object System.Security.AccessControl.FileSystemAccessRule('Administrators', 'FullControl', 'Allow')
  $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule('SYSTEM', 'FullControl', 'Allow')
  $acl.SetAccessRule($administratorsRule)
  $acl.SetAccessRule($systemRule)
  $acl | Set-Acl
  Write-Host '>>> ACL rules for administrators_authorized_keys file have been set.'

  # TODO: Wait for the signature correction for versions >= 1.0.0.1
  Install-Module -Force OpenSSHUtils -Scope AllUsers -RequiredVersion 0.0.2.0

  (Get-Content $script:sshdConfigFile) -replace '^[ #]*PasswordAuthentication.*', 'PasswordAuthentication no' | Set-Content $script:sshdConfigFile
  (Get-Content $script:sshdConfigFile) -replace '^[ #]*PubkeyAuthentication.*', 'PubkeyAuthentication yes' | Set-Content $script:sshdConfigFile
  Write-Host '>>> sshd_config has been modified.'

  Restart-Service sshd
  Restart-Service ssh-agent

  Write-Host '>>> SSH authentication has been configured.'
}

function setupSshKeys {
  $userSshDirectory = Join-Path -Path $HOME -ChildPath '/.ssh'
  $privateSshKeyFile = Join-Path -Path $userSshDirectory -ChildPath '/id_rsa'

  if (-not (Test-Path $userSshDirectory)) {
    New-Item -Path $userSshDirectory -ItemType Directory -Force
    Write-Host '>>> Users .ssh directory has been created.'
  } else {
    Write-Host '>>> Users .ssh directory exists.'
  }

  ssh-keygen -t rsa -b 4096 -C 'pavel.balashov1@gmail.com' -f $privateSshKeyFile -N [string]::Empty
  ssh-add $privateSshKeyFile

  Restart-Service sshd
  Restart-Service ssh-agent

  Write-Host '>>> SSH keys have been configured.'
}

function announceSuccessNextSteps {
  Write-Host '>>> Script has finished running.'
  Write-Host '>>> Next steps:'
  Write-Host ('>>> 1. Add appropriate public keys to ' + $script:administratorsAuthorizedKeysFile)
  Write-Host '>>> 4. Restart PC'
  Write-Host '>>> 5. Run the next script'
}

function main {
  installNugetProvider
  enableSshService
  configureSshAuthentication
  setupSshKeys
  announceSuccessNextSteps
}

main
