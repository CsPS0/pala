# Creates a Windows Start Menu shortcut for Pala Desktop
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$exePath = "$repoRoot\mobile\build\windows\x64\runner\Release\pala_mobile.exe"

if (-not (Test-Path $exePath)) {
    $exePath = "$repoRoot\mobile\build\windows\x64\runner\Debug\pala_mobile.exe"
}

if (-not (Test-Path $exePath)) {
    Write-Host "Forditas folyamatban (flutter build windows)..." -ForegroundColor Yellow
    Push-Location "$repoRoot\mobile"
    flutter build windows
    Pop-Location
    $exePath = "$repoRoot\mobile\build\windows\x64\runner\Release\pala_mobile.exe"
}

if (Test-Path $exePath) {
    $programsFolder = [Environment]::GetFolderPath('Programs')
    $shortcutPath = Join-Path $programsFolder "Pala Desktop.lnk"
    
    $wshShell = New-Object -ComObject WScript.Shell
    $shortcut = $wshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $exePath
    $shortcut.WorkingDirectory = Split-Path -Parent $exePath
    $shortcut.Description = "Pala Desktop - Modern Kreta Kliens"
    $shortcut.Save()
    
    Write-Host "Sikeres! A Pala Desktop bekerult a Start Menube:" -ForegroundColor Green
    Write-Host "$shortcutPath" -ForegroundColor Cyan
    Write-Host "Mostantol elerheto a Start menubol es a Windows keresobol a 'Pala' nev begepelesevel." -ForegroundColor Gray
} else {
    Write-Error "Nem talalhato a leforditott pala_mobile.exe allomany!"
}
