$script:SSH_CLIENT_CAPABILITY_EXISTS = $false
$script:SSH_SERVER_CAPABILITY_EXISTS = $false

$installedPrograms = Get-ItemProperty 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
$installedProgramsChocolatey = $null
$sshConfigurationDirectory = 'C:\ProgramData\ssh'
$administratorsAuthorizedKeysFile = Join-Path -Path $sshConfigurationDirectory -ChildPath 'administrators_authorized_keys'
$sshdConfigFile = Join-Path -Path $sshConfigurationDirectory -ChildPath 'sshd_config'

function addWindowsCapabilitySsh {
  # Make sure that the OpenSSH features are available for install
  $clientCapabilityNameArray = Get-WindowsCapability -Online | Where-Object -Property Name -Like 'OpenSSH.Client*' | Select-Object -ExpandProperty Name
  $serverCapabilityNameArray = Get-WindowsCapability -Online | Where-Object -Property Name -Like 'OpenSSH.Server*' | Select-Object -ExpandProperty Name

  if ($clientCapabilityNameArray.length -gt 0) {
    $clientCapabilityName = $clientCapabilityNameArray[0]
    # Install the OpenSSH Client
    Add-WindowsCapability -Online -Name $clientCapabilityName | Out-Null
    $script:SSH_CLIENT_CAPABILITY_EXISTS = $true
    Write-Host '>>> OpenSSH client capability has been enabled.'
  } else {
    Write-Host '>>> OpenSSH client capability does not exist.'
  }

  if ($serverCapabilityNameArray.length -gt 0) {
    $serverCapabilityName = $serverCapabilityNameArray[0]
    # Install the OpenSSH Server
    Add-WindowsCapability -Online -Name $serverCapabilityName | Out-Null
    $script:SSH_SERVER_CAPABILITY_EXISTS = $true
    Write-Host '>>> OpenSSH server capability has been enabled.'
  } else {
    Write-Host '>>> OpenSSH server capability does not exist.'
  }
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
  if ($null -ne $firewallRuleArray -and -not ($firewallRuleArray -is [array])) {
    Write-Host '>>> SSH Firewall rule exists.'
  }

  # TODO: Handle other cases
}

function configureSshAuthentication {
  if (-not (Test-Path $sshConfigurationDirectory)) {
    New-Item -Path $sshConfigurationDirectory -ItemType Directory -Force | Out-Null
    Write-Host '>>> SSH configuration directory has been created.'
  } else {
    Write-Host '>>> SSH configuration directory exists.'
  }

  if (-not (Test-Path $administratorsAuthorizedKeysFile)) {
    New-Item -Path $administratorsAuthorizedKeysFile -ItemType File -Force | Out-Null
    Write-Host '>>> administrators_authorized_keys file has been created.'
  } else {
    Write-Host '>>> administrators_authorized_keys file exists.'
  }

  # Set ACL for public key authentication
  $acl = Get-Acl $administratorsAuthorizedKeysFile
  $acl.SetAccessRuleProtection($true, $false)
  $administratorsRule = New-Object System.Security.AccessControl.FileSystemAccessRule('Administrators', 'FullControl', 'Allow')
  $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule('SYSTEM', 'FullControl', 'Allow')
  $acl.SetAccessRule($administratorsRule)
  $acl.SetAccessRule($systemRule)
  $acl | Set-Acl
  Write-Host '>>> ACL rules for administrators_authorized_keys file have been set.'

  # TODO: Wait for the signature correction for versions >= 1.0.0.1
  Install-Module -Force OpenSSHUtils -Scope AllUsers -RequiredVersion 0.0.2.0

  (Get-Content $sshdConfigFile) -replace '^[ #]*PasswordAuthentication.*', 'PasswordAuthentication no' | Set-Content $sshdConfigFile
  (Get-Content $sshdConfigFile) -replace '^[ #]*PubkeyAuthentication.*', 'PubkeyAuthentication yes' | Set-Content $sshdConfigFile
  Write-Host '>>> sshd_config has been modified.'

  Restart-Service sshd
  Restart-Service ssh-agent

  Write-Host '>>> SSH authentication has been configured.'
}

function setupSshKeys {
  $userSshDirectory = Join-Path -Path $HOME -ChildPath '/.ssh'
  $privateSshKeyFile = Join-Path -Path $userSshDirectory -ChildPath '/id_rsa'

  if (-not (Test-Path $userSshDirectory)) {
    New-Item -Path $userSshDirectory -ItemType Directory -Force | Out-Null
    Write-Host '>>> Users .ssh directory has been created.'
  } else {
    Write-Host '>>> Users .ssh directory exists.'
  }

  ssh-keygen -t rsa -b 4096 -C 'pavel.balashov1@gmail.com' -f $privateSshKeyFile -q -N """"
  ssh-add $privateSshKeyFile

  Restart-Service sshd
  Restart-Service ssh-agent

  Write-Host '>>> SSH keys have been configured.'
}

function installChocolatey {
  $chocolateyGuiIsInstalled =
    (
      $installedPrograms |
      Where-Object -Property DisplayName -Like 'Chocolatey GUI' |
      Select-Object -ExpandProperty DisplayName
    ).length -gt 0

  if (-not (Test-Path 'Env:\ChocolateyInstall')) {
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    Write-Host '>>> Chocolatey has been installed.'
  } else {
    Write-Host '>>> Chocolatey is already installed.'
  }

  $script:installedProgramsChocolatey = (choco list --local-only)

  if (-not $chocolateyGuiIsInstalled) {
    choco install chocolateygui
    Write-Host '>>> Chocolatey GUI has been installed.'
  } else {
    Write-Host '>>> Chocolatey GUI is already installed.'
  }
}

function installDockerDesktop {
  $programInstalled = $installedProgramsChocolatey -match 'docker-desktop'

  if (-not $programInstalled) {
    choco install docker-desktop
    Write-Host '>>> Docker Desktop has been installed.'
  } else {
    Write-Host '>>> Docker Desktop is already installed.'
  }
}

function installOracleJava {
  try {
    Start-Process -FilePath 'javac.exe' -ArgumentList '-version' -Wait -NoNewWindow
    Write-Host '>>> Oracle JDK has been already installed.'
  } catch [System.Management.Automation.RuntimeException] {
    $source = 'https://download.oracle.com/otn-pub/java/jdk/13.0.2+8/d4173c853231432d94f001e99d882ca7/jdk-13.0.2_windows-x64_bin.exe'
    $destination = Join-Path -Path $HOME -ChildPath '\Downloads\jdk.exe'
    $client = New-Object System.Net.WebClient
    $cookie = "oraclelicense=accept-securebackup-cookie"

    $client.Headers.Add([System.Net.HttpRequestHeader]::Cookie, $cookie)
    $client.downloadFile($source, $destination)
    Write-Host '>>> Oracle JDK installer has been downloaded.'

    Start-Process -FilePath $destination -ArgumentList '/s' -Wait -NoNewWindow
    # Start-Process -FilePath 'C:\Users\nodex\Downloads\jdk.exe' -ArgumentList '/s' -Wait -NoNewWindow
    Remove-Item -Path $destination

    Set-Item -Path Env:Path -Value ($Env:Path + ";C:\Program Files\Java\jdk-13.0.2\bin")
    Add-Content -Path $Profile.CurrentUserAllHosts -Value '$Env:Path += ";C:\Program Files\Java\jdk-13.0.2\bin"'

    Write-Host '>>> Oracle JDK has been installed.'
  }
}