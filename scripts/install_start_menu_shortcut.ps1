# Creates a Windows Start Menu shortcut for Pala Desktop
$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path -Parent $scriptDir
$appFolder = if (Test-Path "$repoRoot\app") { "app" } else { "mobile" }

function Find-DesktopExe {
    param([string]$BuildType)
    foreach ($name in @("palapp.exe", "pala_app.exe", "pala_mobile.exe")) {
        $candidate = "$repoRoot\$appFolder\build\windows\x64\runner\$BuildType\$name"
        if (Test-Path $candidate) { return $candidate }
    }
    return $null
}

$exePath = Find-DesktopExe -BuildType "Release"
if (-not $exePath) {
    $exePath = Find-DesktopExe -BuildType "Debug"
}

if (-not $exePath) {
    Write-Host "Forditas folyamatban (flutter build windows)..." -ForegroundColor Yellow
    Push-Location "$repoRoot\$appFolder"
    flutter build windows
    Pop-Location
    $exePath = Find-DesktopExe -BuildType "Release"
}

if ($exePath -and (Test-Path $exePath)) {
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
    Write-Error "Nem talalhato a leforditott palapp.exe allomany!"
}
