$installedPrograms = Get-ItemProperty 'HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
$installedProgramsChocolatey = $null

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