# =====================================================================
# Pala — Modern All-in-One Telepito es Komponens Kezelo Windowsra
# Hasznalat:
#   Interaktiv: irm https://raw.githubusercontent.com/CsPS0/pala/main/install.ps1 | iex
#   Flagek:     .\install.ps1 -All
#               .\install.ps1 -Cli
#               .\install.ps1 -Desktop
#               .\install.ps1 -Uninstall
# =====================================================================

param(
    [switch]$All,
    [switch]$Cli,
    [switch]$Desktop,
    [switch]$AddToPath,
    [switch]$StartMenu,
    [switch]$Uninstall,
    [string]$Version = ""
)

$ErrorActionPreference = 'Stop'
$Repo = "CsPS0/pala"
$InstallBase = Join-Path $env:LOCALAPPDATA "Pala"
$BinDir = Join-Path $InstallBase "bin"
$DesktopDir = Join-Path $InstallBase "desktop"
$ProgramsFolder = [Environment]::GetFolderPath('Programs')
$DesktopFolder = [Environment]::GetFolderPath('Desktop')

function Show-Banner {
    Write-Host "=============================================================" -ForegroundColor DarkYellow
    Write-Host " Pala — Telepito es Komponens Kezelo (Windows)" -ForegroundColor Yellow
    Write-Host "=============================================================" -ForegroundColor DarkYellow
}

function Add-PathToUserEnv([string]$PathToAdd) {
    $CurrentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    $Parts = @()
    if ($CurrentPath) {
        $Parts = $CurrentPath.Split(';') | Where-Object { $_ -ne "" }
    }
    if ($Parts -notcontains $PathToAdd) {
        $NewPath = ($Parts + $PathToAdd) -join ';'
        [Environment]::SetEnvironmentVariable("Path", $NewPath, [EnvironmentVariableTarget]::User)
        $env:Path = "$env:Path;$PathToAdd"
        Write-Host "    [OK] PATH frissitve: $PathToAdd" -ForegroundColor Green
    } else {
        Write-Host "    [i] A $PathToAdd mar szerepel a felhasznaloi PATH-ban." -ForegroundColor Gray
    }
}

function Remove-PathFromUserEnv([string]$PathToRemove) {
    $CurrentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
    if ($CurrentPath) {
        $Parts = $CurrentPath.Split(';') | Where-Object { $_ -ne "" -and $_ -ne $PathToRemove }
        $NewPath = $Parts -join ';'
        [Environment]::SetEnvironmentVariable("Path", $NewPath, [EnvironmentVariableTarget]::User)
        Write-Host "    [OK] PATH-bol eltavolitva: $PathToRemove" -ForegroundColor Green
    }
}

function Create-Shortcut([string]$Target, [string]$LinkPath, [string]$Description, [string]$WorkingDir, [string]$IconLocation) {
    $wshShell = New-Object -ComObject WScript.Shell
    $shortcut = $wshShell.CreateShortcut($LinkPath)
    $shortcut.TargetPath = $Target
    if ($WorkingDir) { $shortcut.WorkingDirectory = $WorkingDir }
    if ($Description) { $shortcut.Description = $Description }
    if ($IconLocation -and (Test-Path $IconLocation)) { $shortcut.IconLocation = $IconLocation }
    $shortcut.Save()
    Write-Host "    [OK] Parancsikon letrehozva: $LinkPath" -ForegroundColor Green
}

function Uninstall-Pala {
    Write-Host ""
    Write-Host "Pala eltavolitasa folyamatban..." -ForegroundColor Yellow
    
    # Remove Shortcuts
    $StartShortcut = Join-Path $ProgramsFolder "Pala Desktop.lnk"
    $DesktopShortcut = Join-Path $DesktopFolder "Pala Desktop.lnk"
    $CliShortcut = Join-Path $ProgramsFolder "Pala CLI.lnk"
    
    if (Test-Path $StartShortcut) { Remove-Item $StartShortcut -Force; Write-Host "    [OK] Start menü parancsikon eltávolítva." -ForegroundColor Green }
    if (Test-Path $DesktopShortcut) { Remove-Item $DesktopShortcut -Force; Write-Host "    [OK] Asztali parancsikon eltávolítva." -ForegroundColor Green }
    if (Test-Path $CliShortcut) { Remove-Item $CliShortcut -Force; Write-Host "    [OK] CLI parancsikon eltávolítva." -ForegroundColor Green }
    
    # Remove from PATH
    Remove-PathFromUserEnv $BinDir
    
    # Remove Installation Files
    if (Test-Path $InstallBase) {
        Remove-Item -Path $InstallBase -Recurse -Force
        Write-Host "    [OK] Telepitett fajlok eltavolitva: $InstallBase" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Pala sikeresen eltavolitva a rendszerbol!" -ForegroundColor Green
    return
}

if ($Uninstall) {
    Show-Banner
    Uninstall-Pala
    exit 0
}

Show-Banner

# Determine components to install
$InstallDesktop = $false
$InstallCli = $false
$DoAddToPath = $true
$DoStartMenu = $true
$DoDesktopIcon = $false

if ($All) {
    $InstallDesktop = $true
    $InstallCli = $true
    $DoAddToPath = $true
    $DoStartMenu = $true
} elseif ($Cli) {
    $InstallCli = $true
    $DoAddToPath = $true
    $DoStartMenu = $false
} elseif ($Desktop) {
    $InstallDesktop = $true
    $DoStartMenu = $true
    $DoAddToPath = $false
} else {
    Write-Host "Valaszd ki a telepitendo komponenseket:" -ForegroundColor Cyan
    Write-Host "  1) Teljes csomag: Pala Desktop + CLI a PATH-ban (Ajanlott)" -ForegroundColor White
    Write-Host "  2) Csak Pala CLI / TUI (Terminalos eszkoz a PATH-ban)" -ForegroundColor White
    Write-Host "  3) Csak Pala Desktop (Grafikus asztali alkalmazas)" -ForegroundColor White
    Write-Host "  4) Egyeni valasztas (komponensek egyenkent)" -ForegroundColor White
    Write-Host "  5) Pala eltavolitasa a rendszerbol (Uninstall)" -ForegroundColor DarkGray
    
    $Choice = Read-Host "Valasztasod [1-5, alapertelmezett: 1]"
    if ([string]::IsNullOrWhiteSpace($Choice)) { $Choice = "1" }
    
    switch ($Choice) {
        "2" {
            $InstallCli = $true
            $DoAddToPath = $true
        }
        "3" {
            $InstallDesktop = $true
            $DoStartMenu = $true
        }
        "4" {
            $rDesk = Read-Host "Telepited a Pala Desktop grafikus alkalmazast? (I/n) [I]"
            $InstallDesktop = ($rDesk -ne 'n' -and $rDesk -ne 'N')
            
            $rCli = Read-Host "Telepited a Pala CLI / TUI parancssori eszkozt? (I/n) [I]"
            $InstallCli = ($rCli -ne 'n' -and $rCli -ne 'N')
            
            if ($InstallCli) {
                $rPath = Read-Host "Hozzaadod a Pala-t a PATH kornyezeti valtozohoz? (I/n) [I]"
                $DoAddToPath = ($rPath -ne 'n' -and $rPath -ne 'N')
            }
            
            if ($InstallDesktop) {
                $rStart = Read-Host "Letrehozol Start menü parancsikont? (I/n) [I]"
                $DoStartMenu = ($rStart -ne 'n' -and $rStart -ne 'N')
                
                $rDeskIcon = Read-Host "Letrehozol Asztali parancsikont? (i/N) [N]"
                $DoDesktopIcon = ($rDeskIcon -eq 'i' -or $rDeskIcon -eq 'I' -or $rDeskIcon -eq 'y' -or $rDeskIcon -eq 'Y')
            }
        }
        "5" {
            Uninstall-Pala
            exit 0
        }
        Default {
            $InstallDesktop = $true
            $InstallCli = $true
            $DoAddToPath = $true
            $DoStartMenu = $true
        }
    }
}

# Resolve version
if ([string]::IsNullOrWhiteSpace($Version)) {
    Write-Host "Legfrissebb verzio keresese..." -ForegroundColor DarkGray
    try {
        $ReleaseData = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -TimeoutSec 5 -ErrorAction Stop
        $Version = $ReleaseData.tag_name
    } catch {
        $Version = "v1.2.3"
    }
}
Write-Host "Telepitendo verzio: $Version" -ForegroundColor Cyan
Write-Host ""

# Create directories
New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
if ($InstallDesktop) {
    New-Item -ItemType Directory -Path $DesktopDir -Force | Out-Null
}

$RepoRoot = $PSScriptRoot
if (-not $RepoRoot) { $RepoRoot = Directory.current.path }

# 1. CLI Installation
if ($InstallCli) {
    Write-Host "[+] Pala CLI / TUI telepitese..." -ForegroundColor Yellow
    $LocalCli = Join-Path $RepoRoot "pala.exe"
    $DestCli = Join-Path $BinDir "pala.exe"
    
    if (Test-Path $LocalCli) {
        Copy-Item -Path $LocalCli -Destination $DestCli -Force
        Write-Host "    [OK] Helyi pala.exe masolva ide: $DestCli" -ForegroundColor Green
    } else {
        $CliDownloadUrl = "https://github.com/$Repo/releases/download/$Version/pala-windows.exe"
        Write-Host "    Letoltes: $CliDownloadUrl" -ForegroundColor DarkGray
        try {
            Invoke-WebRequest -Uri $CliDownloadUrl -OutFile $DestCli -TimeoutSec 30
            Write-Host "    [OK] Letoltve es telepitve: $DestCli" -ForegroundColor Green
        } catch {
            Write-Host "    [!] Figyelem: A kiadasi binaris nem toltheto le, forditott helyi binaris hasznalata javasolt." -ForegroundColor Yellow
        }
    }
    
    if ($DoAddToPath) {
        Add-PathToUserEnv $BinDir
    }
}

# 2. Desktop Installation
if ($InstallDesktop) {
    Write-Host "[+] Pala Desktop telepitese..." -ForegroundColor Yellow
    $LocalDesktopExe = "$RepoRoot\app\build\windows\x64\runner\Release\pala.exe"
    if (-not (Test-Path $LocalDesktopExe)) {
        $LocalDesktopExe = "$RepoRoot\app\build\windows\x64\runner\Release\pala_mobile.exe"
    }
    if (-not (Test-Path $LocalDesktopExe)) {
        $LocalDesktopExe = "$RepoRoot\mobile\build\windows\x64\runner\Release\pala_mobile.exe"
    }
    
    $DestDesktopExe = Join-Path $DesktopDir "pala.exe"
    
    if (Test-Path $LocalDesktopExe) {
        $ReleaseDir = Split-Path -Parent $LocalDesktopExe
        Copy-Item -Path "$ReleaseDir\*" -Destination $DesktopDir -Recurse -Force
        if (-not (Test-Path $DestDesktopExe)) {
            $OrigName = Split-Path -Leaf $LocalDesktopExe
            Copy-Item (Join-Path $DesktopDir $OrigName) $DestDesktopExe -Force
        }
        Write-Host "    [OK] Asztali alkalmazas fajlok masolva ide: $DesktopDir" -ForegroundColor Green
    } else {
        Write-Host "    [i] Desktop build keszitese vagy GitHub release letoltese..." -ForegroundColor DarkGray
    }
    
    # Shortcuts
    $IconPath = Join-Path $DesktopDir "data\flutter_assets\app_icon.ico"
    if (-not (Test-Path $IconPath)) { $IconPath = "" }
    
    if ($DoStartMenu) {
        $StartShortcut = Join-Path $ProgramsFolder "Pala Desktop.lnk"
        Create-Shortcut -Target $DestDesktopExe -LinkPath $StartShortcut -Description "Pala Desktop — Modern Kreta Kliens" -WorkingDir $DesktopDir -IconLocation $IconPath
    }
    
    if ($DoDesktopIcon) {
        $DeskShortcut = Join-Path $DesktopFolder "Pala Desktop.lnk"
        Create-Shortcut -Target $DestDesktopExe -LinkPath $DeskShortcut -Description "Pala Desktop — Modern Kreta Kliens" -WorkingDir $DesktopDir -IconLocation $IconPath
    }
}

# Save uninstaller helper into install directory
$UninstallScript = Join-Path $InstallBase "uninstall.ps1"
@"
Write-Host "Pala eltavolitasa..." -ForegroundColor Yellow
`$ProgramsFolder = [Environment]::GetFolderPath('Programs')
`$DesktopFolder = [Environment]::GetFolderPath('Desktop')
Remove-Item -Path (Join-Path `$ProgramsFolder "Pala Desktop.lnk") -Force -ErrorAction SilentlyContinue
Remove-Item -Path (Join-Path `$DesktopFolder "Pala Desktop.lnk") -Force -ErrorAction SilentlyContinue
`$CurrentPath = [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User)
if (`$CurrentPath) {
    `$Parts = `$CurrentPath.Split(';') | Where-Object { `$_ -ne "" -and `$_ -ne "$BinDir" }
    [Environment]::SetEnvironmentVariable("Path", (`$Parts -join ';'), [EnvironmentVariableTarget]::User)
}
Remove-Item -Path "$InstallBase" -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Pala sikeresen eltavolitva!" -ForegroundColor Green
"@ | Set-Content -Path $UninstallScript -Encoding utf8

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Green
Write-Host " A telepites es beallitas sikeresen befejezodott!" -ForegroundColor Green
Write-Host " Inditas: " -ForegroundColor White
if ($InstallCli) {
    Write-Host "   - Terminalban:       pala" -ForegroundColor Cyan
}
if ($InstallDesktop) {
    Write-Host "   - Start menubol:     Pala Desktop" -ForegroundColor Cyan
    Write-Host "   - Parancssorbol:     pala --desktop" -ForegroundColor Cyan
}
Write-Host " Eltavolitas barmikor:   $UninstallScript" -ForegroundColor DarkGray
Write-Host "=============================================================" -ForegroundColor Green
