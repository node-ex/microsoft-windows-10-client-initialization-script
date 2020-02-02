Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine

$PSProfileDirectory = 'C:\Users\nodex\Documents\WindowsPowerShell'
$PSProfileFile = Join-Path -Path $PSProfileDirectory -ChildPath 'profile.ps1'

if (Test-Path $PSProfileDirectory) {
  Write-Host ">>> PowerShell profile directory exists."
} else {
  New-Item -ItemType Directory -Force -Path $PSProfileDirectory
  Write-Host ">>> PowerShell profile directory has been created."
}

if (Test-Path $PSProfileFile) {
  Write-Host ">>> PowerShell profile file exists."
} else {
  New-Item -ItemType File -Force -Path $PSProfileFile
  Write-Host ">>> PowerShell profile file has been created."
}

$ActivateReadlineStatement = @"

# Enable Bash-like auto-completion
Set-PSReadlineKeyHandler -Key Tab -Function Complete

"@

Add-Content -NoNewline -Force -Path $PSProfileFile -Value $ActivateReadlineStatement
