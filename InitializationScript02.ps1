$setupUbuntuSteps = @"
  1. Open Start.
  2. Search for the Linux distribution (for example, Ubuntu), click the top result to launch the experience.
  3. Create a username for the Linux distro and press Enter.
  4. Specify a password for the distro and press Enter.
"@

function installNugetProvider {
  Install-PackageProvider -Name NuGet -Force
  Write-Host '>>> NuGet Provider has been installed.'
}

function installUbuntu {
  $userDownloadsDirectory = Join-Path -Path $HOME -ChildPath 'Downloads'
  $backupProgressPreference = $ProgressPreference

  $packageExists = $null -ne (Get-AppxPackage -AllUsers -Name 'CanonicalGroupLimited.Ubuntu*')

  if (-not $packageExists) {
    $ProgressPreference = 'SilentlyContinue'
    Push-Location

    Set-Location -Path $userDownloadsDirectory
    Invoke-WebRequest -Uri https://aka.ms/wslubuntu2004 -OutFile Ubuntu.appx -UseBasicParsing
    Add-AppxPackage .\Ubuntu.appx
    Remove-Item -Path .\Ubuntu.appx

    Pop-Location
    $ProgressPreference = $backupProgressPreference

    Write-Host '>>> Ubuntu has been installed.'
  } else {
    Write-Host '>>> Ubuntu is already installed.'
  }
}

function announceSuccessNextSteps {
  Write-Host '>>> Script has finished running.'
  Write-Host '>>> Next steps:'
  Write-Host '>>> 1. Setup Ubuntu'
  Write-Host $setupUbuntuSteps
}

function main {
  installNugetProvider
  installUbuntu
  announceSuccessNextSteps
}

main
